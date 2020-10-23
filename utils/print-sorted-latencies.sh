#!/bin/bash

ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

end=1900
step=100
current=0
repetitionCount=5

latencies="[
   "
while : ; do
   latencies="$latencies[["
   for ((i=1;i<=$repetitionCount;i++))
     do
        _latency=$(cat $ROOTPATH/logs/latency-cpu-$i-$current.log)

        if ! [[ $_latency =~ ^[0-9].* ]]; then
           _latency=0
        fi
        latencies="$latencies$_latency,"
   done
   latencies="${latencies::-1}]],
   "
   current=$((current+step))
   (( current <= end )) || break
done
latencies="${latencies::-5}
]"

echo "$latencies" | tail -n +1
