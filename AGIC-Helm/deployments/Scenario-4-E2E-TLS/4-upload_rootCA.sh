#!/bin/bash
APPGW_NAME=aksagicingress-AppGw
RG=AGICIngress

kubectl get secret backend-tls -n tls-ns -ojson | kubectl neat | jq -r '.data."tls.crt"' | base64 --decode > backend.crt

az network application-gateway root-cert create \
--gateway-name $APPGW_NAME  \
--resource-group $RG \
--name backend-tls \
--cert-file backend.crt


