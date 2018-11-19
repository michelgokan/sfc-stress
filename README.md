# Endpoints:
* /cpu for CPU intensive workloads
* /mem for memory intensive workloads
* /disk for disk intensive workloads
* /net for network intensive workloads
* /x for combined workloads


## CPU Intensive Workload: 
Generates 10,000 MD5 Checksums plus a Diffie-Hellman key!

## Memory Intensive Workload: 
Stores 1MB of data in the Memory and then release it after a while!
## Disk Intensive Workload: 
Writes 1MB of data in the disk and then deletes it!
## Network Intensive Workload: 
Send 1 MB of data to via network (HTTP)!
## Combined Workload: 
Run all workloads mentioned above once!

# Installation on Kubernetes
Simply use `kubectl apply -f synthetic-workload-generator.yaml` and access via `http://<your_nginx_address>/workload/`
