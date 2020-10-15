#!/bin/bash

source funcs.sh
set -ex

prepare_kubecf "{{.Values.kubecf.from}}"

kubectl create namespace {{.Values.namespaces.quarksoperator}}

helm install cf-operator --namespace {{.Values.namespaces.quarksoperator}} \
	{{- if not .Values.cap.enabled -}} ./cf-operator.tgz {{- else -}} --devel --version {{.Values.cap.quarks.from.version}} {{.Values.cap.quarks.from.chart}} {{- end }} \
	{{- if eq .Values.cap.kubecf.from.version "2.2.3" -}} --set "global.operator.watchNamespace={{.Values.namespaces.kubecf}}" {{- else -}} --set "global.singleNamespace.name={{.Values.namespaces.kubecf}}" {{- end }}

./scripts/cf-operator-wait.sh
