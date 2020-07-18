#!/usr/bin/env bash

source ~/env
setup_logger "setup-bootstrap-tool"

cd ~

echo "*********************************************"
echo "*** (BEGIN) Setting up lab-bootstrap tool ***"
echo "*********************************************"

curl -sSOL "https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/${DM_BRANCH}/dist/linux/lab-bootstrap"
curl -sSOL "https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/${DM_BRANCH}/dist/linux/gotty"
curl -sSOL "https://github.com/apigee-sme-academy-internal/lab-task-tracker/raw/${DM_BRANCH}/dist/linux/.gotty"
mv ./lab-bootstrap /usr/bin/
mv ./gotty /usr/bin
chmod a+rx /usr/bin/{gotty,lab-bootstrap}

export VM_EXTERNAL_IP=$(gcloud compute instances describe lab-startup --zone ${ZONE} --format='value(networkInterfaces.accessConfigs[0].natIP)')
gcloud compute instances add-tags lab-startup --tags=lab-startup --zone=${ZONE}
gcloud compute firewall-rules create "lab-startup" \
      --direction=INGRESS \
      --allow=tcp:80 \
      --source-ranges="0.0.0.0/0" \
      --description="lab-startup" \
      --target-tags=lab-startup

add_apigeelabs_dns_entry "A" "startup.${PROJECT}.apigeelabs.com" "${VM_EXTERNAL_IP}"
apt-get install -y supervisor
echo '
[program:apache2]
environment=HOME=/root,TERM=xterm-256color
command=gotty --port=80 lab-bootstrap monitor
autorestart=true' > /etc/supervisor/conf.d/gotty.conf
systemctl restart supervisor

echo "*******************************************"
echo "*** (END) Setting up lab-bootstrap tool ***"
echo "*******************************************"