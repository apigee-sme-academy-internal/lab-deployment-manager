#!/usr/bin/env bash
source ~/env

task_id="setup-base-tools"
begin_task "${task_id}" "Installing base tools" 30

cd ~

echo "*************************************"
echo "*** (BEGIN) Installing base tools ***"
echo "*************************************"

apt-get install expect -y
snap install kubectl --classic
snap install jq

end_task "${task_id}"
echo "***********************************"
echo "*** (END) Installing base tools ***"
echo "***********************************"