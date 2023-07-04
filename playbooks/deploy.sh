#!/usr/bin/env bash
set -x
set -e

SCRIPT_NAME=$0

# 脚本所在路径
CURRENT_DIR="$(
	cd $(dirname ${SCRIPT_NAME})
	pwd
)"

export ANSIBLE_FORCE_COLOR=true
source ${CURRENT_DIR}/lib/common.sh

init_log ${CURRENT_DIR} "deploy"

playbook=${CURRENT_DIR}/ansible/deploy.yaml

info "[START] do preparation."

ansible-playbook -f 10 -e "action=deploy" ${playbook} 2>&1 | tee -a ${LOG_FILE}
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	error "failed to do prepare."
	exit 1
fi

cp ${CURRENT_DIR}/ansible/hosts /etc/ansible/hosts

info "[FINISH]: prepare successfully."