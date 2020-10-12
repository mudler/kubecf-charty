#!/bin/bash

source funcs.sh
set -ex
{{- if .Values.ingress }}
cat <<EOF >>nginx_ingress.yaml
tcp:
  2222: "kubecf/scheduler:2222"
  20000: "kubecf/tcp-router:20000"
  20001: "kubecf/tcp-router:20001"
  20002: "kubecf/tcp-router:20002"
  20003: "kubecf/tcp-router:20003"
  20004: "kubecf/tcp-router:20004"
  20005: "kubecf/tcp-router:20005"
  20006: "kubecf/tcp-router:20006"
  20007: "kubecf/tcp-router:20007"
  20008: "kubecf/tcp-router:20008"
EOF

kubectl create namespace nginx-ingress

helm install nginx-ingress suse/nginx-ingress \
--namespace nginx-ingress \
--values nginx_ingress.yaml

{{- end }}

git clone --recurse-submodules https://github.com/cloudfoundry-incubator/kubecf

cd kubecf

git checkout "{{.Values.kubecf.from}}" -b build
git submodule update --init --recursive --depth 1

{{- if not .Values.cap.enabled }}
make kubecf-bundle

CHART="output/kubecf-bundle-$(./scripts/version.sh).tgz"

tar -xvf $CHART -C ./ > /dev/null
{{- else }}
helm repo add suse https://kubernetes-charts.suse.com/
helm repo update
{{- end }}

kubectl create namespace {{.Values.namespaces.quarksoperator}}

helm install cf-operator --namespace {{.Values.namespaces.quarksoperator}} \
{{- if not .Values.cap.enabled -}} ./cf-operator.tgz {{- else -}} --devel --version {{.Values.cap.quarks.from.version}}  {{.Values.cap.quarks.from.chart}} {{- end }} \
{{- if eq .Values.cap.kubecf.from.version "2.2.3" -}} --set "global.operator.watchNamespace={{.Values.namespaces.kubecf}}" {{- else -}} --set "global.singleNamespace.name={{.Values.namespaces.kubecf}}" {{- end }}

./scripts/cf-operator-wait.sh

{{- if .Values.ingress }}
kubectl apply -f ../certs.yaml
{{- end }}

helm install kubecf --namespace {{.Values.namespaces.kubecf}} {{- if not .Values.cap.enabled }} ./kubecf_release.tgz {{- else }} --devel --version {{.Values.cap.kubecf.from.version}}  {{.Values.cap.kubecf.from.chart}} {{- end }}  --values ../values.yaml

# The following is just ./scripts/kubecf-wait.sh but with increased number of retrials to fit HA deployment times.
source scripts/include/setup.sh

require_tools kubectl retry

green "Waiting for the BOSHDeployment to exist"
RETRIES=130 DELAY=5 retry get_resource BOSHDeployment/kubecf

green "Waiting for all deployments to be available"
RETRIES=160 DELAY=5 retry check_resource_count deployments
mapfile -t deployments < <(get_resource deployments)
RETRIES=160 DELAY=5 wait_for_condition condition=Available "${deployments[@]}"

wait_ns {{.Values.namespaces.kubecf}}