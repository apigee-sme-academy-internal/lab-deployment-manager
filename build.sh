#!/bin/bash

export LAB_REPO="$1"
export LAB_BRANCH="$2"
export LAB_PRIVATE_KEY_FILE="$3"
export LAB_ZIP_FILE=${4:-deployment-manager.zip}

if [[ -z "$LAB_REPO" ]] ; then
  echo "error: LAB_REPO url is required"
  exit 1
fi

if [[ -z "$LAB_BRANCH" ]] ; then
  echo "error: LAB_BRANCH  is required"
  exit 1
fi

rm -rf ./build/dm ./build/${LAB_ZIP_FILE}
cp -r dm ./build/dm

if [[ -f "$LAB_PRIVATE_KEY_FILE" ]] ; then
  echo "Using custom private key ..."
  export LAB_PRIVATE_KEY=$(cat $LAB_PRIVATE_KEY_FILE)
else
  echo "Using ephemeral key private key ..."
  export LAB_PRIVATE_KEY=$(openssl genrsa 2048 2> /dev/null)
fi

export AUTOMATION_GCP_SERVICE_ACCOUNT_JSON=$(gcloud secrets versions access --secret=automation-gcp-service-account latest)

envsubst '${LAB_REPO},${LAB_BRANCH},${LAB_PRIVATE_KEY},${AUTOMATION_GCP_SERVICE_ACCOUNT_JSON}' < ./build/dm/bootstrap.sh > ./build/dm/bootstrap.sh.temp
mv ./build/dm/bootstrap.sh.temp ./build/dm/bootstrap.sh

zip -j build/${LAB_ZIP_FILE} ./build/dm/*

