#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Register PodSubnetPreview
az feature register --namespace "Microsoft.ContainerService" --name "PodSubnetPreview" --wait

# Create Resource Group
az group create -n $RG -l $LOC


# Create CNI vNext 
echo "Create CNI vNext Cluster"
az network vnet create -g  $RG --name $VNET_NAME_CNIV2 --address-prefixes 10.1.0.0/16 -o none
az network vnet subnet create -g $RG --vnet-name $VNET_NAME_CNIV2 --name $NODE_SUBNET_NAME_CNIV2 --address-prefixes 10.1.240.0/22 -o none
az network vnet subnet create -g $RG --vnet-name $VNET_NAME_CNIV2 --name $POD_SUBNET_NAME_CNIV2 --address-prefixes 10.1.244.0/22 -o none
az aks create -n $CLUSTERNAME_CNIV2 \
-g $RG \
--max-pods 250 \
--node-count 2 \
 --network-plugin azure \
 --generate-ssh-keys \
 --vnet-subnet-id  /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_CNIV2/subnets/$NODE_SUBNET_NAME_CNIV2 \
 --pod-subnet-id /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_CNIV2/subnets/$POD_SUBNET_NAME_CNIV2

# Create CNI
echo "Create CNI cluster"
az network vnet create -g $RG --name $VNET_NAME_CNI --address-prefixes 10.0.0.0/16 -o none
az network vnet subnet create -g $RG --vnet-name $VNET_NAME_CNI --name $SUBNET_NAME_CNI --address-prefixes 10.0.0.0/22 -o none
az aks create \
    --resource-group $RG \
    --name $CLUSTERNAME_CNI \
    --network-plugin azure \
    --vnet-subnet-id /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_CNI/subnets/$SUBNET_NAME_CNI \
    --generate-ssh-keys \
    --service-cidr 10.0.4.0/22 \
    --dns-service-ip 10.0.4.10 \
    --node-count 2