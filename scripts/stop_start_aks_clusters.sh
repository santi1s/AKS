#!/bin/bash
#set -x
set -e
# 
# Bash script stop/start one or all cluster for the current subscription
# List of cluster to be skipped can be used by using env variable SKIP_AKS_CLUSTERS with
# a colon separated list of cluster names
# export SKIP_AKS_CLUSTERS=aks-agic:AGICIngress
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

if [ -z $SKIP_AKS_CLUSTERS ]; then
    while true; do
    read -p "Warning! SKIP_AKS_CLUSTERS variable is no set! This will stop ALL the cluster in the current Subscription. Do you want to continue?(y/n)" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

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
Usage: $0 [-h|--help] -n <cluster-name> -g <cluster-resourcegroup> -s <start|stop> | [--all]
Stop AKS cluster(s) in current subscription

-h,--help   Print usage

-n,         Cluster Name

-g,         Cluster Resource Group

-s,         stop - stops cluster(s) , start - starts cluster(s)

--all,      Stop all AKS clusters

You can skip start/stoping some clusters by exporting env variable SKIP_AKS_CLUSTERS:

export SKIP_AKS_CLUSTERS=cluster1:cluster2:cluster3


EOF
} 

unset NAME;unset RG;unset ALL; unset ACTION
options=$(getopt -l "all,help" -o "hn:g:s:" -a -- "$@")
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
        -g)
            shift
            RG=$1
            ;;
        -s)
            shift
            ACTION=$1
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
if ( [ -z $ACTION ] || ( [ -n $ACTION ] && ( [ $ACTION != "start" ] && [ $ACTION != "stop" ] ) ) ); then usage; exit 1; fi

if ( [ -n "${ALL}" ] ); then
    if ( [ -n "${NAME}" ] || [ -n "${RG}" ] ) ; then
        usage
        exit 1
    fi   
else
    if ( [ -z "${NAME}" ] || [ -z "${RG}" ] ); then 
       usage
       exit 1 
    fi
fi

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