#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"
if [ $# -ne 2 ]
  then
    echo "Please enter service name (first argument) and then namespace (second argument)"
    exit 0
fi

# Read config file
source <(grep = <(grep -A5 '\[general\]' $ROOTPATH/examples/utils/config.ini))
source <(grep = <(grep -A5 '\[root-password-for-ssh\]' $ROOTPATH/examples/utils/config.ini))

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

echo "$podName is placed on $podNodeName with address $podNodeIP..."
echo "It has 2 containers with image ID $mainContainerID and $pauseContainerID..."
echo "The PID of the first pod is $mainContainerPID and the second one is $pauseContainerPID..."

# Network Part 
echo "Entre the path of the workload that you want to initiate traffic (e.g. s1/cpu/1/1/1): "
read path
fullPath="$baseURL$path"
echo "Sending a single request to " $fullPath
epochTime=$(date +%s%3N)
perfLogPath="/tmp/trace-$epochTime-$podName.log"
echo "Running perf stat --per-thread -e instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,duration_time -p \$(pgrep --ns $mainContainerPID | paste -s -d \",\"),\$(pgrep --ns $pauseContainerPID | paste -s -d \",\") -o $perfLogPath"
perfPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET root@${podNodeIP} "screen -S $epochTime-$podName  -d -m perf stat --per-thread -e instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,duration_time -p \$(pgrep --ns $mainContainerPID | paste -s -d \",\"),\$(pgrep --ns $pauseContainerPID | paste -s -d \",\") -o $perfLogPath
perl -e \"select(undef,undef,undef,0.01);\"
screenPID=\$(screen -ls | awk '/\\.$epochTime-$podName\\t/ {printf(\"%d\", strtonum(\$1))}')
pgrep -P \$screenPID perf" | sed 's/[^0-9]*//g' | tr -d '\n')
curl $fullPath
echo ""
perfLog=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "(
 perl -e \"select(undef,undef,undef,0.01);\"
 kill -INT $perfPID
 perl -e \"select(undef,undef,undef,0.01);\"
 cat $perfLogPath
)")
echo "$perfLog"
