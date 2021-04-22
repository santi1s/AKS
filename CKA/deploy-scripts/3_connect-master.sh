#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Start VM
az vm start  -n $MASTER_NAME -g $RG

IF_ID=$(az vm show -n $MASTER_NAME -g $RG  -o json | jq -r '.networkProfile.networkInterfaces[].id')
PIP_ID=$(az network nic show --ids $IF_ID -o json | jq -r '.ipConfigurations[].publicIpAddress.id')
IP=$(az network public-ip show --ids $PIP_ID -o json | jq -r '.ipAddress')

ssh -i ~/.ssh/id_rsa azureuser@$IP
