#!/usr/bin/env bash
cd ~

source ~/env
setup_logger "dm"

get-cert.sh
install-tools.sh
setup-gs-bucket.sh
setup-hybrid-player-repo.sh
setup-lab-repo.sh

# hand off the remaining setup to the lab's startup.sh
source ~/env
cd ${LAB_DIR}
./startup.sh











