#!/usr/bin/env bash

cd ~
source ~/env

echo "********************************"
echo "*** (BEGIN) Setup Assessment ***"
echo "********************************"

STUDENT_HOME="/home/${QWIKLABS_USERNAME}"
export ASSESSMENT_DIR="${STUDENT_HOME}/assessment"

# copy framework to student's home directory
cp -r "${HYBRID_PLAYER_DIR}/assessment" "${ASSESSMENT_DIR}"

cp ~/certs.env "${ASSESSMENT_DIR}/"

# render env file
envsubst < "${ASSESSMENT_DIR}/assessment.env.tpl" > "${ASSESSMENT_DIR}/assessment.env"

# make files accessible by student
chown -R "${QWIKLABS_USERNAME}:ubuntu" "${ASSESSMENT_DIR}"

# Make shell scripts executable
find "${ASSESSMENT_DIR}" -name "*.sh" -exec chmod a+x {} \;

echo "******************************"
echo "*** (END) Setup Assessment ***"
echo "******************************"