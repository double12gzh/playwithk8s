
# https://hub.kubeapps.com/charts/choerodon/chartmuseum
helm repo add choerodon https://openchart.choerodon.com.cn/choerodon/c7n
helm install choerodon/chartmuseum --version 2.15.0 --generate-name
