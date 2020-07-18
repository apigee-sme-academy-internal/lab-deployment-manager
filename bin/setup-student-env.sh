#!/usr/bin/env bash

cd ~
source ~/env

echo "*********************************"
echo "*** (BEGIN) Setup Student Env ***"
echo "*********************************"
lab-bootstrap begin lab-student-env "Configuring student environment" 10


STUDENT_HOME="/home/${QWIKLABS_USERNAME}"

cat << EOF >> "${STUDENT_HOME}/lab.env"

export PATH="/snap/bin:\$PATH"

export PROJECT=\$(gcloud config get-value project)

export ZONE=\$(gcloud compute project-info describe --format="json" |
              jq -r  '.commonInstanceMetadata.items[]  |
              select(.key == "google-compute-default-zone") |
              .value')

export ENV="test"

export ACCESS_TOKEN=\$(gcloud auth print-access-token)

EOF

chown "${QWIKLABS_USERNAME}:ubuntu" "${STUDENT_HOME}/lab.env"

export HOME=${STUDENT_HOME}
sudo -u $QWIKLABS_USERNAME -E bash -c 'gcloud auth activate-service-account --key-file=<(echo ${PROJECT_SERVICE_ACCOUNT_JSON})'

lab-bootstrap end lab-student-env
echo "*******************************"
echo "*** (END) Setup Student Env ***"
echo "*******************************"