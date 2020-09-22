#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

#Check if arguments entered
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
   echo "Usage: assign-guaranteed-cpu-limit.sh <deployment_name> <namespace> <node_name>"
   echo "Error: Please enter deployment name and namespace and node_name"
   exit 1
fi

name=$1
namespace=$2
host=$3

#kube_result1=$(kubectl "${k8s_args[@]}" patch deployment $1 --namespace $2 --type json -p "[{\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/limits/cpu\", \"value\": \"$cpu_limit\"}]")
kube_result1=$(kubectl "${k8s_args[@]}" patch deployment $name --namespace $namespace --type json -p "[{'op': 'replace', 'path': '/spec/template/spec/nodeSelector', 'value': {'kubernetes.io/hostname': '$host'}}]")

echo "$kube_result1"
