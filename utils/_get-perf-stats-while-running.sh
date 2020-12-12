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
echo "Transfering thread-place-on-runqueues.sh to $podNodeName:/tmp ..."
sshpass -p ${podNodePass} scp $ROOTPATH/utils/thread-place-on-runqueues.sh root@${podNodeIP}:/tmp

pgrepPiece="\$(pgrep --ns $mainContainerPID | paste -s -d \",\"),\$(pgrep --ns $pauseContainerPID | paste -s -d \",\")"
threadPlacementCmd="/tmp/thread-place-on-runqueues.sh $pgrepPiece"
perfStatCmd="perf stat --per-thread -e instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,duration_time -p $pgrepPiece -o $perfLogPath"
perfRecordCmd=""

echo "Running $threadPlacementCmd"

sshpass -p ${podNodePass} ssh -o LogLevel=QUIET root@${podNodeIP} "screen -S $epochTime-threadMonitor-$podName  -d -m $threadPlacementCmd"

echo "Running $perfStatCmd"
curl $fullPath &

perfPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET root@${podNodeIP} "while read line;do
    case \"\$line\" in
        *\"START PERF\"* )
            screen -S $epochTime-$podName  -d -m $perfStatCmd
            perl -e \"select(undef,undef,undef,0.01);\"
            screenPID=\$(screen -ls | awk '/\\.$epochTime-$podName\\t/ {printf(\"%d\", strtonum(\$1))}')
            pgrep -P \$screenPID perf
            exit 0
            ;;
    esac
  done < <(tail -f $logFileOfMainContainer -n 0)" | sed 's/[^0-9]*//g' | tr -d '\n')
echo ""
echo "perfPID=$perfPID"
echo ""
sleep 2
perfLog=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "(
 screen -XS $epochTime-threadMonitor-$podName quit
 perl -e \"select(undef,undef,undef,0.01);\"
 kill -INT $perfPID
 perl -e \"select(undef,undef,undef,0.01);\"
 cat $perfLogPath
 rm -Rf $perfLogPath
)")
echo "$perfLog"

##### Processing logs
threadsCount=$(echo "$instructions" | wc -l)

instructions=$(echo "$perfLog" | grep instructions)
cycles=$(echo "$perfLog" | grep cycles)
cacheMisses=$(echo "$perfLog" | grep cache-misses)
contextSwitches=$(echo "$perfLog" | grep context-switches)
cpuMigrations=$(echo "$perfLog" | grep cpu-migrations)
cpuClock=$(echo "$perfLog" | grep cpu-clock)
taskClock=$(echo "$perfLog" | grep task-clock)
durationTime=$(echo "$perfLog" | grep duration_time)

function getCSV {
   echo "$1" | tr -d , | awk '{ if ($2 ~ /^[0-9,\t*\s*]*$/) {print $1 "," $2} else {print $1 "," 0} }' | sort -n -t ',' -k1
}

processedInsts=$(getCSV "$instructions" | awk -F',' '{print $2}')
processedCycles=$(getCSV "$cycles" | awk -F',' '{print $2}')
processedCacheMisses=$(getCSV "$cacheMisses" | awk -F',' '{print $2}')
processedContextSwitches=$(getCSV "$contextSwitches" | awk -F',' '{print $2}')
processedCpuMigrations=$(getCSV "$cpuMigrations" | awk -F',' '{print $2}')
processedCpuClock=$(getCSV "$cpuClock" | awk -F',' '{print $2}')
processedTaskClock=$(getCSV "$taskClock" | awk -F',' '{print $2}')
processedDurationTime=$(getCSV "$durationTime" | awk -F',' '{print $2}')

processesList=$(getCSV "$instructions" | awk -F',' '{print $1}')

csvData=$(paste -d, <(echo "$processesList") <(echo "$processedInsts") <(echo "$processedCycles") <(echo "$processedCacheMisses") <(echo "$processedContextSwitches") <(echo "$processedCpuMigrations") <(echo "$processedCpuClock") <(echo "$processedTaskClock") <(echo "$processedDurationTime"))
csvData=$(echo "task,insts,cycles,cache-misses,context-switches,cpu-migrations,cpu-clock,task-clock,duration-time" && echo "$csvData")
echo "$csvData" > $ROOTPATH/logs/perfLogs-$4.log
kubectl logs $podName -n $deploymentNamespace | tail -1 | tr -d , | awk '{print $8*1000000}' > $ROOTPATH/logs/latency-$4.log

echo ""
echo "Transfering $root@${podNodeIP}:/tmp/runqueues.log to $ROOTPATH/utils/ ..."
sshpass -p ${podNodePass} rsync -avz --remove-source-files -e ssh root@${podNodeIP}:/tmp/runqueues.log $ROOTPATH/logs/
mv $ROOTPATH/logs/runqueues.log $ROOTPATH/logs/runqueues-$4.log 

echo "$perfLog" > $ROOTPATH/logs/perfRawLogs-$4.log
