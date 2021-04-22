#!/bin/bash -

declare -A all_chains=()
declare -A queued_chains=()

builtin_chains_as_regexp='INPUT|OUTPUT|FORWARD|PREROUTING|POSTROUTING'
queue_list=""
prepend_chain=""
show_chain_heading=false
one_go=false
uniquify=true

_print_usage() {
   cat <<- EOF
        Usage: $0 [-npofh] <starting-chain>

        -n    shows chain's creation command as heading, useful for spotting empty chains
        -p    prepends chain's name to each rule
        -o    read everything in one go, 10x quicker when many small chains
        -f    expand all references to a same chain, but beware of chain loops or chains referenced hundreds of times
        -h    shows this help
EOF
}

_expand_chain() {
    local chain_to_expand="${1}"

    local rules=""
    # if one_go selected, work with in-memory cache of chains
    if $one_go ; then
        rules="${all_chains[${chain_to_expand}]}"
    # otherwise read in chain to consider
    else
        rules="$(iptables -S "${chain_to_expand}")"
    fi

    $show_chain_heading && \
        ! [[ "${chain_to_expand}" =~ ${builtin_chains_as_regexp} ]] && \
        echo "-N ${chain_to_expand}"
    while read -r cmd chain rule ; do
        case "${cmd}" in
        -A)
            set -- ${rule}
            # look for target option in rule
            while [ -n "${1}" ] && ! [[ "${1}" =~ -(j|g) ]] ; do shift ; done
            # a few sanity checks
            [ -n "${1}" ] || continue # a rule with no target, skip it
            shift
            [ -n "${1}" ] || { echo "what!? empty target in ${rule}" >&2 ; continue ; }
            if [ -n "${all_chains[${1}]}" ] ; then
                # if target is a chain
                # add to queued chains if uniquify *not* requested or if chain never queued
                if ! $uniquify || [ -z "${queued_chains[${1}]}" ] ; then
                    queue_list+="${1} "
                    queued_chains[${1}]="1"
                fi
            fi
            # show rule
            echo "${prepend_chain:+[${chain_to_expand}] }${cmd} ${chain} ${rule}"
        ;;
        esac
    done <<<"${rules}"
}

###
# ACTUAL EXECUTION STARTS HERE
#

# parse command options if any
while getopts nphfo option ; do
    case $option in
    n) show_chain_heading=true
    ;;
    p) prepend_chain="1"
    ;;
    h) _print_usage ; exit 0
    ;;
    o) one_go=true
    ;;
    f) uniquify=false
    ;;
    '?') exit 1
    ;;
    esac
done

[ -n "${!OPTIND}" ] || { _print_usage ; exit 1 ; }

# preparation step:
# if one_go selected, slurp everything in
if $one_go ; then
    # invoke explicit command only when stdin is the terminal
    [ -t 0 ] && exec 0< <(iptables -S)
    while read -r cmd chain rule ; do
        case "${cmd}" in
        -N)
            all_chains[${chain}]=" " # <<-- whitespace to make provision for empty chains
        ;;
        -A)
            # assign rule to its chain in cache
            all_chains[${chain}]+=$'\n'"${cmd} ${chain} ${rule}"
        ;;
        esac
    done
# otherwise read in chain names only
else
    while IFS= read -r chain ; do
        all_chains[${chain}]="1"
    done < <(iptables -S | sed -ne '/^-N /s///p')
fi

# expand starting chain
_expand_chain ${!OPTIND}

# breadth-first expand queued chains
# as long as queue is not empty
while [ "${#queue_list}" -gt 0 ] ; do
    # take next queued chain
    subchain="${queue_list%% *}"
    # expand it
    _expand_chain "${subchain}"
    # remove expanded chain from queue
    queue_list="${queue_list#${subchain} }"
    # queue gets updated by _expand_chain as needed
done

exit 0