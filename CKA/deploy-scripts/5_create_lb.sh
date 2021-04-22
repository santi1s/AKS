#!/bin/bash

# Load Env Vars
source 0_envvars.sh

# Create PIP for the LB
#az network public-ip create --resource-group $RG --name cka_pip --sku Standard  --zone 1

# create user assigne identity
IDENT=$(az identity create -g $RG -n cka_identity -o json | jq -r '.id')
IDENT_SP=$(az identity show --id $IDENT -o json | jq -r '.principalId')
# assign identity to cka VMs
az vm identity assign -g $RG -n $MASTER_NAME --identities "$IDENT"
az vm identity assign -g $RG -n $SLAVE_NAME --identities "$IDENT"

RG_ID=$(az group show -g cka -o json | jq -r '.id')

az role assignment create --assignee $IDENT_SP --role 'Contributor' --scope "$RG_ID"
