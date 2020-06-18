#!/usr/bin/env bash
# This is the script that runs when in the initial VM created by the
# qwiklabs deployment manager.

# The first thing we do in this script is that we login to gcloud
# using the service account JSON for the qwiklabs student.
# This service account has elevated privileges (project owner).

# After that, we create a new VM with the student service account.
# This new VM has full access to the GCP APIs within the project.
# The remaining bootstrap activities are completed within this new VM.

cd ~

export KEY_FILE='%keyFile%'
export QWIKLAB_USER='%userName%'
export QWIKLAB_PASSWORD='%userPassword%'
export ZONE='%zone%'
export REGION='%region%'

echo -n ${KEY_FILE} > account.json

snap install google-cloud-sdk
snap install jq

## Activate service account
export PATH=/snap/bin:$PATH
gcloud auth activate-service-account --key-file account.json
export SERVICE_ACCOUNT=$(gcloud config list account --format "value(core.account)")
export PROJECT=$(gcloud config get-value project)


# Create startup script
# This is split into two sections
# First section, add the env vars (variable expansion is active)
cat << EOF > ./startup.sh
#!/usr/bin/env bash

export ZONE="$ZONE"
export REGION="$REGION"
export QWIKLAB_USER="$QWIKLAB_USER"
export QWIKLAB_PASSWORD="$QWIKLAB_PASSWORD"
export PROJECT="$PROJECT"
export HOME=/root
export SERVICE_ACCOUNT_JSON='${KEY_FILE}'

EOF
# Second section, the rest of the startup (variable expansion is not active)
cat << 'EOF' >> ./startup.sh
cd ~
echo "*** Installing GCP Logging Agent ***"
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update -y
apt-get install -y google-fluentd google-fluentd-catch-all-config-structured
service google-fluentd start

echo "*** Installing kubectl, gcloud, jq ***"
snap install kubectl --classic
snap install google-cloud-sdk
snap install jq
snap install git-ubuntu --classic
export PATH=/snap/bin:$PATH


export NODE_VERSION=v12.18.0
export NODE_DIR=node-${NODE_VERSION}-linux-x64
export NODE_TARBALL=${NODE_DIR}.tar.gz

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

echo "*** Installing Node.js ($NODE_VERSION) ***"
curl -O https://nodejs.org/dist/${NODE_VERSION}/${NODE_TARBALL}
tar -xzf ${NODE_TARBALL}
sudo mv ${NODE_DIR} /opt/${NODE_DIR}
chmod a+rwx -R /opt/${NODE_DIR}
export PATH=/opt/${NODE_DIR}/bin:$PATH

echo "*** Installing Java 14 ***"
curl -O https://download.java.net/java/GA/jdk14/076bab302c7b4508975440c56f6cc26a/36/GPL/openjdk-14_linux-x64_bin.tar.gz
tar -xzf openjdk-14_linux-x64_bin.tar.gz
chmod a+rwx -R jdk-14
sudo mv jdk-14 /opt
export PATH=/opt/jdk-14/bin:$PATH

export MVN_VERSION=3.6.3
export MVN_DIR=apache-maven-${MVN_VERSION}

echo "*** Installing Maven 3 ***"
curl -O http://mirror.cc.columbia.edu/pub/software/apache/maven/maven-3/${MVN_VERSION}/binaries/${MVN_DIR}-bin.tar.gz
tar -xzf ${MVN_DIR}-bin.tar.gz
chmod a+rwx -R ${MVN_DIR}
sudo mv ${MVN_DIR} /opt/
export PATH=/opt/${MVN_DIR}/bin:$PATH

echo "*** Setup lab private key ***"
echo '${LAB_PRIVATE_KEY}' > lab_private_key.pem
chmod 600 ~/lab_private_key.pem
export GIT_SSH_COMMAND="ssh -i ~/lab_private_key.pem"

echo "*** Setup Assets service account ***"
export ASSETS_SERVICE_ACCOUNT_JSON='${ASSETS_SERVICE_ACCOUNT_JSON}'

ssh-keyscan github.com >> ~/.ssh/known_hosts

echo "*** Cloning Hybrid player ***"
git clone git@github.com:apigee-sme-academy-internal/qwiklabs-hybrid-player.git
pushd qwiklabs-hybrid-player
git checkout master
export PATH=~/qwiklabs-hybrid-player/bin:$PATH
popd

echo "*** Cloning lab content repo ***"
git clone "${LAB_REPO}"
export LAB_DIR="$(pwd)/$(basename "${LAB_REPO}" .git)"
cd ${LAB_DIR}
git checkout ${LAB_BRANCH}

echo "*** Setup env file ***"
cat << HEREDOC > ~/env
export ZONE="$ZONE"
export REGION="$REGION"
export QWIKLAB_USER="$QWIKLAB_USER"
export QWIKLAB_PASSWORD="$QWIKLAB_PASSWORD"
export PROJECT="$PROJECT"
export HOME="$HOME"
export LAB_DIR="$LAB_DIR"
export GIT_SSH_COMMAND="$GIT_SSH_COMMAND"
export PATH="$PATH"
export SERVICE_ACCOUNT_JSON='$SERVICE_ACCOUNT_JSON'
export ASSETS_SERVICE_ACCOUNT_JSON='$ASSETS_SERVICE_ACCOUNT_JSON'

function wait_for_service_ip() {
  service_ip="null"
  service_name=\$1
  while [ -z "\$service_ip" ] || [ "\$service_ip" == "null" ]; do
    echo "Waiting for \${service_name} IP address ...";
    service_ip=\$(kubectl get service \${service_name} -o json | jq ".status.loadBalancer.ingress[0].ip" -r);
    [ -z "\$service_ip" ] || [ "\$service_ip" == "null" ] && sleep 10;
  done;
}

function get_service_ip_and_port() {
  service_name=\$1
  service_ip=\$(kubectl get service \${service_name} -o json | jq ".status.loadBalancer.ingress[0].ip" -r)
  service_port=\$(kubectl get service \${service_name} -o json | jq ".spec.ports[0].port" -r)
  echo "\${service_ip}:\${service_port}"
}

HEREDOC

echo "*** Running lab startup script ***"
./startup.sh
EOF

#Create VM to bootstrap the lab
gcloud compute instances create lab-startup \
    --machine-type=n1-standard-2 \
    --subnet=default \
    --zone $ZONE \
    --service-account=$SERVICE_ACCOUNT \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --image-family=ubuntu-1804-lts \
    --image-project=ubuntu-os-cloud \
    --metadata-from-file startup-script=./startup.sh