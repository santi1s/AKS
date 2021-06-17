#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Create Resource Group
az group create -n $RG -l $LOC
az network vnet subnet show --name aks-agicingress-nodesubnet --resource-group AGICIngress --vnet-name aks-agicingress-vnet -o tsv --query id

# Create cluster
echo -e "Create 1 Node CNI Cluster"
az network vnet create -g  $RG --name $VNET_NAME --address-prefixes 10.3.0.0/16 -o none
az network vnet subnet create -g $RG --vnet-name $VNET_NAME --name $NODE_SUBNET_NAME --address-prefixes 10.3.240.0/22 -o none
SNET_ID=$(az network vnet subnet show --name $NODE_SUBNET_NAME --resource-group $RG --vnet-name $VNET_NAME -o tsv --query id)
az aks create -n $CLUSTERNAME \
-g $RG \
--node-count 1 \
--network-plugin azure \
--generate-ssh-keys \
--vnet-subnet-id $SNET_ID

