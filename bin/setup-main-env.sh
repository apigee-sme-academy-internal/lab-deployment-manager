#!/usr/bin/env bash

source ~/env
setup_logger "setup-main-env"

cd ~

echo "******************************************"
echo "*** (BEGIN) Creating environment files ***"
echo "******************************************"

cat << EOF >> ~/env
export PATH="$PATH:/snap/bin:\$PATH"

LAB_REPO='${LAB_REPO}'
LAB_BRANCH='${LAB_BRANCH}'

DM_REPO='${DM_REPO}'
DM_BRANCH='${DM_BRANCH}'

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

EOF

echo "****************************************"
echo "*** (END) Creating environment files ***"
echo "****************************************"