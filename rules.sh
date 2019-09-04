#!/bin/bash

if [ $EUID != 0 ]; then
    echo "Requiring root privilege.";
    exit 1
fi
if [ ! $1 ] || [ ! $2 ]; then
    echo "Usage: ./rules.sh [enable|disable] [ss-config-file]";
    exit 1
fi
if [ ! -f $2 ]; then
    echo "Missing SS config file.";
    exit 1
fi

WORKING_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" > /dev/null 2>&1 && pwd -P )"
cd $WORKING_DIR;

python3 resolve_ss_config.py $2 server > /dev/null 2>&1;
if [ $? != 0 ]; then
    echo "Invalid SS config file.";
    exit 1
fi

SERVER=$(python3 resolve_ss_config.py $2 server)
LOCAL_PORT=$(python3 resolve_ss_config.py $2 local_port)

CHAIN_NAME="SHADOWSOCKS"
IPSET_NAME="CHINAIP"

rules_purge () {
    # Purge rules
    iptables -t nat -D OUTPUT -p tcp -j $CHAIN_NAME > /dev/null 2>&1;
    iptables -t nat -F $CHAIN_NAME > /dev/null 2>&1;
    if [ $? = 0 ]; then
        iptables -t nat -X $CHAIN_NAME > /dev/null 2>&1;
    fi
    ipset destroy $IPSET_NAME > /dev/null 2>&1
    if [ $? = 127 ]; then
        echo "ipset command not found.";
        exit 1
    fi
}

case $1 in
    enable)
        rules_purge;

        # Setup rules
        ipset create $IPSET_NAME hash:net;

        cat lan_ip_list.txt china_ip_list.txt | \
        while IFS= read line || [ -n "$line" ]; do
            if [ ! -z $line ]; then
                ipset add $IPSET_NAME $line;
            fi
        done

        iptables -t nat -N $CHAIN_NAME;
        iptables -t nat -A $CHAIN_NAME -d $SERVER -j RETURN;
        iptables -t nat -A $CHAIN_NAME -p tcp -m set --match-set $IPSET_NAME dst -j RETURN;
        iptables -t nat -A $CHAIN_NAME -p tcp -j REDIRECT --to-port $LOCAL_PORT;

        iptables -t nat -A OUTPUT -p tcp -j $CHAIN_NAME;
        ;;
    disable)
        rules_purge;
        ;;
    *)
        echo "Usage: ./rules.sh [enable|disable] [ss-config-file]";
        ;;
esac
