#!/usr/bin/bash
set -e
ROOT_DIR=$PWD
BACKUP_DIR=$PWD/backup
kubectl scale --replicas=0 sts api -n {{.Values.namespaces.kubecf}} --timeout=20m
kubectl scale --replicas=0 sts cc-worker -n {{.Values.namespaces.kubecf}} --timeout=20m
kubectl scale --replicas=0 sts uaa -n {{.Values.namespaces.kubecf}} --timeout=20m

kubectl exec -t database-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	"mysql \
  -e 'SET GLOBAL pxc_strict_mode=DISABLED;'"
kubectl exec -t database-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	"mysql \
  -e 'drop database uaa; create database uaa;'"

kubectl exec --stdin database-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	'mysql \
  uaa' <$BACKUP_DIR/uaadb-src.sql

kubectl cp $BACKUP_DIR/blobstore-src.tgz {{.Values.namespaces.kubecf}}/blobstore-0:/.

kubectl exec --stdin --tty --namespace {{.Values.namespaces.kubecf}} blobstore-0 -- bash -l -c 'rm -rf /var/vcap/store/shared/* && tar xvf blobstore-src.tgz && rm blobstore-src.tgz'

kubectl exec mysql-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	"mysql \
  -e 'drop database cloud_controller; create database cloud_controller;'"

kubectl exec --stdin mysql-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	'mysql \
  cloud_controller' <$BACKUP_DIR/ccdb-src.sql

kubectl exec --namespace {{.Values.namespaces.kubecf}} api-0 -c cloud-controller-ng-cloud-controller-ng -- bash -c \
	"source /var/vcap/jobs/cloud_controller_ng/bin/ruby_version.sh; \
export CLOUD_CONTROLLER_NG_CONFIG=/var/vcap/jobs/cloud_controller_ng/config/cloud_controller_ng.yml; \
cd /var/vcap/packages/cloud_controller_ng/cloud_controller_ng; \
bundle exec rake rotate_cc_database_key:perform"

kubectl exec -t database-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	"mysql \
  -e 'SET GLOBAL pxc_strict_mode=ENFORCING;'"
kubectl scale --replicas=1 sts api -n {{.Values.namespaces.kubecf}} --timeout=20m
kubectl scale --replicas=1 sts cc-worker -n {{.Values.namespaces.kubecf}} --timeout=20m
