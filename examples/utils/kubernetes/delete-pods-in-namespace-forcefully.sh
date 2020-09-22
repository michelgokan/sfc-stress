#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

if [ -z "$1" ]
then
   echo "Usage: force-delete-pods.sh <namespace>"
   echo "Error: Please enter specify the namespace."
   exit 1
fi

namespace=$1

#kube_result=$($ROOTPATH/bin/utilities/kubernetes/get-pods-in-namespace.sh $1 | jq '.items[].metadata.name' -r | xargs -I{} -0 -n 1 kubectl delete pod --namespace pcc {})
#echo "$kube_result" 

kube_result=$($ROOTPATH/bin/utilities/kubernetes/get-pods-in-namespace.sh $1 | jq '[.items[] | {n: .metadata.name, nn: .metadata.namespace}]' | jq '.[] | "kubectl delete pod \(.n) --namespace \(.nn) --force --grace-period=0"' -r )


#echo "$kube_result"
while read -r line
do
#   echo "$line"
   eval $line
done <<<"$kube_result"
