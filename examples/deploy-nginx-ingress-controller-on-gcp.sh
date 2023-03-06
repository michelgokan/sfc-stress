#!/bin/bash
# Check https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.6.4/deploy/static/provider/cloud/deploy.yaml

export NGINX_INGRESS_IP=$(kubectl get service ingress-nginx-controller --namespace=ingress-nginx -ojson | jq -r '.status.loadBalancer.ingress[].ip')

gcloud compute addresses create web-ip --addresses $NGINX_INGRESS_IP --region europe-west1

kubectl patch svc ingress-nginx-controller --namespace=ingress-nginx -p "{\"spec\": {\"loadBalancerIP\": \"$NGINX_INGRESS_IP\"}}"

gcloud dns --project=intrepid-app-379207 managed-zones create perfsim --description="" --dns-name="perfsim.com." --visibility="public" --dnssec-state="off"

gcloud dns --project=intrepid-app-379207 record-sets create sfc-stress.perfsim.com. --zone="perfsim" --type="A" --ttl="300" --rrdatas="35.186.254.131"

gcloud dns --project=intrepid-app-379207 record-sets create sfc-stress.perfsim.com. --zone="perfsim" --type="CNAME" --ttl="300" --rrdatas="perfsim.com."

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml

kubectl apply -f issuer-lets-encrypt.yaml

kubectl apply -f web-ssl-secret.yaml
