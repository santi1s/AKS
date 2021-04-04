#!/bin/bash
#set -x

export RG=AGICdemo
export LOC=CanadaCentral
#AKS
export CLUSTERNAME=aks-agic
export VNET_NAME=aks-agic-vnet
export NODE_SUBNET_NAME=aks-agic-nodesubnet
#AppGw
export APPGW_PIP_NAME=aks-AppGw-PublicIP
export APPGW_SUBNET_NAME=aks-AppGw-subnet
export APPGW_NAME=aks-AppGw

# Load Env Vars
source 0_envvars.sh

#check bash version
version=$(bash --version | grep "^GNU bash" | awk '{print $4}' | awk -F "." '{print $1}')

if [ $version -lt 4 ]; then
    echo -e "This script requires bash version > 4\n"
    exit 1
fi

#switch to cluster ctx
kubectl ctx $CLUSTERNAME >> /dev/null 2>&1
if [ $? -gt 0 ]; then
    echo -e "Error getting context $CLUSTERNAME\n"
    exit 1
fi

# get agic cm 
AGIC_CM=$(kubectl get cm -n kube-system | grep ingress-appgw | awk '{print $1}')
if [ -z  $AGIC_CM ]; then
    echo -e "Error getting AGIC configmap in kube-systen namespace\n"
    exit 1
fi

AGIC_CM_DATA=$(kubectl get cm $AGIC_CM -n kube-system -o wide | awk 'NR>1 {print $2}')
mapfile -t AGIC_CM_DATA_KEYS< <(kubectl get  cm ingress-appgw-cm -n kube-system -oyaml | grep -A 7 "^data\:" | grep -v "^data\:" | awk -F ": " '{print $1}' | sed 's/^ *//g')

declare -A AGIC_CFG_ARRAY

echo -e "\nAGIC configuration from $AGIC_CM configmap:\n"
for  i in "${!AGIC_CM_DATA_KEYS[@]}"; do
     KUBE_CMD=$(echo "kubectl get cm ingress-appgw-cm -n kube-system -o jsonpath='{.data."${AGIC_CM_DATA_KEYS[i]}"}'")
     AGIC_CFG_ARRAY[${AGIC_CM_DATA_KEYS[i]}]=$($KUBE_CMD | awk -F"'" '{print $2}' | awk -F"'" '{print $1}')
done 
for key in "${!AGIC_CFG_ARRAY[@]}"; do echo -e "$key => ${AGIC_CFG_ARRAY[$key]}\n"; done

use_msi_for_pod=${AGIC_CFG_ARRAY[USE_MANAGED_IDENTITY_FOR_POD]}
if [ -n $use_msi_for_pod ]  &&  [ $use_msi_for_pod == "true" ]; then
    echo -e "USE_MANAGED_IDENTITY_FOR_POD set to true, gettting sp detail for appId:${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]}\n"
    echo -e "ServicePrincipal details:\n"
    echo -e "accountEnabled: $(az ad sp show --id ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} -o tsv --query accountEnabled)\n"
    echo -e "displayName: $(az ad sp show --id ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} -o tsv --query displayName)\n"
    echo -e "servicePrincipalType: $(az ad sp show --id ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} -o tsv --query servicePrincipalType)\n"
    echo -e "keyCredentials.endDate: $(az ad sp show --id ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} -o tsv --query keyCredentials[0].endDate)\n"
    echo -e "Resource ID: $(az ad sp show --id ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} -o tsv --query alternativeNames[1])\n"
    echo -e "objectId: $(az ad sp show --id ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} -o tsv --query objectId)\n"
    echo -e "role assignments on ${AGIC_CFG_ARRAY[APPGW_RESOURCE_ID]} :\n"
    echo -e "role: $(az role assignment list --assignee ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} --scope ${AGIC_CFG_ARRAY[APPGW_RESOURCE_ID]} --include-inherited --query [].roleDefinitionName | grep -v "^\[" | grep -v "^\]")\n"
    APP_GW_RG_RES_ID=$(echo ${AGIC_CFG_ARRAY[APPGW_RESOURCE_ID]} | awk -F "/providers" '{print $1}')
    echo -e "role assignments on $APP_GW_RG_RES_ID:\n"
    echo -e "role: $(az role assignment list --assignee ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} --scope $APP_GW_RG_RES_ID --query [].roleDefinitionName | grep -v "^\[" | grep -v "^\]")\n"
   
fi

