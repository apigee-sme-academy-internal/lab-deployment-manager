#!/usr/bin/env bash
set -e

cd ~
source ~/env
setup_logger "setup-dns-metadata"

echo "**********************************"
echo "*** (BEGIN) Setup DNS Metadata ***"
echo "**********************************"

# FIXME: need to add lab duration
add_apigeelabs_dns_entry "TXT" "_created_at.${PROJECT}.apigeelabs.com"  "$(date +%s)"

echo "********************************"
echo "*** (END) Setup DNS Metadata ***"
echo "********************************"