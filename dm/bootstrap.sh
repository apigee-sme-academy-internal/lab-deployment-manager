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

export ZONE=$ZONE
export REGION=$REGION
export QWIKLAB_USER=$QWIKLAB_USER
export QWIKLAB_PASSWORD=$QWIKLAB_PASSWORD
export PROJECT=$PROJECT
export HOME=/root

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

export DEPLOY_PLUGIN_FILE=apigee-edge-maven-plugin-2.0.2.jar

echo "*** Install Custom Apigee Hybrid Deploy Plugin ***"
curl -O https://storage.googleapis.com/apigee-sme-academy/${DEPLOY_PLUGIN_FILE}
export DEPLOY_PLUGIN_POM=$(jar tf ${DEPLOY_PLUGIN_FILE} | grep "pom.xml")
jar xf ${DEPLOY_PLUGIN_FILE} ${DEPLOY_PLUGIN_POM}
mvn -ntp org.apache.maven.plugins:maven-install-plugin:install-file  \
   -Dfile=./${DEPLOY_PLUGIN_FILE} \
   -DpomFile=${DEPLOY_PLUGIN_POM} \
   -Dpackaging=jar

echo "*** Setup lab private key ***"
echo '${LAB_PRIVATE_KEY}' > lab_private_key.pem
chmod 600 ~/lab_private_key.pem
export GIT_SSH_COMMAND="ssh -i ~/lab_private_key.pem"

ssh-keyscan github.com >> ~/.ssh/known_hosts

echo "*** Cloning Hybrid player ***"
git clone git@github.com:apigee-sme-academy-internal/qwiklabs-hybrid-player.git
export PATH=~/qwiklabs-hybrid-player/bin:$PATH

echo "*** Cloning lab content repo ***"
git clone "${LAB_REPO}"
export LAB_DIR="$(pwd)/$(basename "${LAB_REPO}" .git)"
cd ${LAB_DIR}
git checkout ${LAB_BRANCH}

echo "*** Setup env file ***"
cat << HEREDOC > ~/env
export ZONE=$ZONE
export REGION=$REGION
export QWIKLAB_USER=$QWIKLAB_USER
export QWIKLAB_PASSWORD=$QWIKLAB_PASSWORD
export PROJECT=$PROJECT
export HOME=$HOME
export LAB_DIR=$LAB_DIR
export GIT_SSH_COMMAND=$GIT_SSH_COMMAND
export PATH=$PATH
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