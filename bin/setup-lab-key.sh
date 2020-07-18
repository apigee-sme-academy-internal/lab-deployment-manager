#!/usr/bin/env bash

source ~/env
setup_logger "setup-lab-key"

cd ~


echo "******************************************"
echo "*** (BEGIN) Setting up lab private key ***"
echo "******************************************"

echo '${LAB_PRIVATE_KEY}' > lab-privkey.pem
chmod 600 ~/lab-privkey.pem
export GIT_SSH_COMMAND="ssh -i ~/lab-privkey.pem"
ssh-keyscan github.com >> ~/.ssh/known_hosts


echo "****************************************"
echo "*** (END) Setting up lab private key ***"
echo "****************************************"
