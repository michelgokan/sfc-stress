#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"
if [ $# -ne 2 ]
  then
    echo "Please enter number of threads (first arg) and log file suffix (second arg)..."
    exit 0
fi
mkdir $ROOTPATH/logs
count=$(($1))
suffix=$2
echo "Creating screens..."

for ((i=1;i<=$count;i++))
  do
     screen -S s1-$i -d -m ./get-perf-stats-while-running.sh s1-$i ingress-nginx s1-$i/cpu/100 multithread-eval-$i-$suffix
  done

echo "Sleeping for 10 seconds..."
sleep 20

echo "Start traffic and perf on all threads..."

for ((i=1;i<=$count;i++))
  do
    screen -S s1-$i -p 0 -X stuff "\n"
  done

v="$(screen -ls | grep -i detached | wc -l)"
echo "$v"
while true
do
   if [ "$v" -ne "0" ]; then
      echo "Wait, $v screens remaining..."
      v="$(screen -ls | grep -i detached | wc -l)"
      sleep 1
   else
      echo "Done!"
      break
   fi
done
