#!/bin/bash
#kubectl create secret tls nginx-tls-host --key="certs/server.key" --cert="certs/server.crt" -n test
kubectl apply -f nginx_tls_host.yaml -n test



