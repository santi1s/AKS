#!/bin/bash

#
# deploy nginx pod in a given node
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
RAND=$(echo $(( $RANDOM % 100)))

cat <<EOF > /tmp/nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-$RAND
spec:
  nodeName: $NODE
  containers:
  - image: nginx
    name: nginx-$RAND
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
EOF

if [ -f /tmp/nginx.yaml ] ; then
    kubectl create -f /tmp/nginx.yaml > /dev/null 2>&1
    echo "pod nginx-$RAND created in node $NODE"
    rm -f /tmp/nginx.yaml
else
    echo "could not find spec nginx.yaml in /tmp"
fi
