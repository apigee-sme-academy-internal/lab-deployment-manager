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


export ZONE=$(get_qwiklab_property '%zone%' "us-west1-b")
export REGION=$(get_qwiklab_property '%region%' "us-west1")

export DM_REPO=$(get_qwiklab_property '%dm_repo%' "git@github.com:apigee-sme-academy-internal/lab-deployment-manager.git")
export DM_BRANCH=$(get_qwiklab_property '%dm_branch%' "master")
export ENV=$(get_qwiklab_property '%env%' "test")

export LAB_REPO=$(get_qwiklab_property '%lab_repo%' "${LAB_REPO_BUILD}")
export LAB_BRANCH=$(get_qwiklab_property '%lab_branch%' "${LAB_BRANCH_BUILD}")

export USE_REAL_CERT=$(get_qwiklab_property '%use_real_cert%' "false")

# Hand off the rest to the main bootstrap in the bin directory
curl -sSOL https://raw.githubusercontent.com/apigee-sme-academy-internal/lab-deployment-manager/${DM_BRANCH}/bin/bootstrap.sh
chmod a+x ./bootstrap.sh
source ./bootstrap.sh
