#!/bin/bash
set -e
# Load Env Vars
source 0_envvars.sh

echo -e "Creating User assigned identity $AGIC_IDENTITY in ResourceGroup $RG...\n"
{ # try
    (az identity create -g $RG -n $AGIC_IDENTITY 1>/dev/null 2>/tmp/error.txt)
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

echo -e "Getting clientId and identiyId for $AGIC_IDENTITY ...\n"
{ # try
    IDENT_CLI_ID=$(az identity show -g $RG -n $AGIC_IDENTITY -o tsv --query "clientId" 2>/tmp/error.txt)
    echo -e "identityClientId:$IDENT_CLI_ID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

{ # try
    IDENT_ID=$(az identity show -g $RG -n $AGIC_IDENTITY -o tsv --query "id" 2>/tmp/error.txt)
    echo -e "identityId:$IDENT_ID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

echo -e "Getting Appgw related ResourceIds ...\n"
{ # try
    APPGW_ID=$(az network application-gateway show -g $RG -n $APPGW_NAME -o tsv --query "id" 2>/tmp/error.txt)
    APPGW_RGID=$(echo $APPGW_ID | awk -F "/providers/" '{print $1}' )
    echo -e "AppGw ResourceID:$APPGW_ID\n"
    echo -e "AppGw RG ResourceID:$APPGW_RGID\n"
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

echo -e "Assigning AGIC clientId "'"Contributor"'" role to Appgw and "'"Reader"'" role to Appgw RG ...\n"
{ # try
    (az role assignment create  --role "Contributor" --assignee $IDENT_CLI_ID --scope $APPGW_ID 2>/tmp/error.txt)
    (az role assignment create  --role "Reader" --assignee $IDENT_CLI_ID --scope $APPGW_RGID 2>/tmp/error.txt)
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

echo -e "Assigning kubelet clientId '"'Managed Identity Operator'"' role to AGIC identity ...\n"
{ # try
    KUBE_CLIID=$(az aks show -n $CLUSTERNAME -g $RG -o tsv --query identityProfile.kubeletidentity.clientId --only-show-errors 2>/tmp/error.txt)
    (az role assignment create  --role "Managed Identity Operator" --assignee $KUBE_CLIID --scope $IDENT_ID 2>/tmp/error.txt)
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}