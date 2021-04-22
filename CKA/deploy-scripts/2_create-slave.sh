#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Create Resource Group
az group create -n $RG -l $LOC


# Create cluster
echo -e "Create k8s slave node"

az vm create \
  --resource-group $RG \
  --name $SLAVE_NAME \
  --image Canonical:UbuntuServer:18.04-LTS:18.04.202101191 \
  --admin-username azureuser \
  --size Standard_D2s_v3 \
  --storage-sku StandardSSD_LRS \
  --data-disk-sizes-gb 128 \
  --nsg-rule SSH \
  --vnet-name $VNET_NAME \
  --subnet $NODE_SUBNET_NAME \
  --generate-ssh-keys
