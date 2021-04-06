#!/bin/bash

export RG=cnidemo
export LOC=westcentralus
#CNI V2
export CLUSTERNAME_CNIV2=aks-cniswift
export VNET_NAME_CNIV2=aks-cniswift-vnet
export NODE_SUBNET_NAME_CNIV2=aks-swift-nodesubnet
export POD_SUBNET_NAME_CNIV2=aks-swift-podsubnet
export POD_SUBNET2_NAME_CNIV2=aks-swift-podsubnet2

#CNI V1
export CLUSTERNAME_CNI=aks-cni
export VNET_NAME_CNI=aks-cni1-vnet
export SUBNET_NAME_CNI=aks-cni1-subnet

#2nd CNI V2
export CLUSTERNAME_CNIV2_2=aks-cniswift-2
export NODE_SUBNET_NAME_CNIV2_2=aks-cniswift-2-nodesubnet