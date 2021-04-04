#!/bin/bash
#set -x

# 
# Bash script to check the configuration of cluster with AGIC Addon Enabled
# Requires bash 4 and jq 
#

## Prerequisites
#check bash version
version=$(bash --version | grep "^GNU bash" | awk '{print $4}' | awk -F "." '{print $1}')
if [ $version -lt 4 ]; then
    echo -e "This script requires bash version > 4\n"
    exit 1
fi
#check jq
{ # try
    jq --version > /dev/null 2>&1
} || { # catch
    echo -e "This script requires jq to be installed\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

#usage
usage() { echo -e  "Usage: $0 -n <cluster-name> -g <cluster-resourcegroup> [-s <subscriptionId> ]\n" 1>&2; exit 1; }

#get options
while getopts ":n:g:s:" option; do
    case "${option}" in
        n)
            CLUSTERNAME=${OPTARG}
            ;;
        g)
            RG=${OPTARG}
            ;;
        s)
            SUBID=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "${CLUSTERNAME}" ] || [ -z "${RG}" ] ; then
    usage
    exit 1
fi

if [ -n  "${SUBID}" ] ;then
{ # try
    az account set -s $SUBID > /dev/null 2>/tmp/error.txt
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
fi

AZ_AKS="az aks show --only-show-errors"
#check if AGIC Addon is enabled
{ # try
    AGIC_ENABLED=$($AZ_AKS -g $RG -n $CLUSTERNAME -o json | jq '.addonProfiles.ingressApplicationGateway.enabled' 2>/tmp/error.txt)
    if [ ${AGIC_ENABLED} != "true" ]; then 
        echo -e "\nAGIC addon not enabled in cluster $CLUSTERNAME \n"
        exit 1
    fi
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

echo -e "\nAGIC addon enabled in cluster.\nAddon Cluster Configuration:\n"

#
# get addon cluster configuration
#
{ # try
    CFGAPPGWRESID=$($AZ_AKS -g $RG -n $CLUSTERNAME -o json | jq '.addonProfiles.ingressApplicationGateway.config.effectiveApplicationGatewayId' | sed -e 's/^"//' -e 's/"$//'  2>/tmp/error.txt)
    echo -e "effectiveApplicationGatewayId:$CFGAPPGWRESID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
{ # try
    CFGARMCLI_ID=$($AZ_AKS -g $RG -n $CLUSTERNAME -o json | jq '.addonProfiles.ingressApplicationGateway.identity.clientId'| sed -e 's/^"//' -e 's/"$//'  2>/tmp/error.txt)
    echo -e "Identity clientId:$CFGARMCLI_ID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
{ # try
    CFGARMOB_ID=$($AZ_AKS -g $RG -n $CLUSTERNAME -o json | jq '.addonProfiles.ingressApplicationGateway.identity.objectId' | sed -e 's/^"//' -e 's/"$//' 2>/tmp/error.txt)
    echo -e "Identity objectId:$CFGARMOB_ID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
{ # try
    CFGARMRES_ID=$($AZ_AKS -g $RG -n $CLUSTERNAME -o json | jq '.addonProfiles.ingressApplicationGateway.identity.resourceId' | sed -e 's/^"//' -e 's/"$//' 2>/tmp/error.txt)
    echo -e "Identity resourceId:$CFGARMRES_ID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

#
# get addon k8s configmap configuration
#
#switch to cluster ctx
{ # try
    az aks get-credentials -n $CLUSTERNAME -g $RG > /dev/null 2>/tmp/error.txt
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

# get ingress-appgw pod configma 
AGIC_CM=$(kubectl get cm -n kube-system | grep ingress-appgw | awk '{print $1}')
if [ -z  $AGIC_CM ]; then
    echo -e "Error getting AGIC configmap in kube-systen namespace\n"
    exit 1
fi

AGIC_CM_DATA=$(kubectl get cm $AGIC_CM -n kube-system -o wide | awk 'NR>1 {print $2}')
mapfile -t AGIC_CM_DATA_KEYS< <(kubectl get  cm ingress-appgw-cm -n kube-system -oyaml | grep -A 7 "^data\:" | grep -v "^data\:" | awk -F ": " '{print $1}' | sed 's/^ *//g')

declare -A AGIC_CFG_ARRAY

echo -e "\nGetting AGIC configuration from $AGIC_CM configmap:\n"
for  i in "${!AGIC_CM_DATA_KEYS[@]}"; do
     KUBE_CMD=$(echo "kubectl get cm ingress-appgw-cm -n kube-system -o jsonpath='{.data."${AGIC_CM_DATA_KEYS[i]}"}'")
     AGIC_CFG_ARRAY[${AGIC_CM_DATA_KEYS[i]}]=$($KUBE_CMD | awk -F"'" '{print $2}' | awk -F"'" '{print $1}')
done 
for key in "${!AGIC_CFG_ARRAY[@]}"; do
     echo -e "$key:${AGIC_CFG_ARRAY[$key]}\n";
done

echo -e "\nChecking values in configmap ingress-appgw-cm against values in cluster config:\n"
if [ ${AGIC_CFG_ARRAY[APPGW_RESOURCE_ID]} != $CFGAPPGWRESID ]; then
    echo -e "There is a mismatch betweem AppGwResourceId!!\n"
fi
if [ ${AGIC_CFG_ARRAY[AZURE_CLIENT_ID]} != $CFGARMCLI_ID ]; then
    echo -e "There is a mismatch betweem appId !!\n"
fi


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

