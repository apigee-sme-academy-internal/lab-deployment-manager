function setup_logger() {
  exec 1> >(stdbuf -i0 -oL -eL sed -e 's/^/'"$1: "'/') 2>&1
}

function launch_prefixed() {
  prefix="$1"
  command="$2"
  "$command" 1> >(stdbuf -i0 -oL -eL sed -e 's/^/'"$1: "'/') 2>&1
}

# When doing a DNS lookup, check all the authoritative servers for apigeelabs.com
# All of them must give a response before we return
# This logic is needed because we don't know which name server certbot is going to check
function short_dig_apigeelabs() {
  dns_record_type="$1"
  dns_record="$2"

  dns_servers_count=$(dig +short NS apigeelabs.com|wc -l)
  count=0
  dns_result=""

  for dns_server in $(dig +short NS apigeelabs.com) ; do
    dns_result=$(dig +short -t ${dns_record_type} ${dns_record} @${dns_server})
    if [[ ! -z "${dns_result}" ]] ; then
      let "count = count + 1"
    fi
  done

  if [[ "${dns_servers_count}" == "${count}" ]] ; then
    echo "${dns_result}"
  else
    echo ""
  fi
}

function add_apigeelabs_dns_entry() {
  resource_type="$1"
  resource_name="$2"
  resource_value="$3"
  access_token=$(gcloud auth print-access-token --account=${ASSETS_SERVICE_ACCOUNT})
  curl -s -X POST  'https://www.googleapis.com/dns/v1/projects/apigee-sme-academy/managedZones/apigeelabs/changes' \
    -H "Authorization: Bearer $access_token" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -d "$(cat << DNSEOF
{
  "additions": [
    {
      "name": "${resource_name}.",
      "type": "${resource_type}",
      "ttl": 300,
      "rrdatas": [
        "${resource_value}"
      ]
    }
  ]
}
DNSEOF
)"
}

function wait_for_dns_record() {
  dns_record_type="$1"
  dns_host="$2"

  (
  setup_logger "poll"
  dns_server="${3:-@8.8.8.8}"
  dns_record=$(dig +short -t ${dns_record_type} ${dns_host} ${dns_server});
  attempts=0
  while [ -z "$dns_record" ] ; do
    (("attempts = attempts + 1"))
    echo "Waiting for ${dns_host} DNS ${dns_record_type} record (${attempts} attempt(s)) ...";
    dns_record=$(dig +short -t ${dns_record_type} ${dns_host} ${dns_server});
    [ -z "$dns_record" ] && sleep 10;
  done;
  echo "Got DNS \"${dns_record_type}\"  record \"${dns_record}\" for \"${dns_host}\" ..."
  )
}


function wait_for_apigeelabs_dns_record() {
  dns_record_type="$1"
  dns_host="$2"

  (
  setup_logger "poll"
  dns_record=$(short_dig_apigeelabs ${dns_record_type} ${dns_host});
  attempts=0
  while [ -z "$dns_record" ] ; do
    (("attempts = attempts + 1"))
    echo "Waiting for ${dns_host} DNS ${dns_record_type} record (${attempts} attempt(s)) ...";
    dns_record=$(short_dig_apigeelabs ${dns_record_type} ${dns_host});
    [ -z "$dns_record" ]  && sleep 10;
  done;
  echo "Got DNS \"${dns_record_type}\" record \"${dns_record}\" for \"${dns_host}\" ..."
  )
}


function get_service_ip() {
  service_name=$1
  service_ip=$(kubectl get service ${service_name} -o json | jq ".status.loadBalancer.ingress[0].ip" -r)
  echo "${service_ip}"
}

function wait_for_service_ip() {
  service_name=$1
  (
  setup_logger "poll"
  service_ip="null"
  attempts=0
  while [ -z "$service_ip" ] || [ "$service_ip" == "null" ]; do
    (("attempts = attempts + 1"))
    echo "Waiting for ${service_name} IP address (${attempts} attempts(s)) ...";
    service_ip=$(kubectl get service "${service_name}" -o json | jq ".status.loadBalancer.ingress[0].ip" -r);
    [ -z "$service_ip" ] || [ "$service_ip" == "null" ] && sleep 10;
  done;
  echo "Got IP Address \"${service_ip}\" for \"${service_name}\" ...";
  )
}


function wait_for_service_and_add_to_dns() {
  service_name="$1"
  service_host="$2"
  wait_for_service_ip "$service_name"
  service_ip=$(get_service_ip "$service_name")
  echo "Adding $service_name address ($service_ip) to DNS"
  add_apigeelabs_dns_entry "A" "${service_host}" "${service_ip}"
  echo "*** $service_name ready: ${service_host} ***"
}


function get_repo_dir() {
  repo_dir="$(basename "${1}" .git)"
  echo "${repo_dir}"
}

