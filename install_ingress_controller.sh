helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm fetch ingress-nginx/ingress-nginx --version 3.19.0

docker pull yametech/ingress-controller:v0.43.0
docker tag docker.io/yametech/ingress-controller:v0.43.0 k8s.gcr.io/ingress-nginx/controller:v0.43.0
kind load docker-image k8s.gcr.io/ingress-nginx/controller:v0.43.0 --name lanjikind

# 修改一下镜像信息,把digest信息注释掉.
# 进入 chart 目录进行安装
helm install ingress-nginx -f values.yaml  --namespace=ingress-nginx .

