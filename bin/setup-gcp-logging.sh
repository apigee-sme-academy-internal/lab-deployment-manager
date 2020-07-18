#!/usr/bin/env bash

source ~/env
setup_logger "setup-gcp-logging"

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