function clone_repo_and_checkout_branch(){
  git_repo="$1"
  git_branch="$2"
  git_repo_dir="$(get_repo_dir ${git_repo})"

  echo "*** Cloning ${git_repo_dir} (${git_branch} branch) ***"
  git clone -q "${git_repo}"
  pushd "${git_repo_dir}" &> /dev/nul;
  branch_exists=$(git ls-remote origin "${git_branch}" | wc -l)
  if [[ "${branch_exists}" == "0" ]] ; then
    echo "WARNING: '${git_branch}' branch does not exist. Falling back to 'master' branch"
    git_branch='master'
  fi
  git checkout ${git_branch}
  popd &> /dev/null
}


function wait_for_apigee_config_api_ready() {
  org="$1"
  (
  setup_logger "poll"
  access_token=$(gcloud auth print-access-token --account=${PROJECT_SERVICE_ACCOUNT})
  status_code=""
  attempts=0
  while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
    (("attempts = attempts + 1"))
    echo "Waiting for Apigee config API to be ready (${attempts} attempts(s)) ..." && sleep 10;
    status_code=$(curl -k -s -o /dev/null \
                      -w "%{http_code}" \
                      --max-time 5 \
                      -H "Authorization: Bearer ${access_token}" \
                      -X GET "https://apigee.googleapis.com/v1/organizations/${org}/apiproducts" | head -1)
  done;
  echo "Got HTTP \"${status_code}\" from Apigee config API ..." && sleep 10;
  )
}

function wait_for_devportal_apidocs_api_ready() {
  dev_portal_host_alias="$1"
  (
  setup_logger "poll"
  status_code=""
  attempts=0
  while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
    (("attempts = attempts + 1"))
    echo "Waiting for Dev Portal API-Docs API to be ready (${attempts} attempts(s)) ..." && sleep 10;
    status_code=$(curl -k -s -o /dev/null \
                      -w "%{http_code}" \
                      --max-time "5" \
                      -X GET "https://${dev_portal_host_alias}/jsonapi/apidoc/apidoc" | head -1)
  done;
  echo "Got HTTP \"${status_code}\" from the Portal API-Docs API ..." && sleep 10;
  )
}


function task_file() {
  echo "/tmp/task.$1"
}
export -f task_file

function task_start() {
  t_id="$1"
  t_name="$2"
  t_file=$(task_file "${t_id}")

  true > "${t_file}"
  task_set_state "${t_id}" "${t_name}"
  task_set_state "${t_id}" "started"
}
export -f task_start

function task_set_state() {
  echo "$2" >> $(task_file "$1")
}
export -f task_set_state

function task_get_name() {
  t_id="$1"
  t_file=$(task_file "${t_id}")
  if [ ! -f "${t_file}" ] ; then
    echo "${t_id}"
    return;
  fi

  head -1 "${t_file}"
}
export -f task_get_name

function task_get_state() {
  t_id="$1"
  t_file=$(task_file "${t_id}")
  if [ ! -f "${t_file}" ] ; then
    echo "unknown"
    return;
  fi

  tail -1 "${t_file}"
}
export -f task_get_state

function task_end() {
  t_id="$1"
  task_set_state "${t_id}" "done"
}
export -f task_end

function task_run() {
  t_id="$1"; shift;
  t_name="$1"; shift
  task_start "${t_id}" "${t_name}"
  "$@"
  t_code="$?"
  if [[ "${t_code}" != "0" ]] ; then
    task_set_state "${t_id}" "failed"
    return 1
  fi

  task_set_state "${t_id}" "passed"
  return 0
}
export -f task_run


function task_get_passed_percent() {
  t_ids="$@"
  total_count=0
  passed_count=0

  for t_id in ${t_ids} ; do
    (( total_count++ ))
    t_state=$(task_get_state "${t_id}")
    if [[ "${t_state}" == "passed" ]] ; then
      (( passed_count++ ))
    fi
  done

  printf "$(echo "scale=2; $passed_count/$total_count * 100" | bc | cut -d . -f 1)"
}


function task_get_json() {
  t_ids="$@"
  total_count=0
  passed_count=0

  summary=""
  for t_id in ${t_ids} ; do
    (( total_count++ ))
    t_state=$(task_get_state "${t_id}")
    t_name=$(task_get_name "${t_id}")
    if [[ "${t_state}" == "passed" ]] ; then
      (( passed_count++ ))
    fi

    summary="${summary}$(printf "%-40s ... %s%s" "${t_name}" "${t_state}" "\n")"

  done

  passed_percent="$(echo "scale=2; $passed_count/$total_count * 100" | bc | cut -d . -f 1)"
  summary="${summary}\n${passed_percent}% passed"

  done="false"
  if [[ "${total_count}" == "${passed_count}" ]] ; then
    done="true"
  fi

  echo "{\"done\": ${done}, \"score\": ${passed_percent}, \"messsage\": \"${summary}\", \"student_message\": \"${summary}\"}";
}

