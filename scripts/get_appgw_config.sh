#!/bin/bash
set -e
#set -x

#RG=AGICIngress
#APPGW_NAME=aksagicingress-AppGw
## Prerequisites
#check bash version
version=$(bash --version | grep "^GNU bash" | awk '{print $4}' | awk -F "." '{print $1}')
if [ $version -lt 4 ]; then
    echo -e "This script requires bash version > 4\n"
    exit 1
fi
#check jq
{ # try
    jq --version > /dev/null 2>&1
} || { # catch
    echo -e "This script requires jq to be installed\n"
    if [ -f /tmp/error.txt ] ; then cat /tmp/error.txt ; rm -f /tmp/error.txt;fi
    exit 1
}

usage()
{
cat << EOF  
Usage: $0 -n <appgw-name> -g <appgw-resourcegroup> -f <input-file>
Get Application Gateway Configuration

-h,--help   Print usage

-n,         Application Gateway Name

-g,         Application Gateway Resource Group


EOF
} 

unset NAME;unset RG;unset FNAME;
options=$(getopt -l "help" -o "hn:g:f:" -a -- "$@")
eval set -- "$options"
#get options
while true; do
    case $1 in
        -h|--help)
            usage; exit 0
            ;;
        -f)
            shift
            FNAME=$1
            break
            ;;
        -n)
            shift
            NAME=$1
            ;;
        -g)
            shift
            RG=$1
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

UUID=$(uuidgen)
IN_JSON=$(echo "/tmp/appgw_${UUID}.json")

if ( [ -n "$FNAME"  ] && [ -f "$FNAME" ] ); then
    mv  ${FNAME} /tmp/appgw_${UUID}.json 
elif ( [ -z "${NAME}" ] || [ -z "${RG}" ] ); then usage; exit 1 ;fi

b=$(tput bold)
n=$(tput sgr0)

if ( [ -n ${NAME}  ] && [ -z ${FNAME} ] ); then
    az network application-gateway show  --resource-group $RG --name $NAME > ${IN_JSON}
fi

#
# print_backpool -i ID --name-only
#
print_backpool ()
{
    local BPOOL_NAME;local NAME_ONLY; local BPOOL_ID
    local options=$(getopt -l "name-only" -o "i:" -a -- "$@")
    eval set -- "$options"
    #get options
    while true; do
        case $1 in
            --name-only)
                NAME_ONLY=True
                ;;
            -i)
                shift
                BPOOL_ID=$1
                ;;
            --)
                shift
                break
                ;;
        esac
        shift
    done
    BPOOL_NAME=$(cat /tmp/appgw_${UUID}.json | jq ".backendAddressPools[] | select(.id==\"$BPOOL_ID\")" | jq -r '.name')
    if ( [ -n "${NAME_ONLY}" ] &&  [ ${NAME_ONLY} == "True" ] ); then
        echo -e "${b}$BPOOL_NAME${n}"
        exit 0
    fi
    echo -e "\nBackend Pool ${b}$BPOOL_NAME${n}:\n"
    cat /tmp/appgw_${UUID}.json | jq ".backendAddressPools[] | select(.id==\"$BPOOL_ID\")"
}

print_backend_http ()
{
    local BSET_NAME;local NAME_ONLY; local BSET_ID
    local options=$(getopt -l "name-only" -o "i:" -a -- "$@")
    eval set -- "$options"
    #get options
    while true; do
        case $1 in
            --name-only)
                NAME_ONLY=True
                ;;
            -i)
                shift
                BSET_ID=$1
                ;;
            --)
                shift
                break
                ;;
        esac
        shift
    done
    BSET_NAME=$(cat /tmp/appgw_${UUID}.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")" | jq -r '.name')
    if ( [ -n "${NAME_ONLY}" ] &&  [ ${NAME_ONLY} == "True" ] ); then
        echo -e "${b}$BSET_NAME${n}"
        exit 0
    fi
    echo -e "\nBackend HTTP Setting ${b}$BSET_NAME${n}:\n"
    cat /tmp/appgw_${UUID}.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")"
}

