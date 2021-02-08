# ref: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --namespace monitoring
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace mointoring
