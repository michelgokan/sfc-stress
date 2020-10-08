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


$ROOTPATH/utils/kubernetes/assign-guaranteed-cpu-limit.sh $1 $2 "1"

for ((i=1;i<=$repetitionCount;i++))
  do
   echo "Starting iteration $i"
   startThread=1
   endThread=200
   stepThread=10
   currentThread=1
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
      echo "Wait 10 seconds..."
      sleep 10
      echo "#######################"
      echo ""
      podInfo=$(kubectl describe pod -n "$2" -l=name=$1)
      podName=$(echo "$podInfo" | grep "^Name:" | awk "{print \$2}")
      echo "Running $ROOTPATH/utils/get-perf-stats-while-running.sh $1 $2 $3/$currentThread thread-${i}-${currentThread} on pod $podName"
      $ROOTPATH/utils/get-perf-stats-while-running.sh $1 $2 $3/$currentThread thread-${i}-${currentThread} > $ROOTPATH/logs/getPerfStatsWhileRunningOutput-thread-${i}-${currentThread}.log
      currentThread=$((currentThread+stepThread))
      kubectl delete pod --namespace $2 $podName
      echo "#######################"
      echo "#######################"
      (( currentThread <= endThread )) || break
   done
done
