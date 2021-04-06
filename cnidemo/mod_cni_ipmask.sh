#!/bin/bash

cat <<EOF > /tmp/ipmask_cm.yaml
apiVersion: v1
data:
  ip-masq-agent: |-
    nonMasqueradeCIDRs:
      - 10.0.0.0/16
      - 10.0.0.0/22
      - 10.0.4.0/22
      - 172.16.5.4/32
    masqLinkLocal: true
    resyncInterval: 60s
kind: ConfigMap
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    component: azure-ip-masq-agent
    kubernetes.io/cluster-service: "true"
  name: azure-ip-masq-agent-config
  namespace: kube-system
EOF

if [ -f /tmp/ipmask_cm.yaml ]; then
kubectl apply -f /tmp/ipmask_cm.yaml
kubectl delete pod -l k8s-app=azure-ip-masq-agent -n kube-system
rm -f /tmp/ipmask_cm.yaml
fi
