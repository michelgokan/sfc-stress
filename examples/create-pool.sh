#!/bin/bash

gcloud container node-pools create pool-1 --cluster=cluster-1 --num-nodes=1 --zone="europe-west1" --disk-size=10GB --disk-type=pd-ssd  --machine-type "e2-standard-2" --num-nodes=1 --enable-autoupgrade --enable-autorepair --scopes=https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/sqlservice.admin,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/monitoring
