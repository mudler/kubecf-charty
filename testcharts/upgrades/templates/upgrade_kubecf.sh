#!/bin/bash

source funcs.sh
set -ex

cd kubecf

helm upgrade kubecf --namespace {{.Values.namespaces.kubecf}} {{- if not .Values.cap.enabled }} ./kubecf_release.tgz {{- else }} --devel --version {{.Values.cap.kubecf.to.version}} {{.Values.cap.kubecf.to.chart}} {{- end }} --values ../values_upgrade.yaml
wait_kubecf
