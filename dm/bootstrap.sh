#!/usr/bin/env bash
cd ~

#
export PROJECT_SERVICE_ACCOUNT_JSON='%keyFile%'
export ASSETS_SERVICE_ACCOUNT_JSON='{{AUTOMATION_GCP_SERVICE_ACCOUNT_JSON}}'
export QWIKLABS_USERNAME='%userName%'
export QWIKLABS_USERPASSWORD='%userPassword%'

export LAB_PRIVATE_KEY='{{LAB_PRIVATE_KEY}}'
export LAB_BRANCH_BUILD='{{LAB_BRANCH_BUILD}}'
export LAB_REPO_BUILD='{{LAB_REPO_BUILD}}'

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

export DM_REPO=$(get_qwiklab_property '%dm_repo%' "https://github.com/apigee-sme-academy-internal/lab-deployment-manager.git")
export DM_BRANCH=$(get_qwiklab_property '%dm_branch%' "master")
export ENV=$(get_qwiklab_property '%env%' "test")

export LAB_REPO=$(get_qwiklab_property '%lab_repo%' "${LAB_REPO_BUILD}")
export LAB_BRANCH=$(get_qwiklab_property '%lab_branch%' "${LAB_BRANCH_BUILD}")

export USE_REAL_CERT=$(get_qwiklab_property '%use_real_cert%' "false")

export HOME=/root
apt-get update
apt-get install -y git

echo "*** Cloning deployment manager (${DM_BRANCH} branch) ***"
mkdir -p ~/dm && cd ~/dm
git clone -q ${DM_REPO} .
git checkout "${DM_BRANCH}"

cat << EOF >> ~/env
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export HOME='${HOME}'
export PATH="~/dm/bin:\$PATH"
source utils.sh

EOF

source ~/env
dm.sh
