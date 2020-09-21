#!/bin/bash
# Read config file
source <(grep = <(grep -A5 '\[general\]' config.ini))
source <(grep = <(grep -A5 '\[root-password-for-ssh\]' config.ini))

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
mainPodContainerID=$(echo "$podsContainers" | sed '1q;d' | awk "{print \$1}")
pausePodContainerID=$(echo "$podsContainers" | sed '2q;d' | awk "{print \$1}")
mainPodContainerPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "docker inspect -f '{{.State.Pid}}' $mainPodContainerID" | sed 's/[^0-9]*//g')
pausePodContainerPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "docker inspect -f '{{.State.Pid}}' $pausePodContainerID" | sed 's/[^0-9]*//g')


# Network Part 
echo "Entre the path of the workload that you want to initiate traffic (e.g. s1/cpu/1/1/1): "
read path
fullPath="$baseURL$path"
echo "Sending a single request to " $fullPath
epochTime=$(date +%s%3N)
perfLogPath="/tmp/trace-$epochTime-$podName.log"
echo "Running perf stat --per-thread -e instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,duration_time -p $mainPodContainerPID,$pausePodContainerPID -o $perfLogPath"
perfPID=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET root@${podNodeIP} "screen -S $epochTime-$podName  -d -m perf stat --per-thread -e instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,duration_time -p $mainPodContainerPID,$pausePodContainerPID -o $perfLogPath
perl -e \"select(undef,undef,undef,0.01);\"
screenPID=\$(screen -ls | awk '/\\.$epochTime-$podName\\t/ {printf(\"%d\", strtonum(\$1))}')
pgrep -P \$screenPID perf" | sed 's/[^0-9]*//g' | tr -d '\n')
#echo "$finalPerfCMD"
#perfPID=eval "$finalPerfCMD"
### echo \$!
### )" | sed 's/[^0-9]*//g')
curl $fullPath
echo $perfPID
perfLog=$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "(
 perl -e \"select(undef,undef,undef,0.01);\"
 kill -INT $perfPID
 perl -e \"select(undef,undef,undef,0.01);\"
 cat $perfLogPath
)")
echo "$perfLog"
#$(sshpass -p ${podNodePass} ssh -o LogLevel=QUIET -t root@${podNodeIP} "perf stati --snapshot --per-thread -e instructions,cycles,task-clock,cpu-clock,cpu-migrations,context-switches,cache-misses,duration_time -p $mainPodContainerPID,$pausePodContainerPID" )
#echo $mainPodContainerID
#echo $pausePodContainerID
#echo "$dockerPSInPodNode"
#echo "$podName"
#echo "$podsContainers"
#IFS='
#'
#for pod in $pods
#do
#   echo "$pod"
#done
#  | tail -n 1 | awk "{print \$1 system(\"kubectl describe pod $1 -n $2| grep Node:\")}")
