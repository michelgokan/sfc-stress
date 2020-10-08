#!/bin/bash
kubectl logs -l name=$1 --all-containers --namespace ingress-nginx --tail=$2 --timestamps

