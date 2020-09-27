#!/bin/bash

ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

end=1900
step=100
current=300
repetitionCount=5

latencies="[
   "
while : ; do
   latencies="$latencies[["
   for ((i=1;i<=$repetitionCount;i++))
     do
       latencies="$latencies$(cat $ROOTPATH/logs/latency-cpu-$i-$current.log),"
   done
   latencies="${latencies::-1}]],
   "
   current=$((current+step))
   (( current <= end )) || break
done
latencies="${latencies::-5}
]"

echo "$latencies" | tail -n +1
