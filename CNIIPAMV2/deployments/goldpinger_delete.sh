#!/bin/bash

#
# remove goldpinger related k8s objects
#
kubectl delete deployment goldpinger-deploy
kubectl delete clusterrolebinding goldpinger-clusterrolebinding
kubectl delete clusterrole goldpinger-clusterrole
kubectl delete service goldpinger
kubectl delete daemonset goldpinger-daemon
kubectl delete serviceaccount goldpinger-serviceaccount