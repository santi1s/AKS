#!/bin/bash

export RG=AGICIngress
export LOC=AustraliaEast
#AKS
export CLUSTERNAME=aks-agicingress
export VNET_NAME=aks-agicingress-vnet
export NODE_SUBNET_NAME=aks-agicingress-nodesubnet
#AppGw
export APPGW_PIP_NAME=aksagicingress-AppGw-PublicIP
export APPGW_SUBNET_NAME=aksagicingress-AppGw-subnet
export APPGW_NAME=aksagicingress-AppGw
#User Identity
export AGIC_IDENTITY=aksagicingress-identity
