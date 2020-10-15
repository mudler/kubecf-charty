#!/bin/bash
export PATH=$PATH:$PWD/bin

cf login --skip-ssl-validation -a https://api.{{.Values.system_domain}} -u admin -p "{{.Values.creds}}"

cf create-space test

cf target -s test
