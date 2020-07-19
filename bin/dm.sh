#!/usr/bin/env bash
source ~/env

task_id="dm"
setup_logger "${task_id}"
setup_error_handler "${task_id}"

setup-service-accounts.sh
setup-dns-metadata.sh
setup-bootstrap-tool.sh

lab-bootstrap begin "${task_id}" "Overall deployment" 900

setup-student-home.sh
setup-gcp-logging.sh
setup-base-tools.sh
setup-cert.sh
setup-lab-tools.sh
setup-student-home.sh
setup-gs-bucket.sh
setup-hybrid-player-repo.sh
setup-assessment.sh
setup-lab-repo.sh

source ~/env
cd "${LAB_DIR}" && ./startup.sh

lab-bootstrap end "${task_id}"