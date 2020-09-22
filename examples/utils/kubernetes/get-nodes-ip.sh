#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

$ROOTPATH/bin/utilities/kubernetes/get-nodes.sh | jq -r '.items[].status.addresses[] | select(.type=="InternalIP") | .address'
