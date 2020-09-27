#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

if [ $# -ne 4 ]
  then
    echo "Please enter service name (first argument), namespace (second argument), path to test (third argument) and number of repetitions (forth argument)."
    exit 0
fi

pathToTest=$3
repetitionCount=$(($4))

mkdir $ROOTPATH/logs



for ((i=1;i<=$repetitionCount;i++))
  do
   echo "Starting iteration $i"
   startCpu=300
   endCpu=1900
   stepCpu=100
   currentCpu=300
   sleep 5
   if [ "$currentCpu" -eq "0" ]; then
      $ROOTPATH/utils/kubernetes/delete-resource-specs.sh $1 $2
   else
      $ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh $1 $2 "${currentCpu}m"
   fi
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
      echo ""
      echo "Running $ROOTPATH/utils/get-perf-stats-while-running.sh $1 $2 $3 cpu-${i}-${currentCpu}"
      $ROOTPATH/utils/get-perf-stats-while-running.sh $1 $2 $3 cpu-${i}-${currentCpu}
      currentCpu=$((currentCpu+stepCpu))
      $ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh $1 $2 "${currentCpu}m"
      echo "#######################"
      echo "#######################"
      (( currentCpu <= endCpu )) || break
   done
done
