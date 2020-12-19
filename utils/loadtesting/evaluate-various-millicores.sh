#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"


if [ $# -ne 12 ]; then
    echo "Please enter arrival rate (first argument), duration (second argument), batch size (thirs argument), path of the workload that you want to initiate traffic (e.g. s1/cpu/1/1/1 as forth argument), suffix for saving logs (fifth argument), target deployment to change resources (sixth argument), target deployment namespace to change resources (seventh argument), target resource (i.e. cpu, memory, egress, or ingress as eighth argument), number of repititons (ninth argument), resource start (tenth argument), resource end (eleventh argument), and resource step (twelfth atgument)"
    exit 0
fi
arrival_rate=$1
duration=$2
batch_size=$3
_path=$4
suffix=$5
deployment=$6
namespace=$7
resource=$8
repetitions_count=$9
start_resource=${10}
end_resource=${11}
step_resource=${12}
_url=http://172.16.16.111:30553/$_path

mkdir $ROOTPATH/logs



for ((i=1;i<=$repetitions_count;i++))
  do
   echo "Starting iteration $i"
   current_resource=0
   sleep 5
   if [ "$current_resource" -eq "0" ]; then
      $ROOTPATH/utils/kubernetes/delete-resource-specs.sh $deployment $namespace
   elif [ "$resource" -eq "cpu" ]; then
      $ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh $deployment $namespace "${current_resource}m"
   else
      echo "ERRRORRRRRR"
      exit 0
   fi
   while : ; do
      v=$($ROOTPATH/utils/kubernetes/are-pods-in-namespace-ready.sh $namespace)
      
      while true
      do
         if [ "$v" -eq "0" ]; then
            echo "Some pods are not ready..."
            echo "Checking pods in $namespace namespace again..."
            v=$($ROOTPATH/utils/kubernetes/are-pods-in-namespace-ready.sh $namespace)
            sleep 1
         else
            echo "All pods in $namespace namespace are ready..."
            break
         fi
      done
      sleep 15
      echo "#######################"
      echo ""
      echo "Running $ROOTPATH/utils/loadtesting/loadtesting.sh $arrival_rate $duration $batch_size $_path $resource-${i}-${current_resource}"
      $ROOTPATH/utils/loadtesting/loadtesting.sh $arrival_rate $duration $batch_size $_path $resource-${i}-${current_resource}
      current_resource=$((current_resource+step_resource))
      echo "Setting current_resource to $current_resource (is it < $end_resource? Let's see!)"
      $ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh $deployment $namespace "${current_resource}m"
      echo "#######################"
      echo "#######################"
      (( current_resource <= end_resource )) || break
   done
done

echo "Done!"
