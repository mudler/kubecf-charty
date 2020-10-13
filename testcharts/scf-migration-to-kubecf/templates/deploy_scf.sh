#!/bin/bash

source funcs.sh
set -ex

helm repo add suse https://kubernetes-charts.suse.com/
helm repo update

kubectl create namespace {{.Values.namespaces.scf}}
helm install scf --namespace {{.Values.namespaces.scf}} --devel --version {{.Values.cap.scf.version}}  {{.Values.cap.scf.chart}} --values scf.yaml
sleep 10
wait_ns {{.Values.namespaces.scf}}
