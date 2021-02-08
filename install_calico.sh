# 参考：https://alexbrand.dev/post/creating-a-kind-cluster-with-calico-networking/
kubectl apply -f /root/kind_example/calico/calico.yaml

# Relax Calico's RPF Check Configuration
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

