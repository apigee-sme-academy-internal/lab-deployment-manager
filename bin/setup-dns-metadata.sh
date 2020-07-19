#!/usr/bin/env bash
source ~/env

task_id="setup-dns-metadata"
setup_logger "${task_id}"
setup_error_handler "${task_id}"

cd ~

echo "**********************************"
echo "*** (BEGIN) Setup DNS Metadata ***"
echo "**********************************"

# FIXME: need to add lab duration
add_apigeelabs_dns_entry "TXT" "_created_at.${PROJECT}.apigeelabs.com"  "$(date +%s)"

echo "********************************"
echo "*** (END) Setup DNS Metadata ***"
echo "********************************"