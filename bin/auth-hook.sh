#!/bin/bash
exec 1> >(logger -t $(basename $0))
exec 2> >(logger -s -t $(basename $0))


source ~/env

export CHALLENGE_PREFIX="_acme-challenge"

add_apigeelabs_dns_entry "TXT" "${CHALLENGE_PREFIX}.${CERTBOT_DOMAIN}"  "${CERTBOT_VALIDATION}"
wait_for_apigeelabs_dns_record "TXT" "${CHALLENGE_PREFIX}.${CERTBOT_DOMAIN}" "${AUTHORITATIVE_NAMESERVER}"
sleep 15; # sleep extra time for good measure ...
