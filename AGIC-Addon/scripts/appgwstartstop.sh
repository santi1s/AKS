#!/bin/bash
usage() { echo "Usage: $0 [-o <start|stop>]" 1>&2; exit 1; }

while getopts ":o:" o; do
    case "${o}" in
        o)
            s=${OPTARG}
            ((s == "start" || s == "stop")) || usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] ; then
    usage
fi


# Load Env Vars
source 0_envvars.sh



# Start/Stop AppGw
az network application-gateway $s -n $APPGW_NAME -g $RG


