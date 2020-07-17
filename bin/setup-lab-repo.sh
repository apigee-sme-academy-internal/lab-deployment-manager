#!/usr/bin/env bash

source ~/env
cd ~

echo "******************************"
echo "*** (BEGIN) Lab repo setup ***"
echo "******************************"
lab-bootstrap begin lab-repo "Cloning lab repo"


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
