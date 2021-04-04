#!/bin/bash

kubectl delete service $1
kubectl delete deployment $1
