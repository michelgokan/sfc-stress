#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

kube_result=$(kubectl "${k8s_args[@]}" get nodes --all-namespaces -o json)
echo $kube_result | jq -c .
