#!/bin/bash
kubectl create namespace nginx-tls
kubectl create secret tls nginx-tls --key="certs/server.key" --cert="certs/server.crt" -n nginx-tls
kubectl apply -f nginx_tls.yaml -n nginx-tls
kubectl config set-context --current --namespace=nginx-tls