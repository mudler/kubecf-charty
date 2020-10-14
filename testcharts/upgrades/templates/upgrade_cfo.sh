#!/bin/bash

source funcs.sh
set -ex

prepare_kubecf "{{.Values.kubecf.to}}"

helm upgrade cf-operator --namespace {{.Values.namespaces.quarksoperator}} \
{{- if not .Values.cap.enabled -}} ./cf-operator.tgz {{- else -}} --devel --version {{.Values.cap.quarks.to.version}}  {{.Values.cap.quarks.to.chart}} {{- end }} \
 --set "global.singleNamespace.name={{.Values.namespaces.kubecf}}"

sleep {{.Values.settings.grace_sleep_time}}
./scripts/cf-operator-wait.sh

wait_ns {{.Values.namespaces.kubecf}}