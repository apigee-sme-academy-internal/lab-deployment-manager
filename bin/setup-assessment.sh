#!/usr/bin/env bash

cd ~
source ~/env

echo "********************************"
echo "*** (BEGIN) Setup Assessment ***"
echo "********************************"
lab-bootstrap begin lab-at "Configuring activity tracking"

export STUDENT_HOME="/home/${QWIKLABS_USERNAME}"
export ASSESSMENT_DIR="${STUDENT_HOME}/assessment"

# copy framework to student's home directory
cp -r "${HYBRID_PLAYER_DIR}/assessment" "${ASSESSMENT_DIR}"

# render handlebars style template using {{...}} style
# first, replace $ for §
# second, replace {{FOO}} for ${FOO}
# third, substitute env vars
# fourth, replace § for $

cat "${ASSESSMENT_DIR}/assessment.env" \
   | perl -pe 's#\$#§#g' \
   | perl -pe 's#\{\{([^}]+)\}\}#\${$1}#g' \
   | envsubst \
   | perl -pe 's#§#\$#g' > "${ASSESSMENT_DIR}/assessment.env.new"
mv "${ASSESSMENT_DIR}/assessment.env.new" "${ASSESSMENT_DIR}/assessment.env"

# make files accessible by student
chown -R "${QWIKLABS_USERNAME}:ubuntu" "${ASSESSMENT_DIR}"

# Make shell scripts executable
find "${ASSESSMENT_DIR}" -name "*.sh" -exec chmod a+x {} \;

lab-bootstrap end lab-at
echo "******************************"
echo "*** (END) Setup Assessment ***"
echo "******************************"