#!/usr/bin/env bash

source ~/env
setup_logger "setup-lab-repo"

cd ~

echo "******************************"
echo "*** (BEGIN) Lab repo setup ***"
echo "******************************"
lab-bootstrap begin lab-repo "Cloning lab git repo" 10

echo '${LAB_PRIVATE_KEY}' > lab-key.pem
chmod 600 ~/lab-key.pem
export GIT_SSH_COMMAND="ssh -i ~/lab-key.pem"

clone_repo_and_checkout_branch ${LAB_REPO} ${LAB_BRANCH}
export LAB_DIR="$(pwd)/$(get_repo_dir ${LAB_REPO})"

cat << EOF >> ~/lab.env
export LAB_DIR='${LAB_DIR}'
EOF

echo "source ~/lab.env" >> ~/env

lab-bootstrap end lab-repo
echo "****************************"
echo "*** (END) Lab repo setup ***"
echo "****************************"
