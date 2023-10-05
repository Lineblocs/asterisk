#!/bin/bash
set -e

: ${CLOUD=""} # One of aws, azure, do, gcp, or empty
if [ "$CLOUD" != "" ]; then
   PROVIDER="-provider ${CLOUD}"
fi

# NOTE: variables below which are exported are used in envsubst and probably not defined beforehand. If you wish to pass
# another one, TLS_ENABLED for example, and it has not been defined before in the docker run command, you need to export
# it to make it available in subcommands (ie. envsubst).

export PRIVATE_IPV4=$(netdiscover -field privatev4 ${PROVIDER})
export PUBLIC_IPV4=$(netdiscover -field publicv4 ${PROVIDER})
export PROXY_IPV4=${PUBLIC_IPV4}


for path in ./configs/*.conf; do
    CFG_PATH="${path}"
    cp $CFG_PATH $CFG_PATH.temp
    filename=$(basename "$path" ".conf")
    DEST_CFG_PATH="/etc/asterisk/${filename}.conf"
    echo $DEST_CFG_PATH
    envsubst '$PRIVATE_IPV4 $PUBLIC_IPV4 $PROXY_IPV4 $LINEBLOCS_KEY $ARI_PASSWORD $AMI_PASS' < $CFG_PATH.temp > $DEST_CFG_PATH
    rm -rf $CFG_PATH.temp
done