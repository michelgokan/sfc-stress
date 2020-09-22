#!/bin/bash
rm /tmp/runqueues.log
touch /tmp/runqueues.log

while true; do
   epoch_time=$(date +%s%3N)
   ps -mo pid,tid,%cpu,psr -p $1 | tail -n +3 | awk "{print \"$epoch_time \" \$2 \" \" \$4}" >> /tmp/runqueues.log
   sleep 0.1
done

