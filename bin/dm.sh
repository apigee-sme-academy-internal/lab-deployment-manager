#!/usr/bin/env bash

source ~/env

set -e
trap 'catch $? $LINENO' EXIT
catch() {
  exit_code="$1"
  exit_line="$2"
  if [ "$1" != "0" ]; then
    echo "ERROR: ${exit_code} occurred on ${exit_line}"
    if ! command -v lab-bootstrap &> /dev/null  ; then
      lab-bootstrap update overall-deployment "errored"
      return
    fi
  fi
}

setup_logger "dm"

setup-service-accounts.sh
setup-dns-metadata.sh
setup-bootstrap-tool.sh

lab-bootstrap begin overall-deployment "Overall deployment" 900

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

lab-bootstrap end overall-deployment