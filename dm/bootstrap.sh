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

EOF
# Second section, the rest of the startup (variable expansion is not active)
cat << 'EOF' >> ./startup.sh
cd ~
echo "Installing GCP Logging Agent"
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update -y
apt-get install -y google-fluentd google-fluentd-catch-all-config-structured
service google-fluentd start

echo "Installing kubectl, gcloud"
snap install kubectl --classic
snap install google-cloud-sdk
snap install jq
snap install git-ubuntu --classic
export PATH=/snap/bin:$PATH

echo '${LAB_PRIVATE_KEY}' > lab_private_key.pem
chmod 600 ~/lab_private_key.pem

eval "$(ssh-agent -s)"
ssh-add ~/lab_private_key.pem
ssh-keyscan github.com >> ~/.ssh/known_hosts

echo "Cloning lab content repo"
git clone "${LAB_REPO}"
cd $(basename "${LAB_REPO}" .git)
git checkout ${LAB_BRANCH}

./startup.sh

EOF

#Create VM to bootstrap the lab
gcloud compute instances create startup \
    --machine-type=n1-standard-2 \
    --subnet=default \
    --zone $ZONE \
    --service-account=$SERVICE_ACCOUNT \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --image-family=ubuntu-1804-lts \
    --image-project=ubuntu-os-cloud \
    --metadata-from-file startup-script=./startup.sh