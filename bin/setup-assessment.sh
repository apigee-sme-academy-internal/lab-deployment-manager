#!/usr/bin/env bash

cd ~
source ~/env

echo "********************************"
echo "*** (BEGIN) Setup Assessment ***"
echo "********************************"

STUDENT_HOME="/home/${QWIKLABS_USERNAME}"

export HOME=${STUDENT_HOME}
export ASSESSMENT_DIR="${STUDENT_HOME}/assessment"

# Copy framework to student's home directory
cp -r "${HYBRID_PLAYER_DIR}/assessment" "${ASSESSMENT_DIR}"

# Overwrite environment file
cat << EOF > "${ASSESSMENT_DIR}/assessment.env"
# this file is used for activity tracking, do not edit it manually
export PROJECT='${PROJECT}'
export CLUSTER_ZONE='${ZONE}'
export PATH="/snap/bin:\$PATH"
export ORG='${PROJECT}'
export ENV='test'
export PROJECT_SERVICE_ACCOUNT_JSON='${PROJECT_SERVICE_ACCOUNT_JSON}'
EOF

# Make files accessible by student
chown -R "${QWIKLABS_USERNAME}:ubuntu" "${ASSESSMENT_DIR}"

# Make shell scripts executable
find "${ASSESSMENT_DIR}" -name "*.sh" -exec chmod a+x {} \;

echo "******************************"
echo "*** (END) Setup Assessment ***"
echo "******************************"