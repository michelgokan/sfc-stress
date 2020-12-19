#!/bin/bash

ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"

if [ $# -ne 5 ]
  then
    echo "Please enter arrival rate (first argument), duration (second argument), batch size (thirs argument), and suffix for saving logs (forth argument)."
    exit 0
fi
arrival_rate=$1
duration=$2
batch_size=$3
suffix=$4
total_requests=$(($1*$2))

current=0

latencies="[
   "
for ((i=0;i<$total_requests;i++)) 
do 
   for ((j=0;j<$batch_size;j++)) 
   do 
   
      _latency=$(cat $ROOTPATH/logs/loadtesting_latency-cpu-${suffix}_${i}_${j}.log)

      #if ! [[ $_latency =~ ^[0-9].* ]]; then
      #     _latency=0
      #fi
      latencies="$latencies$_latency,"
   done
   latencies="${latencies::-1}]],
   "
done
#latencies="${latencies::-5}
#]"

echo "$latencies" | tail -n +1
