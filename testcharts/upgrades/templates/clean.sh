#!/bin/bash
set -ex

{{- if .Values.eirini }}
kubectl delete namespace {{.Values.namespaces.eirini}} || true
{{- end }}

kubectl delete namespace {{.Values.namespaces.kubecf}} || true
kubectl delete namespace {{.Values.namespaces.quarksoperator}} || true
kubectl delete namespace kubecf-mysql || true

{{- if .Values.ingress }}
kubectl delete namespace nginx-ingress || true
{{- end }}