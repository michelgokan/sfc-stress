#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"

#Check if arguments entered
if [ -z "$1" ] || [ -z "$2" ]
then
   echo "Usage: assign-guaranteed-cpu-limit.sh <deployment_name> <namespace>"
   echo "Error: Please enter deployment name and namespace"
   exit 1
fi

deployment_name=$1
namespace=$2

kube_result1=$(kubectl patch deployment $1 --namespace $2 --type json -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/resources"}]')
echo "$kube_result1"
