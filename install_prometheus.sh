# ref: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
# ref: https://github.com/prometheus-operator/kube-prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --namespace monitoring
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace mointoring --version 12.7.0


# 访问：
# 在远端服务器上执行：
# kubectl port-forward -n mointoring svc/alertmanager-operated 9093
# kubectl port-forward -n mointoring svc/prometheus-kube-prometheus-prometheus 9090
# kubectl port-forward deploy/prometheus-grafana -n mointoring 3000
# 在本地执行：
# kcptun_client --key xxxx -l :zzzz -r {远端服务器IP}:yyyy
# ssh -CfgCN -L 9090:localhost:9090 -p zzzz root@localhost
# ssh -CfgCN -L 9093:localhost:9093 -p zzzz root@localhost
# ssh -CfgCN -L 3000:localhost:3000 -p zzzz root@localhost
# 在浏览器中输入：
# http://localhost:9090
# http://localhost:9093
# http://localhost:3000
