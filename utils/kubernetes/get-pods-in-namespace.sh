#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"

if [ -z "$1" ]
then
   echo "Usage:get-pods-in-namespace.sh <namespace-name>"
   echo "Error: Please enter the namespace name"
   exit 1
fi

kube_result=$(kubectl "${k8s_args[@]}" get pods --namespace $1 -o json)
echo $kube_result | jq -c .
