#!/bin/bash

#set -x
#
# get AKS cluster users cert
#
if [ $# -eq 0 ]; then
    echo "$0 -h for usage"
    exit 1
fi


PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h)
      echo "usage $0 -g <resource-group> -n <cluster-name> < --admin | --user <user-name>>"
      shift
      exit 1
      ;;
  case "$1" in
    --admin)
      USER=clusterAdmin
      shift
      ;;
    --user)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CUSER=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -g)
    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        RG=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -n)
    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CNAME=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"
echo $RG
echo $CNAME
echo $CUSER
