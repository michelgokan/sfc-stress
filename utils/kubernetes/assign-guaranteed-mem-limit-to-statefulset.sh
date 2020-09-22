#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../../ && pwd -P )"
source $ROOTPATH/src/init.sh

#Check if arguments entered
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
   echo "Usage: assign-guaranteed-mem-limit-to-statefulset.sh <statefulset_name> <namespace> <mem_limit>"
   echo "Error: Please specify statefulset name and namespace and memory limit (either in bytes or the equivalent suffixes (i.e. 128974848=129e6=129M=123Mi)"
   exit 1
fi

statefulset_name=$1
namespace=$2
mem_limit=$3
rand_number=$(( ( RANDOM % 1000 )  + 1 ))

echo "Assigning CPU limits (requests=limits=$3) to statefulset $1 in namespace $2"
cat <<EOT > $ROOTPATH/.patch.resource.temp.$rand_number
spec:
  template:
    spec:
      containers:
      - name: $statefulset_name
        resources:
          limits:
            memory: $mem_limit
          requests:
            memory: $mem_limit
EOT

#kube_result1=$(kubectl "${k8s_args[@]}" patch deployment $1 --namespace $2 --type json -p "[{\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/limits/cpu\", \"value\": \"$cpu_limit\"}]")
kube_result1=$(kubectl "${k8s_args[@]}" patch statefulset $1 --namespace $2 --patch "$(cat $ROOTPATH/.patch.resource.temp.$rand_number)")
rm $ROOTPATH/.patch.resource.temp.$rand_number

echo "$kube_result1"
