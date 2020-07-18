#!/usr/bin/env bash

source ~/env
setup_logger "setup-student-home"

cd ~


echo "******************************************"
echo "*** (BEGIN) Setting up student account ***"
echo "******************************************"
lab-bootstrap begin student-account "Setting up student account" 10

echo "*** Adding Student Account ${QWIKLABS_USERNAME} Home ***"
mkhomedir_helper ${QWIKLABS_USERNAME}


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


lab-bootstrap end student-account
echo "****************************************"
echo "*** (END) Setting up student account ***"
echo "****************************************"
