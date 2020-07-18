#!/usr/bin/env bash

sourcd ~/env
setup_logger "dm"

setup-service-accounts.sh
setup-bootstrap-tool.sh

lab-bootstrap begin overall-deployment "Overall deployment" 900

setup-student-home.sh
setup-gcp-logging.sh
install-base-tools.sh
setup-lab-key.sh
setup-main-env.sh
get-cert.sh
install-tools.sh
setup-student-env.sh
setup-gs-bucket.sh
setup-hybrid-player-repo.sh
setup-assessment.sh
setup-lab-repo.sh

source ~/env
cd "${LAB_DIR}" && ./startup.sh

lab-bootstrap end overall-deployment