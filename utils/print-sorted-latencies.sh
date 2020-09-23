#!/bin/bash

ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

end=1900
current=0
step=100
latencies=""

while : ; do
   latencies="$(echo "$latencies")
$current,$(cat $ROOTPATH/logs/latency-cpu-$current.log)"

   current=$((current+step))
   (( current <= end )) || break
done
echo "$latencies" | tail -n +1
