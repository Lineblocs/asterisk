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


for filename in /etc/asterisk/*.conf; do
    CFG_PATH="${filename}"
    cp $CFG_PATH $CFG_PATH.temp
    envsubst '$PRIVATE_IPV4 $PUBLIC_IPV4 $PROXY_IPV4 $LINEBLOCS_KEY $ARI_PASSWORD $AMI_PASS' < $CFG_PATH.temp > $CFG_PATH
    rm -rf $CFG_PATH.temp
done


# Default values
ASTERISK_ARGS="-fp"

# Run Asterisk
/usr/sbin/asterisk ${ASTERISK_ARGS}
