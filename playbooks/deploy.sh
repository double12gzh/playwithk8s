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

info "[START] do deployment."

ansible-playbook -f 10 -e "operation=deploy" ${playbook} 2>&1 | tee -a ${LOG_FILE}
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	error "failed to do deployment."
	exit 1
fi

info "[FINISH]: successfully deployed."
