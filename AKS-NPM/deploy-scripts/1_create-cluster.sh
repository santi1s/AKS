#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Create Resource Group
az group create -n $RG -l $LOC


# Create cluster
echo -e "Create 1 Node CNI AKS Cluster with Azure Network Policy "
az network vnet create -g  $RG --name $VNET_NAME --address-prefixes 10.3.0.0/16 -o none
az network vnet subnet create -g $RG --vnet-name $VNET_NAME --name $NODE_SUBNET_NAME --address-prefixes 10.3.240.0/22 -o none
az aks create -n $CLUSTERNAME \
-g $RG \
--node-count 1 \
--network-plugin azure \
--network-policy azure \
--generate-ssh-keys \
-k 1.20.2 \
--vnet-subnet-id  /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$NODE_SUBNET_NAME


