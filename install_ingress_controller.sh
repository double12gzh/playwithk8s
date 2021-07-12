##############方式一(推荐)###############
# 参考：https://kind.sigs.k8s.io/docs/user/ingress/

##################方式二##################
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm fetch ingress-nginx/ingress-nginx --version 3.19.0

docker pull yametech/ingress-controller:v0.43.0
docker tag docker.io/yametech/ingress-controller:v0.43.0 k8s.gcr.io/ingress-nginx/controller:v0.43.0
kind load docker-image k8s.gcr.io/ingress-nginx/controller:v0.43.0 --name lanjikind

# 修改values.yaml文件
# 1. 修改 controller.hostNetwork: true
# 2. 修改 controller.hostPort.enabled: true
# 3. 删除 controller.service.type: LoadBalancer
# 4. 添加 controller.service.type: NodePort
#         controller.service.nodePorts.http: 32080
#         controller.service.nodePorts.https: 32443

# 进入 chart 目录进行安装
helm install ingress-nginx -f values.yaml  --namespace=ingress-nginx .

# 访问服务
# 参考包中的NOTES.txt

# 获取 svc ingress-nginx-controller 中的 NodePort (根据前面对values.yaml文件的修改可知，NodPort的值为32080/32443)
curl http://{NODE_IP}:{NodePort}/bar


##################方式三#################

# 参考以下链接
# https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-3.20.0/deploy/static/provider/kind/deploy.yaml
full_path=$(realpath $0)
dir_path=$(dirname $full_path)

kubectl apply -f ${dir_path}/examples/ingress/deploy.yaml

# 如何访问服务
curl localhost/bar
