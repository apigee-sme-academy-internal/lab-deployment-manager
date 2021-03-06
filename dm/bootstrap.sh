#!/usr/bin/env bash
cd ~

#
export PROJECT_SERVICE_ACCOUNT_JSON='%keyFile%'
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

export KEY_PASS=$(get_qwiklab_property '%key_pass%' "")


export HOME=/root
apt-get update
apt-get install -y git

echo "*** Cloning deployment manager (${DM_BRANCH} branch) ***"
mkdir -p ~/dm && cd ~/dm
git clone -q ${DM_REPO} .
source ./bin/utils.sh
checkout_branch "${DM_BRANCH}" "master"

cat << EOF >> ~/env
BASEDIR="\$( cd "\$( dirname "\$0" )" && pwd )"
export HOME='${HOME}'
export PATH="${HOME}/dm/bin:/snap/bin:\$PATH"

export ZONE='${ZONE}'
export REGION='${REGION}'
export DM_REPO='${DM_REPO}'
export DM_BRANCH='${DM_BRANCH}'
export ENV='${ENV}'
export LAB_REPO='${LAB_REPO}'
export LAB_BRANCH='${LAB_BRANCH}'
export USE_REAL_CERT='${USE_REAL_CERT}'
export PROJECT_SERVICE_ACCOUNT_JSON='${PROJECT_SERVICE_ACCOUNT_JSON}'
export QWIKLABS_USERNAME='${QWIKLABS_USERNAME}'
export QWIKLABS_USERPASSWORD='${QWIKLABS_USERPASSWORD}'
export LAB_PRIVATE_KEY='${LAB_PRIVATE_KEY}'
export LAB_BRANCH_BUILD='${LAB_BRANCH_BUILD}'
export LAB_REPO_BUILD='${LAB_REPO_BUILD}'
export KEY_PASS='${KEY_PASS}'
source utils.sh
EOF

./bin/dm.sh
