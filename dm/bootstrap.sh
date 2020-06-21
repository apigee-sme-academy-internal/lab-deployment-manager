#!/usr/bin/env bash

cd ~

export PROJECT_SERVICE_ACCOUNT_JSON='%keyFile%'
export ASSETS_SERVICE_ACCOUNT_JSON='${AUTOMATION_GCP_SERVICE_ACCOUNT_JSON}'
export QWIKLAB_USER='%userName%'
export QWIKLAB_PASSWORD='%userPassword%'
export ZONE='%zone%'
export REGION='%region%'

# Values from Qwiklabs take precedence

export DM_REPO='%dm_repo%'
export DM_REPO=${DM_REPO:-git@github.com:apigee-sme-academy-internal/lab-deployment-manager.git}

export DM_BRANCH='%dm_branch%'
export DM_BRANCH=${DM_BRANCH:-master}

export ENV='%env%'
export ENV=${ENV:-test}

# Values from Qwiklabs take precedence
export LAB_REPO='%lab_repo%'
export LAB_REPO="${LAB_REPO:-${LAB_REPO_BUILD}}"

export LAB_BRANCH='%lab_branch%'
export LAB_BRANCH="${LAB_BRANCH:-${LAB_BRANCH_BUILD}}"


snap install google-cloud-sdk
snap install jq

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
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update -y
apt-get install -y google-fluentd google-fluentd-catch-all-config-structured
service google-fluentd start

echo "*** Installing kubectl, git ***"
snap install kubectl --classic
snap install git-ubuntu --classic
export PATH=/snap/bin:$PATH

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
export GIT_SSH_COMMAND="ssh -i ~/lab-privkey.pem"
export PROJECT_SERVICE_ACCOUNT='${PROJECT_SERVICE_ACCOUNT}'
export ASSETS_SERVICE_ACCOUNT='${ASSETS_SERVICE_ACCOUNT}'
export PROJECT_SERVICE_ACCOUNT_JSON='${PROJECT_SERVICE_ACCOUNT_JSON}'
export ASSETS_SERVICE_ACCOUNT_JSON='${ASSETS_SERVICE_ACCOUNT_JSON}'

source ~/lab.env
EOF

echo "*** Cloning deployment manager (${DM_BRANCH} branch) ***"
git clone -q ${DM_REPO}
pushd lab-deployment-manager
git checkout ${DM_BRANCH}
export PATH=~/lab-deployment-manager/bin:$PATH
popd

apt-get install expect -y

unbuffer dm-startup.sh