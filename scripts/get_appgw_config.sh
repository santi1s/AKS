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
Usage: $0 -n <appgw-name> -g <appgw-resourcegroup>
Get Application Gateway Configuration

-h,--help   Print usage

-n,         Application Gateway Name

-g,         Application Gateway Resource Group


EOF
} 

unset NAME;unset RG
options=$(getopt -l "help" -o "hn:g:" -a -- "$@")
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
        --)
            shift
            break
            ;;
    esac
    shift
done

if ( [ -z "${NAME}" ] || [ -z "${RG}" ] ); then usage; exit 1 ;fi

b=$(tput bold)
n=$(tput sgr0)


az network application-gateway show  --resource-group $RG --name $NAME > /tmp/appgw.json

if [ -f /tmp/appgw.json ] ; then
    CFG_NAME=$(cat /tmp/appgw.json | jq -r '.name')
    CFG_RG=$(cat /tmp/appgw.json | jq -r '.resourceGroup')

    echo -e "\n###### Configuration for ${b}$CFG_NAME${n} in ResourceGroup ${b}$CFG_RG${n} ########\n"

    echo -e "${b}Tags${n}"
    cat /tmp/appgw.json | jq '.tags'
    
    # Frontend IP configurations
    FEIP_CFG_ID=$(cat /tmp/appgw.json | jq -r  '.frontendIpConfigurations[].id')
    FEIP_CFG_PIP_NAME=$(cat /tmp/appgw.json | jq -r  '.frontendIpConfigurations[].name')
    FEIP_CFG_PIP_ID=$(cat /tmp/appgw.json | jq -r  '.frontendIpConfigurations[].publicIpAddress.id')
    PIP_IPADDR=$(az network public-ip show --ids $FEIP_CFG_PIP_ID | jq -r '.ipAddress')
    FEIP_LISTENER=$(cat /tmp/appgw.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r '.name')
    echo -e "\nFrontend IP configurations:\n\tName: ${b}$FEIP_CFG_PIP_NAME${n}\n\tIP address: ${b}$PIP_IPADDR${n}\n\tAssociated listeners: ${b}$FEIP_LISTENER${n}"
    
    # Listeners
    LISTENER_ID=$(cat /tmp/appgw.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.id')
    LISTENER_NAME=$(cat /tmp/appgw.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.protocol')
    LISTENER_PROT=$(cat /tmp/appgw.json | jq   ".httpListeners[] | select(.frontendIpConfiguration.id==\"$FEIP_CFG_ID\")" | jq -r  '.name')
    LISTENER_PORT_ID=$(cat /tmp/appgw.json | jq -r  '.frontendPorts[].id')
    LISTENER_PORT=$(cat /tmp/appgw.json | jq -r  '.frontendPorts[].port')
    RULE_NAME=$(cat /tmp/appgw.json  | jq   ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.name')
    echo -e "\nListeners:\n\tName: ${b}$LISTENER_NAME${n}\n\tProtocol: ${b}$LISTENER_PROT${n}\n\tPort: ${b}$LISTENER_PORT${n}\n\tAssociated rule: ${b}$RULE_NAME${n}"

    # Rules
    RULE_TYPE=$(cat /tmp/appgw.json  | jq   ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.ruleType')
    echo -e "\nRule ${b}$RULE_NAME${n}:\n\tName: ${b}$RULE_NAME${n}\n\tType: ${b}$RULE_TYPE${n}"
    if [ $RULE_TYPE == "Basic" ]; then
        BPOOL_ID=$(cat /tmp/appgw.json | jq ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.backendAddressPool.id')
        if [ -n $BPOOL_ID ]; then 
            #set -x 
            BPOOL_ID=$(cat /tmp/appgw.json | jq ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.backendAddressPool.id')
            BPOOL_NAME=$(cat /tmp/appgw.json | jq ".backendAddressPools[] | select(.id==\"$BPOOL_ID\")" | jq -r '.name')
            echo -e "\tBackend Target: ${b}$BPOOL_NAME${n}"
        fi
    fi
    BSET_ID=$(cat /tmp/appgw.json | jq ".requestRoutingRules[] | select(.httpListener.id==\"$LISTENER_ID\")" | jq -r '.backendHttpSettings.id')
    BSET_NAME=$(cat /tmp/appgw.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")" | jq -r '.name')
    echo -e "\tHTTP settings:\t${b}$BSET_NAME${n}"
    ([ -n $BPOOL_ID ]) && ( echo -e "\n${b}$BPOOL_NAME${n} Settings:\n")
    cat /tmp/appgw.json | jq ".backendAddressPools[] | select(.id==\"$BPOOL_ID\")"
    ([ -n $BSET_ID ]) && ( echo -e "\n${b}$BSET_NAME${n} Settings:\n")
    cat /tmp/appgw.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")"
    PROBE_ID=$(cat /tmp/appgw.json | jq ".backendHttpSettingsCollection[] | select(.id==\"$BSET_ID\")"| jq -r '.probe.id')
    PROBE_NAME=$(cat /tmp/appgw.json | jq ".probes[]  | select (.id==\"$PROBE_ID\")" | jq -r '.name')
    ([ -n $PROBE_ID ]) && ( echo -e "\n${b}$PROBE_NAME${n} Settings:\n") && cat /tmp/appgw.json | jq ".probes[]  | select (.id==\"$PROBE_ID\")"
fi

if [ 0 -eq 1 ]; then

//listener
az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.httpListeners[].id'

// rule

az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.requestRoutingRules[] | select(.httpListener.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/httpListeners/fl-e1903c8aa3446b7b3207aec6d6ecba8a")'

//rule type
 az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.requestRoutingRules[] | select(.httpListener.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/httpListeners/fl-e1903c8aa3446b7b3207aec6d6ecba8a")' | jq '.ruleType'

// backend pool ID
az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.requestRoutingRules[] | select(.httpListener.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/httpListeners/fl-e1903c8aa3446b7b3207aec6d6ecba8a")' | jq '.backendAddressPool.id'
"/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/backendAddressPools/defaultaddresspool"

//backendpool

az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.backendAddressPools[] | select (.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/backendAddressPools/defaultaddresspool")'

//backed httpSetting iD 
az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.requestRoutingRules[] | select(.httpListener.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/httpListeners/fl-e1903c8aa3446b7b3207aec6d6ecba8a")' | jq '.backendHttpSettings.id'
"/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/backendHttpSettingsCollection/defaulthttpsetting"

az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.backendHttpSettingsCollection[] | select (.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/backendHttpSettingsCollection/defaulthttpsetting")'

//probeID

az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.backendHttpSettingsCollection[] | select (.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/backendHttpSettingsCollection/defaulthttpsetting")' | jq '.probe.id'
"/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/probes/defaultprobe-Http"

//probe
az network application-gateway show  --resource-group AGICdemo --name aks-AppGw | jq '.probes[]  | select (.id=="/subscriptions/5a26ef37-cf5a-444a-b287-99a8aca1a85b/resourceGroups/AGICdemo/providers/Microsoft.Network/applicationGateways/aks-AppGw/probes/defaultprobe-Http")'

fi