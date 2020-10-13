#!/bin/bash
set -ex

if [ -z "$KUBECONFIG" ]; then
    echo "Kubeconfig required!"
    exit 1
fi


{ 

{{- if .Values.eirini }}
kubectl delete namespace {{.Values.namespaces.eirini}} || true
{{- end }}
kubectl delete namespace {{.Values.namespaces.scf}} || true
kubectl delete namespace uaa || true

kubectl delete namespace {{.Values.namespaces.kubecf}} || true
kubectl delete namespace {{.Values.namespaces.quarksoperator}} || true

{{- if .Values.ingress }}
kubectl delete namespace nginx-ingress || true
{{- end }}

} >/dev/null 2>&1