#!/usr/bin/env bash
source ~/env

task_id="setup-gs-bucket"
begin_task "${task_id}" "Configuring GS assets bucket" 10

cd ~

echo "*******************************************"
echo "*** (BEGIN) Setting up GS Assets Bucket ***"
echo "*******************************************"



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

end_task "${task_id}"
echo "*****************************************"
echo "*** (END) Setting up GS Assets Bucket ***"
echo "*****************************************"
