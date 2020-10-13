#!/bin/bash
set -ex
source funcs.sh

git clone --recurse-submodules https://github.com/cloudfoundry-incubator/kubecf

cd kubecf
source scripts/include/setup.sh

git checkout "{{.Values.kubecf.checkout}}" -b build
git submodule update --init --recursive --depth 1

{{- if not .Values.cap.enabled }}
make kubecf-bundle

CHART="output/kubecf-bundle-$(./scripts/version.sh).tgz"

tar -xvf $CHART -C ./ >/dev/null
{{- else }}
helm repo add suse https://kubernetes-charts.suse.com/
helm repo update
{{- end }}

kubectl create namespace {{.Values.namespaces.quarksoperator}}

helm install cf-operator --namespace {{.Values.namespaces.quarksoperator}} {{- if not .Values.cap.enabled }} ./cf-operator.tgz {{- else }} --devel --version {{.Values.cap.quarks.version}} {{.Values.cap.quarks.chart}} {{- end }} --set "global.singleNamespace.name={{.Values.namespaces.kubecf}}"

./scripts/cf-operator-wait.sh

helm install kubecf --namespace {{.Values.namespaces.kubecf}} {{- if not .Values.cap.enabled }} ./kubecf_release.tgz {{- else }} --devel --version {{.Values.cap.kubecf.version}} {{.Values.cap.kubecf.chart}} {{- end }} --values ../values.yaml

# The following is just ./scripts/kubecf-wait.sh but with increased number of retrials to fit HA deployment times.

require_tools kubectl retry

green "Waiting for the BOSHDeployment to exist"
RETRIES=130 DELAY=5 retry get_resource BOSHDeployment/kubecf

green "Waiting for the quarks jobs to be done"
RETRIES=380 DELAY=10 retry check_qjob_ready ig

green "Waiting for all deployments to be available"

RETRIES=160 DELAY=5 retry check_resource_count deployments
mapfile -t deployments < <(get_resource deployments)
RETRIES=160 DELAY=5 wait_for_condition condition=Available "${deployments[@]}"

wait_ns {{.Values.namespaces.kubecf}}
