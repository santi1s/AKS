#!/bin/bash

## Prerequisites
#check bash version
version=$(bash --version | grep "^GNU bash" | awk '{print $4}' | awk -F "." '{print $1}')
if [ $version -lt 4 ]; then
    echo -e "This script requires bash version > 4\n"
    exit 1
fi
#check jq
{ # try
    jq --version > /dev/null 2>&1
} || { # catch
    echo -e "This script requires jq to be installed\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

b=$(tput bold)
n=$(tput sgr0)

EPS=$(cat /var/run/azure-vnet.json | jq '.Network.ExternalInterfaces.eth0.Networks.azure.Endpoints | keys' | jq -r '.|@tsv')

printf "\t${b}%-15s %-15s %-20s %-40s %-40s${n}\n" "Endpoint" "Host IF" "IP" "Namespace" "Pod";

for EP in $EPS;  do
        EPJ=$(cat /var/run/azure-vnet.json | jq ".Network.ExternalInterfaces.eth0.Networks.azure.Endpoints.\"${EP}\"")
        IFNAME=$(echo $EPJ | jq -r '.IfName')
        IP=$(echo $EPJ | jq -r '.IPAddresses[].IP' )
        POD=$(echo $EPJ | jq -r '.PODName' )
        NS=$(echo $EPJ | jq -r '.PODNameSpace' )
        printf "\t%-15s %-15s %-20s %-40s %-40s\n" "$EP" "$HIFNAME" "$IP" "$NS" "$POD";
done

