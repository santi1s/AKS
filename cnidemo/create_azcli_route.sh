#!/bin/bash

if [ $# -lt 2 ]; then
echo "Usage $0 <address-prefix> <next-hop>"
exit 1
fi

RAND=$(echo $(( $RANDOM % 100)))

az network route-table route create -g rg-azcli --route-table-name azcliRT \
-n route$RAND --next-hop-type VirtualAppliance --address-prefix $1 --next-hop-ip-address $2