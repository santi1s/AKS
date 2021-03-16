#!/bin/bash

export RG=cnidemo
export LOC=westcentralus
#CNI V2
export CLUSTERNAME_CNIV2=aks-cnivnext
export VNET_NAME_CNIV2=aks-cniv2-vnet
export NODE_SUBNET_NAME_CNIV2=aks-cni2-nodesubnet
export POD_SUBNET_NAME_CNIV2=aks-cni2-podsubnet
export POD_SUBNET2_NAME_CNIV2=aks-cni2-podsubnet2

#CNI V1
export CLUSTERNAME_CNI=aks-cni
export VNET_NAME_CNI=aks-cni1-vnet
export SUBNET_NAME_CNI=aks-cni1-subnet

#2nd CNI V2
export CLUSTERNAME_CNIV2_2=aks-cnivnext-2
export NODE_SUBNET_NAME_CNIV2_2=aks-cni2-nodesubnet2