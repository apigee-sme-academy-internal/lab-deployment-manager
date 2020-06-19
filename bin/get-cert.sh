#!/usr/bin/env bash

source ~/env
setup_logger "get-cert"

echo "***********************************"
echo "*** (BEGIN) Getting certificate ***"
echo "***********************************"

echo "Installing certbot-auto ..."
wget https://dl.eff.org/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto

echo "Setting up certbot-auto"
certbot-auto --install-only -n

echo "Checking certbot version ..."
certbot-auto --version

echo "Activating python3 virtual environment ... "
source /opt/eff.org/certbot/venv/bin/activate

echo "Requesting new certificate ..."

export PROJECT_HOST_ALIAS="${PROJECT}.apigeelabs.com"

yes | certbot-auto certonly \
  --manual \
  --test-cert \
  --preferred-challenges dns-01 \
  --manual-auth-hook $(which auth-hook.sh) \
  --agree-tos \
  --email "$QWIKLAB_USER@qwiklabs.net" \
  -d "*.${PROJECT_HOST_ALIAS}"
deactivate

cat << EOF >> ~/certs.env

export PROJECT_HOST_ALIAS="${PROJECT}.apigeelabs.com"
export RUNTIME_HOST_ALIAS="api.${PROJECT_HOST_ALIAS}"
export MART_HOST_ALIAS="mart.${PROJECT_HOST_ALIAS}"
export DEV_PORTAL_HOST_ALIAS="developer.${PROJECT_HOST_ALIAS}"
export REST_SERVICE_HOST_ALIAS="rest.${PROJECT_HOST_ALIAS}"
export SOAP_SERVICE_HOST_ALIAS="soap.${PROJECT_HOST_ALIAS}"
export IDP_SERVICE_HOST_ALIAS="idp.${PROJECT_HOST_ALIAS}"

export RUNTIME_SSL_KEY="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/privkey.pem"
export RUNTIME_SSL_CERT="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/fullchain.pem"
EOF

echo "source ~/certs.env" >> ~/env

echo "*********************************"
echo "*** (END) Getting certificate ***"
echo "*********************************"

