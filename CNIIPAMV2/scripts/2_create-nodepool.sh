#!/bin/bash

# Load Env Vars
source 0_envvars.sh


# Create CNI vNext nodepool
echo "Create CNIv2 2nd nodepool"
az network vnet subnet create -g $RG --vnet-name $VNET_NAME_CNIV2 --name $POD_SUBNET2_NAME_CNIV2 --address-prefixes 10.2.248.0/22 -o none
az aks nodepool add -g $RG -n nodepool2 --cluster-name $CLUSTERNAME_CNIV2 --node-count 2 \
--pod-subnet-id /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_CNIV2/subnets/$POD_SUBNET2_NAME_CNIV2

