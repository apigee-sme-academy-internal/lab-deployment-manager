#!/usr/bin/env bash

source ~/env
setup_logger "install-bootstrap-tools"

cd ~

echo "******************************************"
echo "*** (BEGIN) Installing bootstrap tools ***"
echo "******************************************"
lab-bootstrap begin bootstrap-tools "Installing bootstrap tools" 30

apt-get install expect -y
snap install kubectl --classic
snap install jq

lab-bootstrap end bootstrap-tools
echo "****************************************"
echo "*** (END) Installing bootstrap tools ***"
echo "****************************************"