#!/bin/bash
#set -x
usage() { echo -e  "Usage: $0 -p <pod-ui> -n <container-name> [-k|-m|-g]\nwhere:\n<pod-ui> can be obtained by kubectl get pods -o jsonpath='{.metadata.uid}'" 1>&2; exit 1; }
#kubectl get pods stress-877554d7b-ljphm -o jsonpath='{.metadata.uid}'
#docker inspect --format="{{.Id}}"


while getopts ":-p:-n:kmg" o; do
    case "${o}" in
        p)
            puid=${OPTARG}
            #((s == "start" || s == "stop")) || usage
            ;;
        n)
            cname=${OPTARG}
            ;;
        k)
            usekb=1
            ;;
        m)
            usemb=1
            ;;
        g)
            usegb=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "${puid}" ] || [ -z "${cname}" ] || ( ( [ -n "${usekb}" ] && [ -n "${usemb}" ] ) || ( [ -n "${usekb}" ] && [ -n "${usegb}" ] ) || ( [ -n "${usemb}" ] && [ -n "${usegb}" ] ) ); then
    usage
    exit 1
fi



docker_sid=$(docker ps | grep $puid | grep $cname | grep -v pause | awk '{print $1}')
if [ -z "${docker_sid}" ]; then
    echo -e "Could not find any container $cname matching pod with uid:$puid\n"
    exit 1
fi

docker_lid=$(docker inspect $docker_sid --format="{{.Id}}")
memstats_dir="/sys/fs/cgroup/memory/kubepods/burstable/pod$puid/$docker_lid"
mem_usage=$(cat $memstats_dir/memory.usage_in_bytes)
inactive_file=$(cat $memstats_dir/memory.stat | grep total_inactive_file | awk '{print $2}')
let cont_mem_working_set_byte=$mem_usage-$inactive_file
cont_mem_rss_byte=$(cat $memstats_dir/memory.stat | grep "total_rss " | awk '{print $2}')
oom_kills=$(cat $memstats_dir/memory.oom_control | grep "oom_kill " | awk '{print $2}')
cont_mem_working_set_kbyte=$(printf '%.2f\n' $(echo "$cont_mem_working_set_byte/1024" | bc -l))
cont_mem_working_set_mbyte=$(printf '%.1f\n' $(echo "$cont_mem_working_set_byte/1024/1024" | bc -l))
cont_mem_working_set_gbyte=$(printf '%.2f\n' $(echo "$cont_mem_working_set_byte/1024/1024/1024" | bc -l))
cont_mem_rss_kbyte=$(printf '%.2f\n' $(echo "$cont_mem_rss_byte/1024" | bc -l))
cont_mem_rss_mbyte=$(printf '%.1f\n' $(echo "$cont_mem_rss_byte/1024/1024" | bc -l))
cont_mem_rss_gbyte=$(printf '%.2f\n' $(echo "$cont_mem_rss_byte/1024/1024/1024" | bc -l))
echo -e "$(date +'%d/%m/%Y %T')\n"
(($usekb)) && echo -e "\nContainer_memory_working_set_bytes(KB):$cont_mem_working_set_kbyte\nContainer_memory_rss(KB):$cont_mem_rss_kbyte\nOOM_KILS:$oom_kills\n" && exit 0
(($usemb)) && echo -e "\nContainer_memory_working_set_bytes(MB):$cont_mem_working_set_mbyte\nContainer_memory_rss(MB):$cont_mem_rss_mbyte\nOOM_KILS:$oom_kills\n" && exit 0
(($usegb)) && echo -e "\nContainer_memory_working_set_bytes(GB):$cont_mem_working_set_gbyte\nContainer_memory_rss(GB):$cont_mem_rss_gbyte\nOOM_KILS:$oom_kills\n" && exit 0
echo -e "\nContainer_memory_working_set_bytes:$cont_mem_working_set_byte\nContainer_memory_rss:$cont_mem_rss_byte\nOOM_KILS:$oom_kills\n" && exit 0