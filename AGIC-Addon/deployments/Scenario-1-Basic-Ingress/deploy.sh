#!/bin/bash
kubectl ctx aks-agic
kubectl apply -f aspnetapp.yaml
echo -e "\naspnetapp deployment\n"
kubectl get deployments -l app=aspnetapp -o wide
echo -e "\naspnetapp pods\n"
kubectl get pods -l app=aspnetapp -owide
echo -e "\naspnetapp ClusterIP Service\n"
kubectl get services -l app=aspnetapp
echo -e "\naspnetapp ingress describe\n"
kubectl describe ingresses -l app=aspnetapp
echo -e "\naspnetapp ingress YAML definition (neat)\n"
kubectl get ingresses -l app=aspnetapp -oyaml | kubectl neat
