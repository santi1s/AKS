#!/bin/bash
cd ../../certs
kubectl ctx aks-agicingress
kubectl create namespace tls-ns
kubectl create secret tls frontend-tls --key="frontend.key" --cert="frontend.crt" -n tls-ns
kubectl create secret tls backend-tls --key="backend.key" --cert="backend.crt" -n tls-ns

kubectl get secrets frontend-tls -n tls-ns -oyaml | kubectl neat

kubectl get secrets backend-tls -n tls-ns -oyaml | kubectl neat