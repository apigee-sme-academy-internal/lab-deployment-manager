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


echo "*** Configure lab-bootstrap tool ***"
curl -sSOL https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/master/dist/linux/lab-bootstrap
mv ./lab-bootstrap /usr/bin/
chmod a+rx /usr/bin/lab-bootstrap

lab-bootstrap begin student-account "Setting up student account"
echo "*** Adding Student Account ${QWIKLABS_USERNAME} Home ***"
mkhomedir_helper ${QWIKLABS_USERNAME}
lab-bootstrap end student-account


snap install google-cloud-sdk
snap install jq
snap install yq

## Activate service account
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

export HOME=/root

cd ~

echo "*** Setting up Logging Agent Credentials ***"
GOOGLE_APPLICATION_CREDENTIALS="/etc/google/auth/application_default_credentials.json"
mkdir -p $(dirname ${GOOGLE_APPLICATION_CREDENTIALS})
echo "${PROJECT_SERVICE_ACCOUNT_JSON}" > $GOOGLE_APPLICATION_CREDENTIALS
chown root:root "$GOOGLE_APPLICATION_CREDENTIALS"
chmod 0400 "$GOOGLE_APPLICATION_CREDENTIALS"


echo "*** Installing GCP Logging Agent ***"
lab-bootstrap begin cloud-logger "Setting up cloud logger"
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update -y
apt-get install -y google-fluentd google-fluentd-catch-all-config-structured
service google-fluentd start
lab-bootstrap end cloud-logger


echo "*** Installing kubectl, git ***"
lab-bootstrap begin base-tools "Installing kubectl, git"
snap install kubectl --classic
export PATH=/snap/bin:$PATH
apt-get install -y git
lab-bootstrap end base-tools


echo "*** Setup lab private key ***"
echo '${LAB_PRIVATE_KEY}' > lab-privkey.pem
chmod 600 ~/lab-privkey.pem
export GIT_SSH_COMMAND="ssh -i ~/lab-privkey.pem"
ssh-keyscan github.com >> ~/.ssh/known_hosts


echo "*** Create env files ***"
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

echo "*** Cloning deployment manager (${DM_BRANCH} branch) ***"
lab-bootstrap begin lab-dm "Cloning deployment manager"
git clone -q ${DM_REPO}
pushd lab-deployment-manager
git checkout ${DM_BRANCH}
export PATH=~/lab-deployment-manager/bin:$PATH
popd

apt-get install expect -y
lab-bootstrap end lab-dm


unbuffer dm-startup.sh