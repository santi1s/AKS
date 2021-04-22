#!/bin/bash

RG=AGICdemo
APPGW_NAME=aks-AppGw
PIP_ID=$(az network application-gateway frontend-ip  list --resource-group $RG --gateway-name $APPGW_NAME -o tsv --query [].publicIpAddress.id)
PIP_ADDR=$(az network public-ip show --ids $PIP_ID -o tsv --query ipAddress)
PIP_PORT=80

nc -vz $PIP_ADDR $PIP_PORT
wget http://$PIP_ADDR  >/dev/null 
if [ -f index.html ]; then lynx -dump index.html; rm -f index.html;fi 
