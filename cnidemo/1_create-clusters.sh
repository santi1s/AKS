#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Create Resource Group
az group create -n $RG -l $LOC

# Create CNI
echo "Create CNI cluster"
az network vnet create -g $RG --name $VNET_NAME_CNI --address-prefixes 10.0.0.0/16 -o none
az network vnet subnet create -g $RG --vnet-name $VNET_NAME_CNI --name $SUBNET_NAME_CNI --address-prefixes 10.0.0.0/22 -o none
SUBNET_ID=$(az network vnet subnet list --resource-group $RG --vnet-name $VNET_NAME_CNI --query "[0].id" --output tsv)
az aks create \
    --resource-group $RG \
    --name $CLUSTERNAME_CNI \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --generate-ssh-keys \
    --node-count 1 \
    --managed-identity

# Create non-AAD Cluster
#echo "Create AAD Enabled Cluster"
