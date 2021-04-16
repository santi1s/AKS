#!/bin/bash
#set -x
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl delete --ignore-not-found --all
