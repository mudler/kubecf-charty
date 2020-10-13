#!/bin/bash
set -ex
{{- if .Values.ingress }}
cat <<EOF >>nginx_ingress.yaml
tcp:
  2222: "kubecf/scheduler:2222"
  20000: "kubecf/tcp-router:20000"
  20001: "kubecf/tcp-router:20001"
  20002: "kubecf/tcp-router:20002"
  20003: "kubecf/tcp-router:20003"
  20004: "kubecf/tcp-router:20004"
  20005: "kubecf/tcp-router:20005"
  20006: "kubecf/tcp-router:20006"
  20007: "kubecf/tcp-router:20007"
  20008: "kubecf/tcp-router:20008"
EOF

kubectl create namespace nginx-ingress

helm install nginx-ingress suse/nginx-ingress \
--namespace nginx-ingress \
--values nginx_ingress.yaml

{{- end }}

git clone --recurse-submodules https://github.com/cloudfoundry-incubator/kubecf

cd kubecf

git checkout "{{.Values.kubecf.checkout}}" -b build
git submodule update --init --recursive --depth 1

# Deploy mysql. It's from kubecf, but with opinionated settings
source scripts/include/setup.sh

require_tools kubectl helm

: "${MYSQL_CHART:=https://kubernetes-charts.storage.googleapis.com/mysql-1.6.4.tgz}"
: "${MYSQL_CLIENT_IMAGE:=mysql@sha256:c93ba1bafd65888947f5cd8bd45deb7b996885ec2a16c574c530c389335e9169}"

default_name="kubecf-mysql"
name="kubecf-mysql"
default_namespace="kubecf-mysql"
root_password="root"
namespace="kubecf-mysql"
databases=(
  "cloud_controller"
  "diego"
  "network_connectivity"
  "network_policy"
  "routing-api"
  "uaa"
  "locket"
  "credhub"
)

if ! kubectl get namespace "${namespace}" 1> /dev/null 2> /dev/null; then
  kubectl create namespace "${namespace}"
fi

helm template "${name}" "${MYSQL_CHART}" \
  --namespace "${namespace}" \
  --set "mysqlRootPassword=${root_password}" \
  --set "testFramework.enabled=false" \
  | kubectl apply -f - \
    --namespace "${namespace}"

kubectl wait pod \
  --for condition=ready \
  --namespace "${namespace}" \
  --selector "app=${name}" \
  --timeout 300s

# Ensure the database is fully functional.
until echo "SELECT 'Ready!'" | kubectl run mysql-client --rm -i --restart='Never' --image "${MYSQL_CLIENT_IMAGE}" --namespace "${namespace}" --command -- \
    mysql --host="${name}.${namespace}.svc" --user=root --password="${root_password}"; do
      sleep 1
done

kubectl run mysql-client --rm -i --restart='Never' --image "${MYSQL_CLIENT_IMAGE}" --namespace "${namespace}" --command -- \
    mysql --host="${name}.${namespace}.svc" --user=root --password="${root_password}" \
    < <(
      for database in ${databases[*]}; do
        echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
      done
    )

{{- if not .Values.cap.enabled }}
make kubecf-bundle

CHART="output/kubecf-bundle-$(./scripts/version.sh).tgz"

tar -xvf $CHART -C ./ > /dev/null
{{- else }}
helm repo add suse https://kubernetes-charts.suse.com/
helm repo update
{{- end }}

kubectl create namespace {{.Values.namespaces.quarksoperator}}

helm install cf-operator --namespace {{.Values.namespaces.quarksoperator}} {{- if not .Values.cap.enabled }} ./cf-operator.tgz {{- else }} --devel --version {{.Values.cap.quarks.version}}  {{.Values.cap.quarks.chart}} {{- end }} --set "global.singleNamespace.name={{.Values.namespaces.kubecf}}"

./scripts/cf-operator-wait.sh

{{- if .Values.ingress }}
kubectl apply -f ../certs.yaml
{{- end }}
kubectl apply -f ../secret.yaml

helm install kubecf --namespace {{.Values.namespaces.kubecf}} {{- if not .Values.cap.enabled }} ./kubecf_release.tgz {{- else }} --devel --version {{.Values.cap.kubecf.version}}  {{.Values.cap.kubecf.chart}} {{- end }}  --values ../values.yaml

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