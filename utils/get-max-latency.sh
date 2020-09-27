#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"

if [ $# -ne 2 ]
  then
    echo "Please enter number of threads and CPU size that you want to obtain max latency..."
    exit 0
fi
count=$1
max=0
for ((i=1;i<=$count;i++))
  do
    echo "Getting latency of $i-cpu-$2"
    latency=$(cat $ROOTPATH/logs/latency-multithread-eval-$i-cpu-$2.log)
    if (( "$latency" > "$max" )); then
       max=$latency
    fi
  done
echo "$max"
