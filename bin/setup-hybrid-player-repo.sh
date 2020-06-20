#!/usr/bin/env bash

source ~/env
setup_logger "setup-hybrid-player"

echo "***********************************"
echo "*** (BEGIN) Setup Hybrid Player ***"
echo "***********************************"

cd ~

export HYBRID_PLAYER_REPO='git@github.com:apigee-sme-academy-internal/qwiklabs-hybrid-player.git'
clone_repo_and_checkout_branch ${HYBRID_PLAYER_REPO} ${DM_BRANCH}

export HYBRID_PLAYER_PATH="$(pwd)/$(get_repo_dir ${HYBRID_PLAYER_REPO})/bin"

cat << EOF >> ~/hybrid-player.env
export HYBRID_PLAYER_PATH='${HYBRID_PLAYER_PATH}'
export PATH="\${HYBRID_PLAYER_PATH}:\${PATH}"
EOF

echo "source ~/hybrid-player.env" >> ~/env

echo "*********************************"
echo "*** (END) Setup Hybrid Player ***"
echo "*********************************"

