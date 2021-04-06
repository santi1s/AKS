#!/bin/bash

# Load Env Vars
source 0_envvars.sh


# Create AppGw
echo "Create PIP for AppGw"
az network public-ip create -n $APPGW_PIP_NAME -g $RG --allocation-method Static --sku Standard
echo "Create AppGw Subnet"
az network vnet subnet create -g $RG --vnet-name $VNET_NAME --name $APPGW_SUBNET_NAME --address-prefixes 10.2.248.0/24
echo "Create AppGw"
az network application-gateway create -n $APPGW_NAME -l $LOC -g $RG --sku Standard_v2 --public-ip-address $APPGW_PIP_NAME --vnet-name $VNET_NAME --subnet $APPGW_SUBNET_NAME


