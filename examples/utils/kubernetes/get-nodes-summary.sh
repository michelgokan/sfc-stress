#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

get_nodes=$(kubectl describe nodes)
#kube_result=$($ROOTPATH/bin/utilities/kubernetes/get-nodes.sh | jq '.items[].status | {hostname: .addresses[] | select(.type=="Hostname") | .address, ip: .addresses[] | select(.type=="InternalIP") | .address,allocatable:.allocatable}' )
#echo "$kube_result" | jq -s .
hostnames=$(echo "$get_nodes" |  grep -E "Hostname" | awk '{print $2}')
ips=$(echo "$get_nodes" |  grep -E "InternalIP" | awk '{print $2}')
cpu_requests=$(echo "$get_nodes" |  grep -E "  cpu" | awk '{print $2}')
cpu_requests_percent=$(echo "$get_nodes" |  grep -E "  cpu" | awk '{print $3}')
cpu_limits=$(echo "$get_nodes" |  grep -E "  cpu" | awk '{print $4}')
cpu_limits_percent=$(echo "$get_nodes" |  grep -E "  cpu" | awk '{print $5}')
mem_requests=$(echo "$get_nodes" |  grep -E "  memory" | awk '{print $2}')
mem_requests_percent=$(echo "$get_nodes" |  grep -E "  memory" | awk '{print $3}')
mem_limits=$(echo "$get_nodes" |  grep -E "  memory" | awk '{print $4}')
mem_limits_percent=$(echo "$get_nodes" |  grep -E "  memory" | awk '{print $5}')
allocatable_cpu=$(echo "$get_nodes" | grep -E "Allocatable" -A 6 | grep cpu | awk '{print $2}')
allocatable_memory=$(echo "$get_nodes" | grep -E "Allocatable" -A 6 | grep memory | awk '{print $2}')
allocatable_ephemeral=$(echo "$get_nodes" | grep -E "Allocatable" -A 6 | grep ephemeral-storage | awk '{print $2}')
allocatable_huge_page_1g=$(echo "$get_nodes" | grep -E "Allocatable" -A 6 | grep hugepages-1Gi | awk '{print $2}')
allocatable_huge_page_2mi=$(echo "$get_nodes" | grep -E "Allocatable" -A 6 | grep hugepages-2Mi | awk '{print $2}')
allocatable_pods=$(echo "$get_nodes" | grep -E "Allocatable" -A 6 | grep pods | awk '{print $2}')

#awk '{ print "{}" } ' <<< "" | jq . -s
counter=$(echo "$hostnames" | wc -l)
json="[ "

while [ $counter -gt 0 ] 
do 
   hostname=$(echo "$hostnames" | sed -n ${counter}p)
   ip=$(echo "$ips" | sed -n ${counter}p)
   cpu_request=$(echo "$cpu_requests" | sed -n ${counter}p)
   cpu_request_percent=$(echo "$cpu_requests_percent" | sed -n ${counter}p | sed  's/[\%\(\)]//g')
   cpu_limit=$(echo "$cpu_limits" | sed -n ${counter}p)
   cpu_limit_percent=$(echo "$cpu_limits_percent" | sed -n ${counter}p | sed  's/[\%\(\)]//g')
   mem_request=$(echo "$mem_requests" | sed -n ${counter}p)
   mem_request_percent=$(echo "$mem_requests_percent" | sed -n ${counter}p | sed  's/[\%\(\)]//g')
   mem_limit=$(echo "$mem_limits" | sed -n ${counter}p)
   mem_limit_percent=$(echo "$mem_limits_percent" | sed -n ${counter}p | sed  's/[\%\(\)]//g')
   alloc_cpu=$(echo "$allocatable_cpu" | sed -n ${counter}p)
   alloc_memory=$(echo "$allocatable_memory" | sed -n ${counter}p)
   alloc_ephemeral=$(echo "$allocatable_ephemeral" | sed -n ${counter}p)
   alloc_huge_page_1g=$(echo "$allocatable_huge_page_1g" | sed -n ${counter}p)
   alloc_huge_page_2mi=$(echo "$allocatable_huge_page_2mi" | sed -n ${counter}p)
   alloc_pods=$(echo "$allocatable_pods" | sed -n ${counter}p)
   static_policy=$(curl -X GET  "https://$K8S_MASTER_IP:$K8S_MASTER_PORT/api/v1/nodes/$hostname/proxy/configz" --header "Authorization: Bearer $K8S_TOKEN" --insecure -s | jq -r .kubeletconfig.cpuManagerPolicy)
   json="$json {\"hostname\": \"$hostname\",\"ip\":\"$ip\", \"cpuManagerPolicy\": \"$static_policy\",\"allocated\": { \"cpu\": { \"requests\": { \"total_value\": \"$cpu_request\", \"total_percentage\":\"$cpu_request_percent\" }, \"limits\": {\"total_value\": \"$cpu_limit\", \"total_percentage\": \"$cpu_limit_percent\" } }, \"memory\": { \"requests\": { \"total_value\": \"$mem_request\", \"total_percentage\": \"$mem_request_percent\" }, \"limits\": { \"total_value\": \"$mem_limit\", \"total_percentage\": \"$mem_limit_percent\" } } }, \"allocatable\": { \"cpu\":\"$alloc_cpu\", \"memory\": \"$alloc_memory\", \"ephemeral-storage\":\"$alloc_ephemeral\", \"hugepages-1Gi\":\"$alloc_huge_page_1g\", \"hugepages-2Mi\": \"$alloc_huge_page_2mi\", \"pods\": \"$alloc_pods\" } },"; 
   ((counter-=1)); 
done
json=${json::-1}
json="$json]"
echo "$json"  | jq .
