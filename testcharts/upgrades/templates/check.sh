#!/bin/bash
set -ex
export PATH=$PATH:$PWD/bin

bash login.sh

if cf apps | grep started; then
	echo "OK"
else
	echo "APP not OK"
	echo "Restaging app"
	cf restage dizzylizard
	if cf apps | grep started; then
		echo "App OK after restaging"
	else
		echo "Failed starting app"
		exit 1
	fi
fi
