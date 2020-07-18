#!/usr/bin/env bash

source ~/env
setup_logger "setup-service-accounts"

cd ~

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





cat << EOF >> ~/accounts.env
export PROJECT='${PROJECT}'
export PROJECT_SERVICE_ACCOUNT='${PROJECT_SERVICE_ACCOUNT}'
export ASSETS_SERVICE_ACCOUNT='${ASSETS_SERVICE_ACCOUNT}'
EOF

echo "source ~/accounts.env" >> ~/env

echo "*****************************************"
echo "*** (END) Setting up service accounts ***"
echo "*****************************************"