#!/usr/bin/env bash
source ~/env

task_id="setup-assessment"
begin_task "${task_id}" "Configuring activity tracking" 10

cd ~

echo "********************************"
echo "*** (BEGIN) Setup Assessment ***"
echo "********************************"

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

end_task "${task_id}"
echo "******************************"
echo "*** (END) Setup Assessment ***"
echo "******************************"