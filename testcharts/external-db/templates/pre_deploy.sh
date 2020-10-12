#!/bin/bash

echo "Deploying {{- if .Values.cap.enabled }}CAP{{- else }}KubeCF{{- end }}"
echo "Ingress: {{.Values.ingress}}"
echo "HA: {{.Values.ha}}"
{{- if .Values.cap.enabled }}
echo "CAP: KubeCF @ {{.Values.cap.kubecf.version}} - quarks @ {{.Values.cap.quarks.version}}"
{{- else }}
echo "KubeCF: {{.Values.kubecf.checkout}}"
{{- end }}
