#!/usr/bin/env bash

source ~/env
setup_logger "install-bootstrap-tools"

cd ~

echo "*************************************"
echo "*** (BEGIN) Installing base tools ***"
echo "*************************************"
lab-bootstrap begin base-tools "Installing base tools" 30

apt-get install expect -y
snap install kubectl --classic
snap install jq

lab-bootstrap end bootstrap-tools
echo "***********************************"
echo "*** (END) Installing base tools ***"
echo "***********************************"