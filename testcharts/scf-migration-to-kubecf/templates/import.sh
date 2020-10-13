#!/usr/bin/bash
set -e
ROOT_DIR=$PWD
BACKUP_DIR=$PWD/backup

kubectl exec -t database-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	"/var/vcap/packages/mariadb/bin/mysql \
  --defaults-file=/var/vcap/jobs/mysql/config/mylogin.cnf \
  --socket /var/vcap/sys/run/pxc-mysql/mysqld.sock \
  -e 'drop database uaadb; create database uaadb;'"

kubectl exec --stdin database-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	'/var/vcap/packages/mariadb/bin/mysql \
  --defaults-file=/var/vcap/jobs/mysql/config/mylogin.cnf \
  --socket /var/vcap/sys/run/pxc-mysql/mysqld.sock \
  uaadb' <$BACKUP_DIR/uaadb-src.sql

kubectl cp $BACKUP_DIR/blobstore-src.tgz {{.Values.namespaces.kubecf}}/blobstore-0:/.

kubectl exec --stdin --tty --namespace {{.Values.namespaces.kubecf}} blobstore-0 -- bash -l -c 'rm -rf /var/vcap/store/shared/* && tar xvf blobstore-src.tgz && rm blobstore-src.tgz'

kubectl exec mysql-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	"/var/vcap/packages/mariadb/bin/mysql \
  --defaults-file=/var/vcap/jobs/mysql/config/mylogin.cnf \
  --socket /var/vcap/sys/run/pxc-mysql/mysqld.sock \
  -e 'drop database ccdb; create database ccdb;'"

kubectl exec --stdin mysql-0 --namespace {{.Values.namespaces.kubecf}} -- bash -c \
	'/var/vcap/packages/mariadb/bin/mysql \
  --defaults-file=/var/vcap/jobs/mysql/config/mylogin.cnf \
  --socket /var/vcap/sys/run/pxc-mysql/mysqld.sock \
  ccdb' <$BACKUP_DIR/ccdb-src.sql

kubectl exec --namespace {{.Values.namespaces.kubecf}} api-group-0 -- bash -c \
	"source /var/vcap/jobs/cloud_controller_ng/bin/ruby_version.sh; \
export CLOUD_CONTROLLER_NG_CONFIG=/var/vcap/jobs/cloud_controller_ng/config/cloud_controller_ng.yml; \
cd /var/vcap/packages/cloud_controller_ng/cloud_controller_ng; \
bundle exec rake rotate_cc_database_key:perform"

kubectl delete pod api-0 --namespace {{.Values.namespaces.kubecf}}
kubectl delete pod cc-worker-0 --namespace {{.Values.namespaces.kubecf}}
kubectl delete pod cc-clock-0 --namespace {{.Values.namespaces.kubecf}}
