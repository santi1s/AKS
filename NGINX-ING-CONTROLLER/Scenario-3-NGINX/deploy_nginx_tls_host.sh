#!/bin/bash
kubectl create namespace application
kubectl create secret tls nginx-tls-host --key="certs/server.key" --cert="certs/server.crt" -n application
kubectl apply -f nginx_tls_host.yaml -n application



