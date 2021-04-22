#!/bin/bash

# Load Env Vars
source 0_envvars.sh


# delete cluster
echo -e "Deleting  Cluster $CLUSTERNAME in RG $RG..."
az aks delete -n $CLUSTERNAME -g $RG -y

# delete cluster subnet
echo -e "Deleting  subnet /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/$RG/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$NODE_SUBNET_NAME ...\n"
az network vnet subnet delete  -g $RG --vnet-name $VNET_NAME --name $NODE_SUBNET_NAME

echo -e "Done\n"

exit 0