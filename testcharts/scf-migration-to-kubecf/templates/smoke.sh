#!/bin/bash
set -ex
export PATH=$PATH:$PWD/bin
export CONFIG=$PWD/smoke.json

export GOPATH=$PWD/go
go get -u -d github.com/cloudfoundry/cf-smoke-tests || true
cd $GOPATH/src/github.com/cloudfoundry/cf-smoke-tests

./bin/test
