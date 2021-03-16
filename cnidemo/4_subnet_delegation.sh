#!/bin/bash

# Load Env Vars
source 0_envvars.sh


# Create CNI vNext 2nd Cluster 
az network vnet subnet create -g $RG --vnet-name $VNET_NAME_CNIV2 --name $NODE_SUBNET_NAME_CNIV2_2 --address-prefixes 10.1.252.0/22 -o none
az aks create -n $CLUSTERNAME_CNIV2_2 \
-g $RG \
--max-pods 250 \
--node-count 1 \
 --network-plugin azure \
 --generate-ssh-keys \
 --vnet-subnet-id  /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_CNIV2/subnets/$NODE_SUBNET_NAME_CNIV2_2\
 --pod-subnet-id /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_CNIV2/subnets/$POD_SUBNET_NAME_CNIV2
