#!/bin/bash

set -e
BACKUP_DIR=$PWD/backup
# 200 small apps 1 org ~11m20s
if [ ! -d "$BACKUP_DIR" ]; then
	mkdir $BACKUP_DIR
fi

# From: https://documentation.suse.com/suse-cap/1.5.2/html/cap-guides/cha-cap-backup-restore.html

# Export the UAA database into a file:
echo "Exporting UAA database"
kubectl exec --tty mysql-0 --namespace scf -- bash -c \
	'/var/vcap/packages/mariadb/bin/mysqldump \
  --defaults-file=/var/vcap/jobs/mysql/config/mylogin.cnf \
  --socket /var/vcap/sys/run/pxc-mysql/mysqld.sock \
  uaadb' >$BACKUP_DIR/uaadb-src.sql

if [ ! -e "$BACKUP_DIR/uaadb-src.sql" ]; then
	echo "UAA db dump not present. something went wrong"
	exit 1
fi

# Create an archive of the blobstore directory to preserve all needed files

echo "Backing up scf blobstore"
kubectl exec --stdin --tty blobstore-0 \
	--namespace scf \
	-- tar cfvz blobstore-src.tgz /var/vcap/store/shared
kubectl cp scf/blobstore-0:blobstore-src.tgz $BACKUP_DIR/blobstore-src.tgz

if [ ! -e "$BACKUP_DIR/blobstore-src.tgz" ]; then
	echo "Blobstore dump not present. something went wrong"
	exit 1
fi

# Export the Cloud Controller Database (CCDB) into a file
echo "Exporting CCDB Database"
kubectl exec mysql-0 --namespace scf -- bash -c \
	'/var/vcap/packages/mariadb/bin/mysqldump \
  --defaults-file=/var/vcap/jobs/mysql/config/mylogin.cnf \
  --socket /var/vcap/sys/run/pxc-mysql/mysqld.sock \
  ccdb' >$BACKUP_DIR/ccdb-src.sql

cc_config=$(kubectl exec --stdin --tty --namespace scf api-group-0 -- bash -c "cat /var/vcap/jobs/cloud_controller_ng/config/cloud_controller_ng.yml")

current_key_label=$(echo "$cc_config" | yq r - "database_encryption.current_key_label")

echo "Current key label: $current_key_label"

# Prepare kubecf values
# See https://github.com/cloudfoundry-incubator/kubecf/blob/11797e25f3f1427f3b061d574eb255b795f23bf3/doc/encryption_key_rotation.md#importing-encryption-keys
if [ -z $current_key_label ]; then
	DB_ENCRYPTION_KEY=$(kubectl exec api-group-0 --namespace scf -- bash -c 'echo $DB_ENCRYPTION_KEY')

	cat >>values.yaml <<EOF
ccdb:
  encryption:
    rotation:
      key_labels:
      - $current_key_label
      current_key_label: $current_key_label

credentials:
  cc_db_encryption_key: "$DB_ENCRYPTION_KEY"
  ccdb_key_label_$current_key_label: "$current_key_label"
EOF

else
	DB_ENCRYPTION_KEYS=$(echo "$cc_config" | yq r - "database_encryption.keys")
	DB_ENCRYPTION_KEY=$(kubectl exec api-group-0 --namespace scf -- bash -c 'echo $DB_ENCRYPTION_KEY')
	cat >>values.yaml <<EOF
ccdb:
  encryption:
    rotation:
      key_labels:
      - $current_key_label
      current_key_label: $current_key_label

credentials:
  cc_db_encryption_key: "$DB_ENCRYPTION_KEY"
  ccdb_key_label_$current_key_label: "$current_key_label"
EOF

fi
