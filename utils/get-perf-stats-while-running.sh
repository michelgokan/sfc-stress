#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd -P )"
if [ $# -ne 4 ]
  then
    echo "Please enter service name (first argument), namespace (second argument), path of the workload that you want to initiate traffic (e.g. s1/cpu/1/1/1), and finally a suffix for .log files (forth argument)."
    exit 0
fi
mkdir $ROOTPATH/logs

# Read config file
source <(grep = <(grep -A5 '\[general\]' $ROOTPATH/utils/config.ini))
source <(grep = <(grep -A5 '\[root-password-for-ssh\]' $ROOTPATH/utils/config.ini))

deploymentName=$1
deploymentNamespace=$2
podInfo=$(kubectl describe pod -n "$deploymentNamespace" -l=name=$deploymentName)
podName=$(echo "$podInfo" | grep "^Name:" | awk "{print \$2}")
podNode=$(echo "$podInfo" | grep "^Node:" | awk "{print \$2}")
podNodeDetails=(${podNode//\// })
podNodeName=${podNodeDetails[0]}
podNodeIP=${podNodeDetails[1]}
podNodePass="${!podNodeName}"
dockerPSInPodNode=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} 'docker ps')
podsContainers=$(echo "$dockerPSInPodNode" | grep "$podName")
mainContainerID=$(echo "$podsContainers" | sed '1q;d' | awk "{print \$1}")
pauseContainerID=$(echo "$podsContainers" | sed '2q;d' | awk "{print \$1}")
mainContainerPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "docker inspect -f '{{.State.Pid}}' $mainContainerID" | sed 's/[^0-9]*//g')
pauseContainerPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "docker inspect -f '{{.State.Pid}}' $pauseContainerID" | sed 's/[^0-9]*//g')
logFileOfMainContainer=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "echo \"/var/lib/docker/containers/\$(docker inspect $mainContainerID | jq .[0].Id -r)/\$(docker inspect $mainContainerID | jq .[0].Id -r)-json.log\"" | sed 's/[^a-zA-Z0-9\/\.\-]*//g')

echo "$podName is placed on $podNodeName with address $podNodeIP..."
echo "It has 2 containers with image ID $mainContainerID and $pauseContainerID..."
echo "The PID of the first pod is $mainContainerPID and the second one is $pauseContainerPID..."
echo "Main container's log file path = " "$logFileOfMainContainer"
# Network Part 
path=$3
fullPath="$baseURL$path"
echo "Sending a single request to " $fullPath
epochTime=$(date +%s%3N)
perfLogPath="/tmp/trace-$epochTime-$podName.log"
pidstatLogPath="/tmp/pidstat-$epochTime-$podName.log"
pmapLogPath="/tmp/pmap-$epochTime-$podName.log"
echo "Transfering thread-place-on-runqueues.sh to $podNodeName:/tmp ..."
pgrepPiece="\$(pgrep --ns $mainContainerPID | paste -s -d ','),\$(pgrep --ns $pauseContainerPID | paste -s -d ',')"
pgrepPieceWithSpace=$(echo "$pgrepPiece" | sed 's|,| |g' | sed 's|\$|\\\$|g')
threadPlacementCmd="/tmp/thread-place-on-runqueues.sh $pgrepPiece"
pmapCmd="#!/bin/bash
watch -n 0.1 echo \"\\\$(pmap $pgrepPieceWithSpace | grep total | sed 's|[a-zA-Z]||g' | awk '{sum+=\\\$1} END{print sum}')\" '>>' $pmapLogPath"
echo "$pmapCmd" > $ROOTPATH/pmap.sh
sshpass -p ${podNodePass} scp $ROOTPATH/pmap.sh $ROOTPATH/utils/thread-place-on-runqueues.sh root@${podNodeIP}:/tmp
rm $ROOTPATH/pmap.sh
eventsToCollect="instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,cache-references,branch-load-misses,branch-loads,dTLB-load-misses,dTLB-loads,dTLB-store-misses,dTLB-stores,iTLB-load-misses,iTLB-loads,node-load-misses,node-loads,node-store-misses,node-stores,duration_time,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetch-misses,L1-dcache-loads,L1-dcache-load-misses,L1-dcache-stores,L1-icache-load-misses,L1-icache-prefetches,L1-icache-prefetch-misses,L1-dcache-prefetches,L1-dcache-prefetch-misses,cpu/mem-stores/u,r81d0:u,r82d0:u"
perfStatCmd="perf stat --per-thread -e $eventsToCollect -p $pgrepPiece -o $perfLogPath"
perfRecordCmd=""
pidstatCmd="pidstat -dru -hlHr -p $pgrepPiece 1 > $pidstatLogPath" #add -t for per-thread stats
pidstatKillCmd="sleep 2 && screen -XS $epochTime-pidstat-$podName quit && screen -XS $epochTime-kill-pidstat-$podName quit"

