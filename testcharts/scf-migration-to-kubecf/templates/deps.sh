#!/bin/bash
set -e
wget 'https://packages.cloudfoundry.org/stable?release=linux64-binary&version={{.Values.cf_cli_version}}&source=github-rel' --quiet -O cf.tgz

mkdir bin/
tar -xvf cf.tgz -C bin/ >/dev/null
chmod +x bin/cf

wget 'https://github.com/mikefarah/yq/releases/download/{{.Values.yq_version}}/yq_linux_amd64' --quiet -O bin/yq
chmod +x bin/yq

echo "Done installing cf-cli {{.Values.cf_cli_version}}. yq {{.Values.yq_version}}"