print_probe ()
{
    PROBE_NAME=$(cat /tmp/appgw_${UUID}.json | jq ".probes[]  | select (.id==\"$1\")" | jq -r '.name')
    echo -e "\nHealth Probe ${b}$PROBE_NAME${n} Settings:\n"
    cat /tmp/appgw_${UUID}.json | jq ".probes[]  | select (.id==\"$1\")"
}


if [ -f /tmp/appgw_${UUID}.json ] ; then
    CFG_NAME=$(cat /tmp/appgw_${UUID}.json | jq -r '.name')
    CFG_RG=$(cat /tmp/appgw_${UUID}.json | jq -r '.resourceGroup')

    echo -e "\n###### Configuration for ${b}$CFG_NAME${n} in ResourceGroup ${b}$CFG_RG${n} ########\n"

    echo -e "${b}Tags${n}"
    cat /tmp/appgw_${UUID}.json | jq '.tags'
    
    # Frontend IP configurations
    FEIP_CFG_ID=$(cat /tmp/appgw_${UUID}.json | jq -r  '.frontendIpConfigurations[].id')
    FEIP_CFG_PIP_NAME=$(cat /tmp/appgw_${UUID}.json | jq -r  '.frontendIpConfigurations[].name')
    FEIP_CFG_PIP_ID=$(cat /tmp/appgw_${UUID}.json | jq -r  '.frontendIpConfigurations[].publicIpAddress.id')
    PIP_IPADDR=$(az network public-ip show --ids $FEIP_CFG_PIP_ID | jq -r '.ipAddress')
    FEIP_LISTENER=$(cat /tmp/appgw_${UUID}.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r '.name')
    echo -e "\nFrontend IP configurations:\n\tName: ${b}$FEIP_CFG_PIP_NAME${n}\n\tIP address: ${b}$PIP_IPADDR${n}\n\tAssociated listeners: ${b}$FEIP_LISTENER${n}"
    
    # Listeners
    LISTENER_ID=$(cat /tmp/appgw_${UUID}.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.id')
    LISTENER_NAME=$(cat /tmp/appgw_${UUID}.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.name')
    LISTENER_PROT=$(cat /tmp/appgw_${UUID}.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.protocol')
    LISTENER_PORT_ID=$(cat /tmp/appgw_${UUID}.json | jq -r  '.frontendPorts[].id')
    LISTENER_PORT=$(cat /tmp/appgw_${UUID}.json | jq -r  '.frontendPorts[].port')
    RULE_NAME=$(cat /tmp/appgw_${UUID}.json  | jq   ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.name')
    if [ $LISTENER_PROT == "Https" ]; then
        REQ_SERVER_NAME=$(cat /tmp/appgw_${UUID}.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.requireServerNameIndication')
        SSL_CERT_ID=$(cat /tmp/appgw_${UUID}.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.sslCertificate.id')
        SSL_CERT_NAME=$(cat /tmp/appgw_${UUID}.json | jq ".sslCertificates[] | select(.id==\"$SSL_CERT_ID\")" | jq -r '.name')
        echo -e "\nListeners:\n\tName: ${b}$LISTENER_NAME${n}\n\tProtocol: ${b}$LISTENER_PROT${n}\n\tPort: ${b}$LISTENER_PORT${n} \
        \n\trequireServerNameIndication:${b}$REQ_SERVER_NAME${n}\n\tsslCert:${b}$SSL_CERT_NAME${n}\n\tAssociated rule: ${b}$RULE_NAME${n}"
    else
        echo -e "\nListeners:\n\tName: ${b}$LISTENER_NAME${n}\n\tProtocol: ${b}$LISTENER_PROT${n}\n\tPort: ${b}$LISTENER_PORT${n}\n\tAssociated rule: ${b}$RULE_NAME${n}"
    fi

    # Rules
    RULE_TYPE=$(cat /tmp/appgw_${UUID}.json  | jq   ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.ruleType')
    echo -e "\nRule ${b}$RULE_NAME${n}:\n\tName: ${b}$RULE_NAME${n}\n\tType: ${b}$RULE_TYPE${n}"
    
    if [ $RULE_TYPE == "Basic" ]; then
        BPOOL_ID=$(cat /tmp/appgw_${UUID}.json | jq ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.backendAddressPool.id')
        BPOOL_NAME=$(cat /tmp/appgw_${UUID}.json | jq ".backendAddressPools[] | select(.id==\"$BPOOL_ID\")" | jq -r '.name')
        echo -e "\tBackend Target: ${b}$BPOOL_NAME${n}"
        BSET_ID=$(cat /tmp/appgw_${UUID}.json | jq ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.backendHttpSettings.id')
        BSET_NAME=$(cat /tmp/appgw_${UUID}.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")" | jq -r '.name')
        echo -e "\tHTTP settings:\t${b}$BSET_NAME${n}"
        ([ -n $BPOOL_ID ]) && ( print_backpool -i $BPOOL_ID)
        ([ -n $BSET_ID ]) && ( print_backend_http -i $BSET_ID)
        PROBE_ID=$(cat /tmp/appgw_${UUID}.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")"| jq -r '.probe.id')
        ([ -n $PROBE_ID ]) && ( print_probe $PROBE_ID)
    elif [ $RULE_TYPE == "PathBasedRouting" ]; then
        URL_PATH_MAP_ID=$(cat /tmp/appgw_${UUID}.json | jq ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.urlPathMap.id')
        DEF_BPOOL_ID=$(cat /tmp/appgw_${UUID}.json | jq ".urlPathMaps [] | select(.id == \"$URL_PATH_MAP_ID\")" | jq -r '.defaultBackendAddressPool.id')
        DEF_BSET_ID=$(cat /tmp/appgw_${UUID}.json | jq ".urlPathMaps [] | select(.id == \"$URL_PATH_MAP_ID\")" | jq -r '.defaultBackendHttpSettings.id')
        DEF_BPOOL_NAME=$(print_backpool -i $DEF_BPOOL_ID --name-only)
        DEF_BSET_NAME=$(print_backend_http -i $DEF_BSET_ID --name-only)
        echo -e "\tDefault Backend Target: ${b}$DEF_BPOOL_NAME${n}\n\tDefault HTTP settings: ${b}$DEF_BSET_NAME${n}"
        echo -e "\n\t${b} Path Based Rules${n}\n"
        printf "\t\t${b}%-20s %-45s %-45s %-40s${n}\n" "Path" "Target name" "HTTP setting name" "Backend pool";
        
        PATH_RULES=$(cat /tmp/appgw_${UUID}.json | jq ".urlPathMaps [] | select(.id == \"$URL_PATH_MAP_ID\")" | jq '.pathRules[]' | jq --compact-output '.')
        declare -A HTTP_SETTINGS_ARRAY
        declare -A BPOOL_ARRAY
        for PATH_RULE in $( echo $PATH_RULES  | jq --compact-output '.'); do
            _jq(){
                echo $PATH_RULE |  jq -r ${1}
            }
            #set -x
            TGT_NAME=$(echo $(_jq '.name'))
            SPATH=$(echo $(_jq '.paths[]'))
            HTTP_SET_ID=$(echo $(_jq '.backendHttpSettings.id'))
            HTTP_SETTINGS_ARRAY[$(echo $HTTP_SET_ID | awk -F"/" '{print $NF}')]=$HTTP_SET_ID
            BPOOL_ID=$(echo $(_jq '.backendAddressPool.id'))
            BPOOL_ARRAY[$(echo $BPOOL_ID | awk -F"/" '{print $NF}')]=$BPOOL_ID

            printf "\t\t%-20s %-45s %-45s %-40s\n" "$SPATH" "$TGT_NAME" "$(echo $HTTP_SET_ID | awk -F"/" '{print $NF}')" "$(echo $BPOOL_ID | awk -F"/" '{print $NF}')   ";
        done
        for val in "${BPOOL_ARRAY[@]}"; do print_backpool -i $val; done
        for val in "${HTTP_SETTINGS_ARRAY[@]}"; do print_backend_http -i $val; done
        PROBE_ID=$(cat /tmp/appgw_${UUID}.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$val\")"| jq -r '.probe.id')
        print_probe $PROBE_ID
    fi
fi
