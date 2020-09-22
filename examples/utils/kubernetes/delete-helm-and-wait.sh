#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

if [ -z "$1" ]
then
   echo "Usage: delete-helm-and-wait.sh <helm chart name>"
   echo "Error: Please enter the helm chart name as argument"
   exit 1
fi


namespace=$1
is_deleted=0
is_exists=1

while true
do
   if [ $is_deleted -eq 0 ];
   then
      echo "Namespace $1 has not been deleted yet"
sshpass -p $K8S_MASTER_HOST_PASSWORD ssh -q $K8S_MASTER_HOST_USERNAME@$K8S_MASTER_IP <<EOF
echo "Deleting $1..."
echo "Be patient :-)"
helm delete --purge $1
EOF
      is_deleted=1   
   else
      echo "check whether deleting is over..."
      kube_result=$(kubectl "${k8s_args[@]}" get namespaces)
      exists=$(echo "$kube_result" | awk '{print $1}' | grep -E "^$1$")
      if [ ! -z "$exists" ]
      then
         # Namespace exists...
         echo "Namespace $1 is still there..."
         echo "Check whether all the pods deleted instead..."

         pods_exists=$(kubectl "${k8s_args[@]}" get pods --namespace $namespace |& grep "No resources found.")
#         echo "pods_exists command=kubectl ${k8s_args[@]} get pods --namespace $namespace |& grep \"No resources found.\""
         if [ ! -z "$pods_exists" ]
         then 
#            echo "pods_exists=$pods_exists"
            # Pods Deleted ...
            echo "No pods left ..."
            is_exists=0
         else
            echo "Some pods still exists..."
            echo "$pods_exists"
         fi
      else
         is_exists=0
         break
      fi
      if [ $is_exists -eq 0 ];
      then
         echo "$1 deleted successfully ($is_exists)!"
         break
      fi
      sleep 1
   fi
done
