#!/usr/bin/env bash

source ~/env
setup_logger "setup-hybrid-player"

echo "***********************************"
echo "*** (BEGIN) Setup Hybrid Player ***"
echo "***********************************"
lab-bootstrap begin hybrid-player "Cloning hybrid player git repo" 10


cd ~

export HYBRID_PLAYER_REPO='https://github.com/apigee-sme-academy-internal/qwiklabs-hybrid-player.git'
clone_repo_and_checkout_branch ${HYBRID_PLAYER_REPO} ${DM_BRANCH}

export HYBRID_PLAYER_DIR="$(pwd)/$(get_repo_dir ${HYBRID_PLAYER_REPO})"
export HYBRID_PLAYER_PATH="${HYBRID_PLAYER_DIR}/bin"

cat << EOF >> ~/hybrid-player.env
export HYBRID_PLAYER_REPO='${HYBRID_PLAYER_REPO}'
export HYBRID_PLAYER_DIR='${HYBRID_PLAYER_DIR}'
export HYBRID_PLAYER_PATH='${HYBRID_PLAYER_PATH}'
export PATH="\${HYBRID_PLAYER_PATH}:\${PATH}"
EOF

echo "source ~/hybrid-player.env" >> ~/env

lab-bootstrap end hybrid-player
echo "*********************************"
echo "*** (END) Setup Hybrid Player ***"
echo "*********************************"


