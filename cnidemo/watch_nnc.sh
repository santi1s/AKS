#!/bin/bash

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
 watch -n 1 kubectl get nnc $NODE -n kube-system  -o jsonpath={$.spec.requestedIPCount}