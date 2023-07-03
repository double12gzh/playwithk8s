#!/bin/bash

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

LOG=""
LOG_FILE=""

function init_log() {
	path=$1

	LOG=${path}/logs
	if [[ ! -d ${LOG} ]]; then
		mkdir -p ${LOG}
	fi

	LOG_FILE="${LOG}/execution.log"

	mv ${LOG_FILE} ${LOG_FILE}.bk >/dev/null 2>&1 && echo true || echo false

	touch ${LOG_FILE}
}

function date_time() {
	echo "$(date '+%Y-%m-%d %H:%M:%S.%2N')"
}

function error() {
	t=$(date_time)
	echo "$red$t[ERROR] $@$end" >>${LOG}/execution.log
}

function info() {
	t=$(date_time)
	echo "$grn$t[INFO] $@$end" >>${LOG}/execution.log
}

function warn() {
	t=$(date_time)
	echo "$blu$t[WARN] $@$end" >>${LOG}/execution.log
}
