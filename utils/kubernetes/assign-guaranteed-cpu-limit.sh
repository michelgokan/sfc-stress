#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"

#Check if arguments entered
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
   echo "Usage: assign-guaranteed-cpu-limit.sh <deployment_name> <namespace> <cpu_limit>"
   echo "Error: Please enter deployment name and namespace and cpu limit (eaither an integer or the millicore (i.e. 1000m=1)"
   exit 1
fi

deployment_name=$1
namespace=$2
cpu_limit=$3
rand_number=$(( ( RANDOM % 1000 )  + 1 ))
echo "Assigning CPU limits (requests=limits=$3) to deployment $1 in namespace $2"
cat <<EOT > $ROOTPATH/.patch.resource.temp.$rand_number
spec:
  template:
    spec:
      containers:
      - name: $deployment_name
        resources:
          limits:
            cpu: $cpu_limit
          requests:
            cpu: $cpu_limit
EOT

kube_result1=$(kubectl "${k8s_args[@]}" patch deployment $1 --namespace $2 --patch "$(cat $ROOTPATH/.patch.resource.temp.$rand_number)")
cat $ROOTPATH/.patch.resource.temp.$rand_number
rm $ROOTPATH/.patch.resource.temp.$rand_number

echo "$kube_result1"
