#!/bin/bash
export PATH=$PATH:$PWD/bin
set -ex
bash login.sh

[ ! -d "dizzylizard" ] && git clone https://github.com/scf-samples/dizzylizard

pushd dizzylizard
cf push
popd
