#!/usr/bin/env bash
gcloud config set project apigee-sme-academy
gcloud secrets versions access --secret=automation-deploy-key latest > ./build/deploy-key.pem

echo "##### Building Lab 1 DM ..."
export LAB_ZIP="lab1-dm.zip"
export LAB_REPO="git@github.com:apigee-sme-academy-internal/app-modernization-lab-1.git"
export LAB_BRANCH="master"
./build.sh ${LAB_REPO} ${LAB_BRANCH} ./build/deploy-key.pem ${LAB_ZIP}

echo "##### Building Lab 2 DM ..."
export LAB_ZIP="lab2-dm.zip"
export LAB_REPO="git@github.com:apigee-sme-academy-internal/app-modernization-lab-2.git"
export LAB_BRANCH="${LAB_BRANCH:-master}"
./build.sh ${LAB_REPO} ${LAB_BRANCH} ./build/deploy-key.pem ${LAB_ZIP}


echo "##### Building Lab 3 DM ..."
export LAB_ZIP="lab3-dm.zip"
export LAB_REPO="git@github.com:apigee-sme-academy-internal/app-modernization-lab-3.git"
export LAB_BRANCH="master"
./build.sh ${LAB_REPO} ${LAB_BRANCH} ./build/deploy-key.pem ${LAB_ZIP}

echo "##### Building Lab 4 DM ..."
export LAB_ZIP="lab4-dm.zip"
export LAB_REPO="git@github.com:apigee-sme-academy-internal/app-modernization-lab-4.git"
export LAB_BRANCH="master"
./build.sh ${LAB_REPO} ${LAB_BRANCH} ./build/deploy-key.pem ${LAB_ZIP}

echo "##### Building Lab 5 DM ..."
export LAB_ZIP="lab4-dm.zip"
export LAB_REPO="git@github.com:apigee-sme-academy-internal/app-modernization-lab-5.git"
export LAB_BRANCH="master"
./build.sh ${LAB_REPO} ${LAB_BRANCH} ./build/deploy-key.pem ${LAB_ZIP}



rm -f ./build/deploy-key.pem