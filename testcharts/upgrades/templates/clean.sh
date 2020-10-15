#!/bin/bash
set -ex

{{- if or .Values.eirini .Values.settings.switch_upgrade }}
kubectl delete namespace {{.Values.namespaces.eirini}} || true
{{- end }}

kubectl delete namespace {{.Values.namespaces.kubecf}} || true
kubectl delete namespace {{.Values.namespaces.quarksoperator}} || true

{{- if .Values.ingress }}
kubectl delete namespace nginx-ingress || true
{{- end }}
