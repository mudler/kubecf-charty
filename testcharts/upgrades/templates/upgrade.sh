#!/bin/bash

source funcs.sh
set -ex
cd kubecf

git checkout "{{.Values.kubecf.to}}" -b upgrade
git submodule update --init --recursive --depth 1

{{- if not .Values.cap.enabled }}
make kubecf-bundle

CHART="output/kubecf-bundle-$(./scripts/version.sh).tgz"

tar -xvf $CHART -C ./ > /dev/null
{{- else }}
helm repo add suse https://kubernetes-charts.suse.com/
helm repo update
{{- end }}

helm ugrade cf-operator --namespace {{.Values.namespaces.quarksoperator}} \
{{- if not .Values.cap.enabled }} ./cf-operator.tgz {{- else }} --devel --version {{.Values.cap.quarks.to.version}}  {{.Values.cap.quarks.to.chart}} {{- end }} \
 --set "global.singleNamespace.name={{.Values.namespaces.kubecf}}"

sleep 30
./scripts/cf-operator-wait.sh

helm upgrade kubecf --namespace {{.Values.namespaces.kubecf}} {{- if not .Values.cap.enabled }} ./kubecf_release.tgz {{- else }} --devel --version {{.Values.cap.kubecf.to.version}}  {{.Values.cap.kubecf.to.chart}} {{- end }}  --values ../values.yaml

sleep 120
# The following is just ./scripts/kubecf-wait.sh but with increased number of retrials to fit HA deployment times.

require_tools kubectl retry

green "Waiting for the BOSHDeployment to exist"
RETRIES=130 DELAY=5 retry get_resource BOSHDeployment/kubecf

green "Waiting for all deployments to be available"
RETRIES=160 DELAY=5 retry check_resource_count deployments
mapfile -t deployments < <(get_resource deployments)
RETRIES=160 DELAY=5 wait_for_condition condition=Available "${deployments[@]}"

wait_ns {{.Values.namespaces.kubecf}}