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



if [ 0 -eq 1 ];then

 az network application-gateway show -g AGICIngress -n aksagicingress-AppGw -o tsv --query id
identityClientId:cf3c8a86-653f-4dce-bb4a-e08dbc43946c

identityId:/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourcegroups/AGICIngress/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aksagicingress-identity
az role assignment create \
    --role "Contributor" \
    --assignee cf3c8a86-653f-4dce-bb4a-e08dbc43946c \
    --scope /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICIngress/providers/Microsoft.Network/applicationGateways/aksagicingress-AppGw

az role assignment create \
    --role "Reader" \
    --assignee cf3c8a86-653f-4dce-bb4a-e08dbc43946c \
    --scope /subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICIngress
#switch to cluster ctx
{ # try
    (kubectl config use-context $CLUSTERNAME >/dev/null 2>&1) && (echo -e "Switched to context:$CLUSTERNAME\n")
} || { # catch
    echo -e "Error getting context $CLUSTERNAME\n"
    exit 1
}

helm install ingress-azure \
  --namespace kube-system \
  -f helm-config.yaml \
  application-gateway-kubernetes-ingress/ingress-azure \
  --version 1.4.0
sed  's/\(subscriptionId: \)[a-z0-9-]*$/\1gggg/' helm-config.yaml

{ # try
    (echo -e "Installing aad-pod-identity using helm\n") && (helm > /dev/null 2>&1) &&  (version=$(helm version | awk -F"Version:" '{print $2}' | awk -F "," '{print $1}'))
} || { # catch
    echo -e "helm not found\n"
    exit 1
}

{ # try
    helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts > /dev/null 2>/tmp/error.txt
} || { # catch
    echo -e "failed to add helm chart for aad-pod-identity to repo :\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
{ # try
    helm install aad-pod-identity aad-pod-identity/aad-pod-identity --namespace=kube-system > /dev/null 2>/tmp/error.txt
} || { # catch
    echo -e "failed to install aad-pod-identity in namespace kube-system:\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    #exit 1
}

echo -e "aad-pod-identity installed. Checking status...\n"

{ # try
    (echo -e "Checking mic pod status in namespace kube-system:\n") && kubectl --namespace=kube-system get pods -l "app.kubernetes.io/component=mic" 2>/tmp/error.txt
} || { # catch
    echo -e "failed to get mic pod status in  namespace kube-system:\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

{ # try
    (echo -e "Checking nmi pod status in namespace kube-system:\n") && kubectl --namespace=kube-system get pods -l "app.kubernetes.io/component=nmi" 2>/tmp/error.txt
} || { # catch
    echo -e "failed to get mic pod status in  namespace kube-system:\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
fi
