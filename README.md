# Introduction to Synthetic Service Mesh
Synthetic Service Mesh is a customizable, multi-threaded, and Docker/Kubernetes based synthetic workload that is used to generate different types of service meshes with various types of workloads. It can be used to emulate any type of service chains in a cluster and can be easily deployed in Kubernetes or Docker Swarm environments. For example, you can generate a service chain like below (this is just an example, you can design your own service chain):    

![Image of a service chain](./images/service_chain.png)

You can use yaml files inside the `example` folder to generate service mesh above (or use them as an example for your own custom service mesh). To start the traffic, you should send a GET request/call /s1/cpu/1/1/1. It will then send a single request to s1 and then s1 send the traffic to s2, s2 to s3 and s7 and so on.

# Endpoints:
* */cpu/:workloadSize?/:threadsCount?/:sendToNext? for CPU intensive workloads
* */mem/:dataSize?/:threadsCount?/:sendToNext? for memory intensive workloads
* */blkio/:fileSize?/:threadsCount?/:sendToNext? for disk intensive workloads
* */net/:payloadSize?/:isPromised? for network intensive workloads
* */x/:sendToNext?/:isPromised? for combined workloads


## CPU Intensive Workload: 
Generates <workloadSize> number of Diffie-Hellman keys and calculates their MD5 checksums! It then calls the NetworkIntensiveWorload with zero payload if sendToNext parameter is true.
## Memory Intensive Workload: 
Stores and release <dataSize>MB of data in the memory as a variable! It then calls the NetworkIntensiveWorload with zero payload if sendToNext parameter is true.
## Disk Intensive Workload: 
Writes <fileSize>MB of data in the disk and then deletes it! It then calls the NetworkIntensiveWorload with zero payload if sendToNext parameter is true.
## Network Intensive Workload:
Send <payloadSize>MB of data over network (POST HTTP) to N number of destinations specified in a comma separated environment variable NEXT_SERVICES_ADDRESSES!
It comes in 2 types:
 
1. **Normal mode:** Send request and exit!
2. **Promised mode:** Send request, wait for the response, and then exit!

To enable promised-mode, pass 1 to isPromised parameter in */net or */x.

## Combined Workload: 
Run all workloads mentioned above once!

# Installation on Kubernetes
Simply use `kubectl apply -f synthetic-service-mesh.yaml` and access via `http://<your_nginx_address>/workload/`. Make sure to set NEXT_SERVICES_ADDRESSES environment variable in the yaml file for the network intensive workload and/or for properly forming your service mesh graph.
