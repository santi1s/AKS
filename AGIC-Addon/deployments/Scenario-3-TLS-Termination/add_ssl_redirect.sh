#!/bin/bash
set -x
kubectl get ingress nginx-ingress -oyaml | kubectl neat > ingress.yaml
sed -i '/kubernetes\.io\/ingress\.class\: azure\/application-gateway/a\ \ \ \ appgw.ingress.kubernetes.io/ssl-redirect: "true"' ingress.yaml
kubectl replace -f ingress.yaml
rm -f ingress.yaml
