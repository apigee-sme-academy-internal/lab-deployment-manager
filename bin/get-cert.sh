#!/usr/bin/env bash

source ~/env
setup_logger "get-cert"

echo "***********************************"
echo "*** (BEGIN) Getting certificate ***"
echo "***********************************"
lab-bootstrap begin lab-certs "Creating certificates" 180

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

if [[ "${USE_REAL_CERT}" == "true" ]] || [[ "${USE_REAL_CERT}" == "yes" ]] ; then
  TEST_CERT_FLAG="";
  echo "*** Requesting real certificate with cert-bot ***"
else
  TEST_CERT_FLAG="--test-cert"
  echo "*** Requesting fake certificate with cert-bot***"
  echo ""
  echo "*** Run these commands in MacOS to trust the LE FakeRoot ***"
  echo "  curl -O -s https://letsencrypt.org/certs/fakelerootx1.pem"
  echo "  sudo security add-trusted-cert -d -r trustRoot -k '/Library/Keychains/System.keychain' ./fakelerootx1.pem"
  echo ""
  echo "*** Run these commands in Ubuntu/Debian to trust the LE FakeRoot ***"
  echo "  curl -O -s https://letsencrypt.org/certs/fakelerootx1.pem"
  echo "  sudo cp fakelerootx1.pem /usr/local/share/ca-certificates/fakelerootx1.crt"
  echo "  sudo update-ca-certificates"
  echo ""
  echo " See full instructions at: https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html"
  echo ""
fi

yes | certbot-auto certonly \
  --manual \
  --non-interactive \
  $TEST_CERT_FLAG \
  --preferred-challenges dns-01 \
  --manual-auth-hook $(which auth-hook.sh) \
  --agree-tos \
  --manual-public-ip-logging-ok \
  --email "$QWIKLABS_USERNAME@qwiklabs.net" \
  -d "*.${PROJECT_HOST_ALIAS}"
deactivate

cat << EOF >> ~/certs.env

export PROJECT_HOST_ALIAS="${PROJECT}.apigeelabs.com"
export RUNTIME_HOST_ALIAS="api.${PROJECT_HOST_ALIAS}"
export MART_HOST_ALIAS="mart.${PROJECT_HOST_ALIAS}"
export DEV_PORTAL_HOST_ALIAS="developer.${PROJECT_HOST_ALIAS}"
export OAS_EDITOR_HOST_ALIAS="spec-editor.${PROJECT_HOST_ALIAS}"
export REST_SERVICE_HOST_ALIAS="rest.${PROJECT_HOST_ALIAS}"
export SOAP_SERVICE_HOST_ALIAS="soap.${PROJECT_HOST_ALIAS}"
export IDP_SERVICE_HOST_ALIAS="idp.${PROJECT_HOST_ALIAS}"

export RUNTIME_SSL_KEY="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/privkey.pem"
export RUNTIME_SSL_CERT="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/fullchain.pem"

export DEV_PORTAL_SSL_KEY="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/privkey.pem"
export DEV_PORTAL_SSL_CERT="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/cert.pem"
export DEV_PORTAL_SSL_CHAIN="/etc/letsencrypt/live/${PROJECT_HOST_ALIAS}/fullchain.pem"

EOF

if [[ ! -z "${TEST_CERT_FLAG}" ]] ; then
  echo "**********************************"
  echo "*** Installing LE Fakeroot CA  ***"
  echo "**********************************"
  curl -O -s https://letsencrypt.org/certs/fakelerootx1.pem
  sudo cp fakelerootx1.pem /usr/local/share/ca-certificates/fakelerootx1.crt
  sudo update-ca-certificates
fi

echo "source ~/certs.env" >> ~/env

lab-bootstrap end lab-certs

echo "*********************************"
echo "*** (END) Getting certificate ***"
echo "*********************************"

