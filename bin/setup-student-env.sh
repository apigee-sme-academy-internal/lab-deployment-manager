#!/usr/bin/env bash

cd ~
source ~/env

echo "*********************************"
echo "*** (BEGIN) Setup Student Env ***"
echo "*********************************"


STUDENT_HOME="/home/${QWIKLABS_USERNAME}"
mkdir -p "$STUDENT_HOME"
chmod a+rwx "$STUDENT_HOME"

cat << EOF >> $STUDENT_HOME/lab.env

export PROJECT=\$(gcloud config get-value project)

export ZONE=\$(gcloud compute project-info describe --format="json" |
              jq -r  '.commonInstanceMetadata.items[]  |
              select(.key == "google-compute-default-zone") |
              .value')

export ENV="test"

export ACCESS_TOKEN=\$(gcloud auth print-access-token)

export PROJECT_SERVICE_ACCOUNT_JSON='${PROJECT_SERVICE_ACCOUNT_JSON}'

EOF

export HOME=$STUDENT_HOME
cd ~
gcloud auth activate-service-account --key-file=<(echo ${PROJECT_SERVICE_ACCOUNT_JSON})
rm -f /tmp/service_account.json

echo "*******************************"
echo "*** (END) Setup Student Env ***"
echo "*******************************"