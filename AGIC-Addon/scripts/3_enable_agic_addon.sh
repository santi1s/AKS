#!/bin/bash

# Load Env Vars
source 0_envvars.sh

echo "Enable AGIC Addon"
APPGW_ID=$(az network application-gateway show -n $APPGW_NAME -g $RG -o tsv --query "id") 
az aks enable-addons -n $CLUSTERNAME -g $RG -a ingress-appgw --appgw-id $APPGW_ID


