#!/usr/bin/env bash

export LAB_ZIP="lab2-dm.zip"
export LAB_REPO="git@github.com:apigee-sme-academy-internal/app-modernization-lab-2.git"
export LAB_BRANCH="master"
gcloud secrets versions access --secret=automation-deploy-key latest > ./build/deploy-key.pem


./build.sh ${LAB_REPO} ${LAB_BRANCH} ./build/deploy-key.pem ${LAB_ZIP}
rm -f ./build/deploy-key.pem