#!/bin/bash
set -e
# Load Env Vars
source 0_envvars.sh

echo -e "Setup aad-pod-identity...\n"
#switch to cluster ctx
{ # try
    (kubectl config use-context $CLUSTERNAME >/dev/null 2>&1) && (echo -e "Switched to context:$CLUSTERNAME\n")
} || { # catch
    echo -e "Error getting context $CLUSTERNAME\n"
    exit 1
}

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



if [ 1 -eq 0 ]; then

kubectl --namespace=kube-system get pods -l "app.kubernetes.io/component=mic"
  kubectl --namespace=kube-system get pods -l "app.kubernetes.io/component=nmi"
echo -e "Installing aad-pod-identity via helm...\n"
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm install aad-pod-identity aad-pod-identity/aad-pod-identity --namespace=kube-system
fi