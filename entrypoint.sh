#!/bin/bash
set -e

: ${CLOUD=""} # One of aws, azure, do, gcp, or empty
if [ "$CLOUD" != "" ]; then
   PROVIDER="-provider ${CLOUD}"
fi

PRIVATE_IPV4=$(netdiscover -field privatev4 ${PROVIDER})
PUBLIC_IPV4=$(netdiscover -field publicv4 ${PROVIDER})
PROXY_IPV4=${PUBLIC_IPV4}


for filename in /etc/asterisk/*.conf; do
    CFG_PATH="${filename}"
    sed "s/PRIVATE_IPV4/${PRIVATE_IPV4}/g" $CFG_PATH > $CFG_PATH.cop
    sed "s/PUBLIC_IPV4/${PUBLIC_IPV4}/g" $CFG_PATH.cop > $CFG_PATH.cop2
    sed "s/PROXY_IPV4/${PROXY_IPV4}/g" $CFG_PATH.cop2 > $CFG_PATH.cop3
    sed "s/LINEBLOCS_KEY/${LINEBLOCS_KEY}/g" $CFG_PATH.cop3 > $CFG_PATH.cop4
    sed "s/ARI_PASSWORD/${ARI_PASSWORD}/g" $CFG_PATH.cop4 > $CFG_PATH.final
    rm -rf $CFG_PATH.cop*
    yes|mv  $CFG_PATH.final $CFG_PATH
done


# Default values
ASTERISK_ARGS="-fp"

# Run Asterisk
/usr/sbin/asterisk ${ASTERISK_ARGS}
