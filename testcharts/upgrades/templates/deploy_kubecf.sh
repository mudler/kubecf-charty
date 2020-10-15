#!/bin/bash

source funcs.sh
set -ex

cd kubecf

{{- if .Values.ingress }}
kubectl apply -f ../certs.yaml
{{- end }}

helm install kubecf --namespace {{.Values.namespaces.kubecf}} {{- if not .Values.cap.enabled }} ./kubecf_release.tgz {{- else }} --devel --version {{.Values.cap.kubecf.from.version}} {{.Values.cap.kubecf.from.chart}} {{- end }} --values ../values.yaml

wait_kubecf
