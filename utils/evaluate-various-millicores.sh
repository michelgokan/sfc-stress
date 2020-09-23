#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

if [ $# -ne 2 ]
  then
    echo "Please enter service name (first argument) and then namespace (second argument)."
    exit 0
fi

mkdir $ROOTPATH/logs
startCpu=100
endCpu=4000
stepCpu=100
currentCpu=0

$ROOTPATH/utils/kubernetes/delete-resource-specs.sh $1 $2

while : ; do
   v=$($ROOTPATH/utils/kubernetes/are-pods-in-namespace-ready.sh $2)
   
   while true
   do
      if [ "$v" -eq "0" ]; then
         echo "Some pods are not ready..."
         echo "Checking pods in $2 namespace again..."
         v=$($ROOTPATH/utils/kubernetes/are-pods-in-namespace-ready.sh $2)
         sleep 1
      else
         echo "All pods in $2 namespace are ready..."
         break
      fi
   done
   sleep 15
   echo "#######################"
   echo "Running get-perf-stats-while-running.sh for s1/cpu/100 with $currentCpu millicores..."
   echo ""
   echo "Running $ROOTPATH/utils/get-perf-stats-while-running.sh $1 $2 s1/cpu/100 cpu-${currentCpu}"
   $ROOTPATH/utils/get-perf-stats-while-running.sh $1 $2 s1/cpu/100 cpu-${currentCpu}
   currentCpu=$((currentCpu+stepCpu))
   $ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh $1 $2 "${currentCpu}m"
   echo "#######################"
   echo "#######################"
   (( currentCpu <= endCpu )) || break
done

