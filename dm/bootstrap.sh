#!/usr/bin/env bash

cd ~

export PROJECT_SERVICE_ACCOUNT_JSON='%keyFile%'
export ASSETS_SERVICE_ACCOUNT_JSON='${AUTOMATION_GCP_SERVICE_ACCOUNT_JSON}'
export QWIKLABS_USERNAME='%userName%'
export QWIKLABS_USERPASSWORD='%userPassword%'


# Values from qwiklabs take precedence
function get_qwiklab_property() {
  qwiklabs_value="$1";
  default_value="$2"
  if [[ -z "${qwiklabs_value}" ]] || [[ "${qwiklabs_value}" =~ ^%.*%$ ]] ; then
    echo "${default_value}"
    return
  fi

  echo "${qwiklabs_value}"
}


function add_apigeelabs_dns_entry() {
  resource_type="$1"
  resource_name="$2"
  resource_value="$3"
  access_token=$(gcloud auth print-access-token --account="${ASSETS_SERVICE_ACCOUNT}")
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
export -f add_apigeelabs_dns_entry

export ZONE=$(get_qwiklab_property '%zone%' "us-west1-b")
export REGION=$(get_qwiklab_property '%region%' "us-west1")

export DM_REPO=$(get_qwiklab_property '%dm_repo%' "git@github.com:apigee-sme-academy-internal/lab-deployment-manager.git")
export DM_BRANCH=$(get_qwiklab_property '%dm_branch%' "master")
export ENV=$(get_qwiklab_property '%env%' "test")

export LAB_REPO=$(get_qwiklab_property '%lab_repo%' "${LAB_REPO_BUILD}")
export LAB_BRANCH=$(get_qwiklab_property '%lab_branch%' "${LAB_BRANCH_BUILD}")

export USE_REAL_CERT=$(get_qwiklab_property '%use_real_cert%' "false")



## Activate service account
echo "*******************************************"
echo "*** (BEGIN) Setting up service accounts ***"
echo "*******************************************"

snap install google-cloud-sdk
export PATH=/snap/bin:$PATH

# Save the project svc account name
gcloud auth activate-service-account --key-file=<(echo ${PROJECT_SERVICE_ACCOUNT_JSON})
export PROJECT_SERVICE_ACCOUNT=$(gcloud config list account --format "value(core.account)")
export PROJECT=$(gcloud config get-value project)

# Activate and save the assets svc account name
gcloud auth activate-service-account --key-file=<(echo ${ASSETS_SERVICE_ACCOUNT_JSON})
export ASSETS_SERVICE_ACCOUNT=$(gcloud config list account --format "value(core.account)")

# Make the project service account be the active one
gcloud config set account ${PROJECT_SERVICE_ACCOUNT}

echo "*****************************************"
echo "*** (END) Setting up service accounts ***"
echo "*****************************************"


echo "*********************************************"
echo "*** (BEGIN) Setting up lab-bootstrap tool ***"
echo "*********************************************"

curl -sSOL "https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/${DM_BRANCH}/dist/linux/lab-bootstrap"
curl -sSOL "https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/${DM_BRANCH}/dist/linux/gotty"
curl -sSOL "https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/${DM_BRANCH}/dist/linux/.gotty"
mv ./lab-bootstrap /usr/bin/
mv ./gotty /usr/bin
chmod a+rx /usr/bin/{gotty,lab-bootstrap}

export VM_EXTERNAL_IP=$(gcloud compute instances describe lab-startup --zone ${ZONE} --format='value(networkInterfaces.accessConfigs[0].natIP)')
gcloud compute instances add-tags lab-startup --tags=lab-startup --zone=${ZONE}
gcloud compute firewall-rules create "lab-startup" \
      --direction=INGRESS \
      --allow=tcp:80 \
      --source-ranges="0.0.0.0/0" \
      --description="lab-startup" \
      --target-tags=lab-startup

add_apigeelabs_dns_entry "A" "startup.${PROJECT}.apigeelabs.com" "${VM_EXTERNAL_IP}"
apt-get install -y supervisor
echo '
[program:apache2]
environment=HOME=/root,TERM=xterm-256color
command=gotty --port=80 lab-bootstrap monitor
autorestart=true' > /etc/supervisor/conf.d/gotty.conf
systemctl restart supervisor

echo "*******************************************"
echo "*** (END) Setting up lab-bootstrap tool ***"
echo "*******************************************"


lab-bootstrap begin overall-deployment "Overall deployment" 900

echo "******************************************"
echo "*** (BEGIN) Setting up student account ***"
echo "******************************************"
lab-bootstrap begin student-account "Setting up student account" 10

echo "*** Adding Student Account ${QWIKLABS_USERNAME} Home ***"
mkhomedir_helper ${QWIKLABS_USERNAME}

lab-bootstrap end student-account
echo "****************************************"
echo "*** (END) Setting up student account ***"
echo "****************************************"



export HOME=/root
cd ~

echo "********************************************"
echo "*** (BEGIN) Installing GCP Logging Agent ***"
echo "********************************************"
lab-bootstrap begin cloud-logger "Setting up GCP logging agent" 30

GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json"
mkdir -p $(dirname ${GOOGLE_APPLICATION_CREDENTIALS})
echo "${PROJECT_SERVICE_ACCOUNT_JSON}" > $GOOGLE_APPLICATION_CREDENTIALS
chown root:root "$GOOGLE_APPLICATION_CREDENTIALS"
chmod 0400 "$GOOGLE_APPLICATION_CREDENTIALS"

curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update -y
apt-get install -y google-fluentd google-fluentd-catch-all-config-structured
service google-fluentd start

lab-bootstrap end cloud-logger
echo "******************************************"
echo "*** (END) Installing GCP Logging Agent ***"
echo "******************************************"


echo "******************************************"
echo "*** (BEGIN) Installing bootstrap tools ***"
echo "******************************************"
lab-bootstrap begin bootstrap-tools "Installing base tools" 30

snap install kubectl --classic
snap install jq
apt-get install -y git

lab-bootstrap end bootstrap-tools
echo "****************************************"
echo "*** (END) Installing bootstrap tools ***"
echo "****************************************"


echo "******************************************"
echo "*** (BEGIN) Setting up lab private key ***"
echo "******************************************"

echo '${LAB_PRIVATE_KEY}' > lab-privkey.pem
chmod 600 ~/lab-privkey.pem
export GIT_SSH_COMMAND="ssh -i ~/lab-privkey.pem"
ssh-keyscan github.com >> ~/.ssh/known_hosts

echo "****************************************"
echo "*** (END) Setting up lab private key ***"
echo "****************************************"


echo "******************************************"
echo "*** (BEGIN) Creating environment files ***"
echo "******************************************"

cat << EOF >> ~/lab.env
LAB_REPO='${LAB_REPO}'
LAB_BRANCH='${LAB_BRANCH}'

DM_REPO='${DM_REPO}'
DM_BRANCH='${DM_BRANCH}'
EOF

cat << EOF >> ~/env
export HOME=/root
export PATH="${HOME}/lab-deployment-manager/bin:/snap/bin:\$PATH"
source utils.sh

export PROJECT='${PROJECT}'
export ENV='${ENV}'
export REGION='${REGION}'
export ZONE='${ZONE}'
export VM_EXTERNAL_IP='${VM_EXTERNAL_IP}'
export GIT_SSH_COMMAND="ssh -i ~/lab-privkey.pem"
export PROJECT_SERVICE_ACCOUNT='${PROJECT_SERVICE_ACCOUNT}'
export ASSETS_SERVICE_ACCOUNT='${ASSETS_SERVICE_ACCOUNT}'
export PROJECT_SERVICE_ACCOUNT_JSON='${PROJECT_SERVICE_ACCOUNT_JSON}'
export ASSETS_SERVICE_ACCOUNT_JSON='${ASSETS_SERVICE_ACCOUNT_JSON}'
export USE_REAL_CERT='${USE_REAL_CERT}'
export QWIKLABS_USERNAME='${QWIKLABS_USERNAME}'
export QWIKLABS_USERPASSWORD='${QWIKLABS_USERPASSWORD}'

source ~/lab.env
EOF

echo "****************************************"
echo "*** (END) Creating environment files ***"
echo "****************************************"


echo "******************************************"
echo "*** (BEGIN) Cloning deployment manager (${DM_BRANCH} branch) ***"
echo "******************************************"
lab-bootstrap begin lab-dm "Cloning deployment manager git repo" 10

git clone -q ${DM_REPO}
pushd lab-deployment-manager
git checkout ${DM_BRANCH}
export PATH=~/lab-deployment-manager/bin:$PATH
popd

lab-bootstrap end lab-dm
echo "******************************************"
echo "*** (END) Cloning deployment manager (${DM_BRANCH} branch) ***"
echo "******************************************"


apt-get install expect -y
unbuffer dm-startup.sh
lab-bootstrap end overall-deployment
