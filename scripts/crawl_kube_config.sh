#!/bin/bash
#set -x
set -e
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


# populate skip cluster array 
declare -A SKIP_CLUSTERS
if [ -n $SKIP_AKS_CLUSTERS ]; then
    SKIP_AKS_CLUSTERS_INT=$(echo $SKIP_AKS_CLUSTERS | tr -s ':' ' ')
    for i in $SKIP_AKS_CLUSTERS_INT; do
        SKIP_CLUSTERS[$i]=dummy
    done
fi 

#usage
usage()
{
cat << EOF  
Usage: $0 [-h|--help] [-n <cluster>] [-f kube-config] | [--all]
Get kube config entrie(s)

-h,--help   Print usage

-n,         Cluster Name

-f,         kube config file - defaults to ~/.kube/config

--all,      get info for all clusters


EOF
} 

unset NAME;unset RG;unset ALL; unset ACTION
KUBE_CONFIG="~/.kube/config"
options=$(getopt -l "all,help" -o "hn:f" -a -- "$@")
eval set -- "$options"
#get options
while true; do
    case $1 in
        -h|--help)
            usage; exit 0
            ;;
        -n)
            shift
            NAME=$1
            ;;
        -f)
            shift
            KUBE_CONFIG=$1
            ;;
        --all)
            ALL=true
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

# validate input options
if ( [ -n "${ALL}" ] ) && ( [ -n "${NAME}" ] ) ; then usage; exit 1

if [ !-f KUBE_CONFIG ]; then echo -e "$KUBE_CONFIG does not exist or is unreadable!!"; exit 1; fi

CHECK=$(egrep -e "apiVersion: v1" -e "^clusters" -e "^users" -e "^contexts" ~/.kube/config | wc -l); if  [ check -lt 4]; then  echo -e "Invalid $KUBE_CONFIG !!" ; exit 1; fi

#populate cluster info Array
declare -A CLUSTER_ARRAY
{ # try
    RESID=$(az aks list --only-show-errors -o json | jq '.[] | .id' | sed -e 's/^"//' -e 's/"$//' 2>/tmp/error.txt )
    for i in $RESID; do
        key=$(echo $i | awk -F "managedClusters/" '{print $2}' 2>/tmp/error.txt)
        value=$(echo $i | awk -F "resourcegroups/" '{print $2}' | awk -F "/providers" '{print $1}' 2>/tmp/error.txt)
        CLUSTER_ARRAY[$key]=$value
    done
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

#stop /start the clusters, bypassing the skip ones
{ # try
    for key in "${!CLUSTER_ARRAY[@]}"; do
        if [ -z ${SKIP_CLUSTERS[$key]} ]; then 
            echo -e "$ACTION cluster $key in Resource Group ${CLUSTER_ARRAY[$key]} with --no-wait option...\n"
            az aks $ACTION -n $key -g ${CLUSTER_ARRAY[$key]} --only-show-errors --no-wait 2> /tmp/error.txt
        else
            echo -e "Skipping $ACTION $key in Resource Group ${CLUSTER_ARRAY[$key]}\n"
        fi
    done
} || { # catch
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}
exit 0