echo ""
echo "Running $threadPlacementCmd"
echo ""
echo ""
echo "Running $perfStatCmd"
echo ""
echo ""
echo "Running $pidstatCmd"
echo ""
echo ""
echo "Running $pmapCmd"
echo ""

perfPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET root@${podNodeIP} "
chmod +x /tmp/pmap.sh
screen -S $epochTime-threadMonitor-$podName  -d -m $threadPlacementCmd
screen -S $epochTime-pmap-$podName  -d -m /tmp/pmap.sh
screen -S $epochTime-pidstat-$podName -d -m bash -c \"$pidstatCmd\"
screen -S $epochTime-$podName  -d -m $perfStatCmd
perl -e \"select(undef,undef,undef,0.01);\"
screenPID=\$(screen -ls | awk '/\\.$epochTime-$podName\\t/ {printf(\"%d\", strtonum(\$1))}')
pgrep -P \$screenPID perf" | sed 's/[^0-9]*//g' | tr -d '\n')
echo ""
echo "perfPID=$perfPID"
echo ""

curl $fullPath > $ROOTPATH/logs/curlOutput-$4.log 
echo "$pidstatKillCmd"
perfLog=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "(
 screen -XS $epochTime-threadMonitor-$podName quit
 screen -XS $epochTime-pmap-$podName quit
 screen -S $epochTime-kill-pidstat-$podName -d -m bash -c \"$pidstatKillCmd\"
 kill -INT $perfPID
 sleep 0.2
 cat $perfLogPath
 rm -Rf $perfLogPath
)")
echo "$perfLog"

echo ""
echo "Running $pidstatKillCmd"
echo ""

pidstatLog=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "(
 sleep 2
 cat $pidstatLogPath
 rm -Rf $pidstatLogPath
)")


pmapLog=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "(
 cat $pmapLogPath
 rm -Rf $pmapLogPath
)")

##### Processing logs
IFS=',' read -r -a array <<< "$eventsToCollect"

#sorts based on thread name
#output is like <tid>,<value>
function getCSV {
   echo "$1" | tr -d , | awk '{ if ($2 ~ /^[0-9,\t*\s*]*$/) {print $1 "," $2} else {print $1 "," 0} }' | sort -n -t ',' -k1
}


dummyLines=$(echo "$perfLog" | grep "instructions") 
processesList=$(getCSV "$dummyLines" |  awk -F',' '{print $1}')

csvData="$processesList"
for element in "${array[@]}"
do
   lines=$(echo "$perfLog" | grep -i "$element")
   linesToCSV=$(getCSV "$lines" | awk -F',' '{print $2}')
   csvData=$(paste -d, <(echo "$csvData") <(echo "$linesToCSV"))
done

threadsCount=$(echo "$data" | wc -l)
csvData=$(paste -d, <(echo "$processedList") <(echo "$csvData"))
csvData=$(echo "tid,$eventsToCollect" && echo "$csvData")

echo "$csvData" | sed 's/^,//' > $ROOTPATH/logs/perfLogs-$4.log
cat $ROOTPATH/logs/perfLogs-$4.log | awk '
function calculate_cache_miss_rate(cache_misses, cache_references){
   if (cache_references != 0) {miss_rate = cache_misses/cache_references;}
   else {miss_rate = 0;}
   return miss_rate;
}
BEGIN {FS=OFS=","}
NR == 1 {for (i=1; i<=NF; i++) {
   if ($i == "cache-misses") cache_misses_index=i;
   if ($i == "cache-references") cache_references_index=i;
   }
   print $0",miss-ratio"}
NR > 1 {for (i=2; i<=NF; i++) {sum[i]+=$i;} 
   len=NF;
   print $0","calculate_cache_miss_rate($cache_misses_index, $cache_references_index)};
END {$1="sum"; for (i=2; i<=len; i++) {$i=sum[i];} 
     print $0","calculate_cache_miss_rate($cache_misses_index, $cache_references_index);}
' > $ROOTPATH/logs/perfLogsProcessed-$4.csv
podRawLogs=$(kubectl logs $podName -n $deploymentNamespace)
echo "$podRawLogs" > $ROOTPATH/logs/podRawLogs-$4.log
echo "$podRawLogs" | tail -1 | tr -d , | awk '{print $9*1000000}' > $ROOTPATH/logs/latency-$4.log
echo "$pidstatLog" > $ROOTPATH/logs/pidstatRawLog-$4.log
echo "$pmapLog" > $ROOTPATH/logs/pmapLog-$4.log

echo ""
echo "Transfering $root@${podNodeIP}:/tmp/runqueues.log to $ROOTPATH/utils/ ..."
sshpass -p ${podNodePass} rsync -avz --remove-source-files -e ssh root@${podNodeIP}:/tmp/runqueues.log $ROOTPATH/logs/
mv $ROOTPATH/logs/runqueues.log $ROOTPATH/logs/runqueues-$4.log 

echo "$perfLog" > $ROOTPATH/logs/perfRawLogs-$4.log
