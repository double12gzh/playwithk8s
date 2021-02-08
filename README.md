> 用于总结一下 k8s 安装过程（非生产）

# 1. 访问K8S dashboard
kubectl proxy --address='0.0.0.0'  --accept-hosts='^*$' --port=8001

> 在需要访问的 dashboard的机器上执行下面的命令
```bash
ssh -fgCNL 30443:127.0.0.1:8001 root@192.168.1.104
```
> 页面地址：http://localhost:30443/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default

# 2. 访问prometheus
```bash
kubectl port-forward prometheus-prometheus-kube-prometheus-prometheus-0 9090
```

> 在需要访问的 UI的机器上执行下面的命令
```bash
ssh -fgCNL 39090:127.0.0.1:9090 root@192.168.1.104
```
> 页面地址：http://localhost:39090

# 3. 访问grafana

```bash
kubectl port-forward -n monitoring prometheus-grafana-85b4dbb556-8v8dw 3000
```
> 在需要访问的 UI的机器上执行下面的命令
```bash
ssh -fgCNL 33000:127.0.0.1:3000 root@192.168.1.104
```
> 页面地址：http://localhost:33000
> 用户名和密码：kubectl get secret -n monitoring grafana-credentials -o yaml
