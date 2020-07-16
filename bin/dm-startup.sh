#!/usr/bin/env bash
cd ~

source ~/env
setup_logger "dm"

task_run "certs" "Create certificates" get-cert.sh
task_run "tools" "Installing tools" install-tools.sh
task_run "student-env" "Setup student environment" setup-student-env.sh
task_run "storage-bucket" "Configure GCP storage bucket" setup-gs-bucket.sh
task_run "hybrid-player-repo" "Setup hybrid player repo" setup-hybrid-player-repo.sh
task_run "assessment" "Configure activity tracking" setup-assessment.sh
task_run "lab-repo" "Setup lab repo" setup-lab-repo.sh

# hand off the remaining setup to the lab's startup.sh
source ~/env
cd ${LAB_DIR}
./startup.sh











