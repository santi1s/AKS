#!/bin/bash
kubectl apply -f nginx-deployment.yaml
POD=$(kubectl get pods -n tls-ns -l app=website | awk 'NR>1 {print $1}')
kubectl exec -it  $POD -n tls-ns -- curl -kvL https://localhost:8443
