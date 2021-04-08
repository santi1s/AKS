#!/bin/bash
set -x
# Load Env Vars
source 0_envvars.sh

#switch to cluster ctx
{ # try
    (kubectl config use-context $CLUSTERNAME >/dev/null 2>&1) && (echo -e "Switched to context:$CLUSTERNAME\n")
} || { # catch
    echo -e "Error getting context $CLUSTERNAME\n"
    exit 1
}


{ # try
    (echo -e "Installing  application-gateway-kubernetes-ingress using helm\n") && (helm > /dev/null 2>&1) &&  (version=$(helm version | awk -F"Version:" '{print $2}' | awk -F "," '{print $1}'))
} || { # catch
    echo -e "helm not found\n"
    exit 1
}

{ # try
    (echo -e "Adding helm chart for application-gateway-kubernetes-ingress to repo..\n") && helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/ > /dev/null 2>/tmp/error.txt
    (echo -e "Running hem repo update...\n") && helm  repo update
} || { # catch
    echo -e "failed to add helm chart for application-gateway-kubernetes-ingress to repo :\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

echo -e "Downloading and configuring AGIC helm-config.yaml..."
{ # try
    wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml -O helm-config.yaml 1>/dev/null 2>/tmp/error.txt
    SUBID=$(az account show -o tsv --query id 2>/tmp/error.txt)
    IDENT_CLI_ID=$(az identity show -g $RG -n $AGIC_IDENTITY -o tsv --query "clientId" 2>/tmp/error.txt)
    IDENT_ID=$(az identity show -g $RG -n $AGIC_IDENTITY -o tsv --query "id" 2>/tmp/error.txt)
    sed -i -e "s/\(^verbosityLevel: \)[0-9]$/\15/" -e "s/<subscriptionId>/${SUBID}/" -e "s/<resourceGroupName>/${RG}/" \
    -e "s/<applicationGatewayName>/${APPGW_NAME}/" -e "s|<identityResourceId>|${IDENT_ID}|" -e "s/<identityClientId>/${IDENT_CLI_ID}/" helm-config.yaml
} || { # catch
    echo -e "Failed to download and configure AGIC helm-config.yaml :\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

if [ 1 -eq 0 ]; then
echo -e "Installing Helm chart application-gateway-kubernetes-ingress in kube-system namespace..."
{ # try
    helm install ingress-azure \
    --namespace default \
    -f helm-config.yaml \
    application-gateway-kubernetes-ingress/ingress-azure \
    --version 1.4.0
} || { # catch
    echo -e "Failed to install AGIC helm chart :\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
fi 
