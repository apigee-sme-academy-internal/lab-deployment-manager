#!/usr/bin/env bash

source ~/env
setup_logger "setup-gs-bucket"

echo "*******************************************"
echo "*** (BEGIN) Setting up GS Assets Bucket ***"
echo "*******************************************"
lab-bootstrap begin lab-gs "Configuring GS assets bucket" 10

cd ~

echo "*** Setup lab assets storage bucket ***"

# Create bucket (with same name as project name)
gsutil mb -b on gs://${PROJECT}

# Make bucket public
gsutil iam ch allUsers:objectViewer gs://${PROJECT}

# Setup bucket CORS
cat << 'CORSHEREDOC' >> bucket-cors.json
[
  {
    "maxAgeSeconds": 3000,
    "method": [
      "GET"
    ],
    "origin": [
      "*"
    ],
    "responseHeader": [
      "*",
      "Authorization",
      "Accept",
      "Accept-Encoding",
      "Accept-Language",
      "Connection",
      "Host",
      "If-None-Match",
      "Origin",
      "Referer",
      "Sec-Fetch-Dest",
      "Sec-Fetch-Mode",
      "Sec-Fetch-Site",
      "User-Agent",
      "Authorization",
      "Content-Range",
      "Accept",
      "Content-Type",
      "Origin",
      "Range"
    ]
  }
]
CORSHEREDOC

gsutil cors set bucket-cors.json gs://${PROJECT}

lab-bootstrap end lab-gs
echo "*****************************************"
echo "*** (END) Setting up GS Assets Bucket ***"
echo "*****************************************"
