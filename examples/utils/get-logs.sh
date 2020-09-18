#!/bin/bash

services=8

for s in $(seq 1 $services)
do
   echo "=========================="
   echo "Service $s"
   kubectl logs -l app=s$s --all-containers --namespace ingress-nginx --tail=999999999 --timestamps
   echo "**************************"
done
