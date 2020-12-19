#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"

if [ $# -ne 5 ]
  then
    echo "Please enter arrival rate (first argument), duration (second argument), batch size (thirs argument), path of the workload that you want to initiate traffic (e.g. s1/cpu/1/1/1 as forth argument), and suffix for saving logs (fifth argument)."
    exit 0
fi
arrival_rate=$1
duration=$2
batch_size=$3
_path=$4
suffix=$5
_url=http://172.16.16.111:30553/$_path

total_requests=$(($1*$2))
wait_time=$(printf '%.5f\n' "$(echo "scale=4;1/$1" | bc)")

echo "Total requests: $total_requests"
echo "Wait time: $wait_time"
echo "Address: $_url"
#echo "Ready?"

#read -r

for ((i=0;i<$total_requests;i++)) 
do 
   for ((j=0;j<$batch_size;j++)) 
   do 
      curl --silent -w "@curl-format2.txt" http://172.16.16.111:30553/$_path -o $ROOTPATH/logs/loadtesting_${suffix}_${i}_${j}.log > $ROOTPATH/logs/loadtesting_latency_${suffix}_${i}_${j}.log &
      pids[$((i+j))]=$!
   done
   sleep "$wait_time"
   echo "$i"
done

echo "Waiting for curl pids to finish..."

for pid in ${pids[*]}; do
   wait $pid
done

echo "Done!"
