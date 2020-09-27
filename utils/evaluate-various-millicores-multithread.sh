#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

if [ $# -ne 1 ]
  then
    echo "Please enter number of threads..."
    exit 0
fi
mkdir $ROOTPATH/logs
count=$(($1))


for ((i=1;i<=$count;i++))
  do
     $ROOTPATH/utils/kubernetes/delete-resource-specs.sh s1-$i ingress-nginx
  done


startCpu=100
endCpu=200
stepCpu=100
currentCpu=0

while : ; do
   echo "Inside while loop"
   v=$($ROOTPATH/utils/kubernetes/are-pods-in-namespace-ready.sh ingress-nginx)
   
   while true
   do
      if [ "$v" -eq "0" ]; then
         echo "Some pods are not ready..."
         echo "Checking pods in ingress-nginx namespace again..."
         v=$($ROOTPATH/utils/kubernetes/are-pods-in-namespace-ready.sh ingress-nginx)
         sleep 1
      else
         echo "All pods in ingress-nginx namespace are ready..."
         break
      fi
   done
   echo "Wait 20 seconds..."
   sleep 20
   echo "#######################"
   echo ""
   echo "Running $ROOTPATH/utils/get-perf-stats-while-running-multithread.sh s1-$i ingress-nginx s1/cpu/100 cpu-${currentCpu}"
   $ROOTPATH/utils/get-perf-stats-while-running-multithread.sh $count cpu-${currentCpu}
   currentCpu=$((currentCpu+stepCpu))
   for ((i=1;i<=$count;i++))
     do
        $ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh s1-$i ingress-nginx "${currentCpu}m"
     done
   echo "#######################"
   echo "Starting next iteration with currentCpu = $currentCpu"
   echo "#######################"
   (( currentCpu <= endCpu )) || break
done

