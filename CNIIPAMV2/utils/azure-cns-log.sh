#!/bin/bash

#
# Get azure-cns pod logs for a given node
#
#Usage message
usage()
{
        echo 'Interactive:'
        echo '$0'
        echo " "
        echo 'Non-Interactive'
        echo '$0 <NODE>'
        exit 0
}

if [ "$1" = "-h" ]
then
        usage
        exit 1
fi

#Check user input.
if [ -z "$1" ]; then

        mapfile -t nodenumber < <( kubectl get nodes --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' )

        for i in "${!nodenumber[@]}"; do
          printf "$i ${nodenumber[i]} \n"
        done
        read -p "Enter the node number: " NODE_INDEX
        NODE=${nodenumber[NODE_INDEX]}

    else
        NODE=$1
    fi
CNSPOD=$(kubectl get pods -o wide -n kube-system -l k8s-app=azure-cns --field-selector spec.nodeName=$NODE | awk 'NR>1 {print $1}')
kubectl logs $CNSPOD -n kube-system -f