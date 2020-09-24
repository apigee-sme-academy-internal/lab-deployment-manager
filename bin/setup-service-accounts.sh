#!/usr/bin/env bash
source ~/env

task_id="setup-service-accounts"
setup_logger "${task_id}"
setup_error_handler "${task_id}"

cd ~

## Activate service account
echo "*******************************************"
echo "*** (BEGIN) Setting up service accounts ***"
echo "*******************************************"

snap install google-cloud-sdk
export PATH=/snap/bin:$PATH

export KEY_PASS="${KEY_PASS:-Apigee123}"
export ASSETS_SERVICE_ACCOUNT_JSON=$(openssl enc -aes-256-cbc -d -in <(gsutil cat gs://apigee-sme-academy/automation-svc.json.enc) -pass "pass:${KEY_PASS}")

# Save the project svc account name
activate_service_account "${PROJECT_SERVICE_ACCOUNT_JSON}"
export PROJECT_SERVICE_ACCOUNT=$(gcloud config list account --format "value(core.account)")
export PROJECT=$(gcloud config get-value project)

# Activate and save the assets svc account name
activate_service_account "${ASSETS_SERVICE_ACCOUNT_JSON}"
export ASSETS_SERVICE_ACCOUNT=$(gcloud config list account --format "value(core.account)")

# Make the project service account be the active one
gcloud config set account "${PROJECT_SERVICE_ACCOUNT}"





cat << EOF >> ~/accounts.env
export PROJECT='${PROJECT}'
export PROJECT_SERVICE_ACCOUNT='${PROJECT_SERVICE_ACCOUNT}'
export ASSETS_SERVICE_ACCOUNT='${ASSETS_SERVICE_ACCOUNT}'
EOF

echo "source ~/accounts.env" >> ~/env

echo "*****************************************"
echo "*** (END) Setting up service accounts ***"
echo "*****************************************"