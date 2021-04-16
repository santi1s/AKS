#!/bin/bash
usage() { echo "Usage: $0 -n <name> -g <resource-group> -o <start|stop>" 1>&2; exit 1; }

unset NAME;unset RG;unset OPTION
options=$(getopt -l "help" -o "ho:n:g:" -a -- "$@")
eval set -- "$options"
#get options
while true; do
    case $1 in
        -h|--help)
            usage; exit 0
            ;;
        -n)
            shift
            NAME=$1
            ;;
        -g)
            shift
            RG=$1
            ;;
        -o)
            shift
            OPTION=$1
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

if ( [ -z "${NAME}" ] || [ -z "${RG}" ] ||  [ -z "${OPTION}" ]); then usage; exit 1 ;fi


# Start/Stop AppGw
az network application-gateway $OPTION -n $NAME -g $RG


