#!/usr/bin/env bash
source ~/env

task_id="setup-lab-repo"
begin_task "${task_id}" "Cloning lab git repo" 10

cd ~

echo "******************************"
echo "*** (BEGIN) Lab repo setup ***"
echo "******************************"

cat << EOF > ~/lab-key.pem
${LAB_PRIVATE_KEY}
EOF

chmod 600 ~/lab-key.pem
export GIT_SSH_COMMAND="ssh -i ${HOME}/lab-key.pem"

ssh-keyscan github.com >> ~/.ssh/known_hosts

clone_repo_and_checkout_branch ${LAB_REPO} ${LAB_BRANCH}
export LAB_DIR="$(pwd)/$(get_repo_dir ${LAB_REPO})"

cat << EOF >> ~/lab.env
export GIT_SSH_COMMAND='${GIT_SSH_COMMAND}'
export LAB_DIR='${LAB_DIR}'
EOF

echo "source ~/lab.env" >> ~/env

end_task "${task_id}"
echo "****************************"
echo "*** (END) Lab repo setup ***"
echo "****************************"