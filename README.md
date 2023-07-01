手动搭建 k8s1.25 + containerd

# 0. 基础环境

| 主机名  | IP 地址      | 角色   | os        | kernel          |
| ------- | ------------ | ------ | --------- | --------------- |
| master1 | 10.81.82.100 | master | centos7u6 | 5.10.0-1.0.0.25 |
| master2 | 10.81.82.101 | master | centos7u6 | 5.10.0-1.0.0.25 |
| master3 | 10.81.82.102 | master | centos7u6 | 5.10.0-1.0.0.25 |
| node1   | 10.81.82.103 | node   | centos7u6 | 5.10.0-1.0.0.25 |
| node2   | 10.81.82.104 | node   | centos7u6 | 5.10.0-1.0.0.25 |

| 软件         | 版本          |
| ------------ | ------------- |
| docker-ce    | 24.0.0        |
| pod 网络     | 193.244.0.0/16 |
| service 网络 | 196.20.0.0/16   |

# 1. 参数配置

## 1.1 修改 /etc/hosts

```bash
# master
10.81.82.100  master1
10.81.82.101  master2
10.81.82.102  master3

# worker
10.81.82.103  node1
10.81.82.104  node2
```

## 1.2 配置 yum

```bash
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

yum clean all && yum makecache
```

## 1.3 安装包

```bash
yum install wget jq psmisc vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git -y
```

## 1.4 关闭防火墙、selinux、swap、dnsmasq

```bash
systemctl disable --now firewalld
systemctl disable --now dnsmasq
systemctl disable --now NetworkManager

setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab
```

## 1.5 时间同步

```bash
rpm -ivh http://mirrors.wlnmp.com/centos/wlnmp-release-centos.noarch.rpm
yum install ntpdate -y
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' >/etc/timezone
ntpdate ntp1.aliyun.com
# 加入到crontab
*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com
```

## 1.6 配置 ulimit

```bash
ulimit -SHn 65535

vim /etc/security/limits.conf
# 末尾添加如下内容
* soft nofile 65536
* hard nofile 131072
* soft nproc 65535
* hard nproc 655350
* soft memlock unlimited
* hard memlock unlimited
```

## 1.7 设置免密登陆

```bash
ssh-keygen -t rsa
for i in master1 master2 master3 node1 node2;do ssh-copy-id -i .ssh/id_rsa.pub $i;done
```

## 1.8 安装 ipvsadm

```bash
yum install ipvsadm ipset sysstat conntrack libseccomp -y
```

## 1.9 配置 ipvs

```bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
vim /etc/modules-load.d/ipvs.conf
# 加入以下内容
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
ip_vs_sh
nf_conntrack
ip_tables
ip_set
xt_set
ipt_set
ipt_rpfilter
ipt_REJECT
ipip
# 设置开机自动加载
systemctl enable --now systemd-modules-load.service
```

## 1.10 配置 K8S 内核参数

```bash
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.may_detach_mounts = 1
net.ipv4.conf.all.route_localnet = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720

net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF
sysctl --system

# 检查重启生效
# reboot
# lsmod | grep --color=auto -e ip_vs -e nf_conntrack
```

# 2. 包安装

## 2.1 安装 k8s 工具

```bash
# yum list --showduplicate kublet
yum install -y kubelet-1.25.0-0.x86_64 kubectl-1.25.0-0.x86_64 kubeadm-1.25.0-0.x86_64 docker-ce-24.0.0 docker-ce-cli-24.0.0 containerd.io

# 如果需要下载翻墙下载镜像，可以配置一下 docker 代理
# vim /usr/lib/systemd/system/docker.service
# 添加以下内容
# [Service]
#...
#Environment="HTTP_PROXY=http://agent.fuckyou.com:8118"
#Environment="HTTPS_PROXY=http://agent.fuckyou.com:8118"
#Environment="NO_PROXY=localhost,127.0.0.1"
...

```

## 2.2 配置 containerd

```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe -- overlay
modprobe -- br_netfilter

# 配置内核模块
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# 加载内核模块
sysctl --system

# containerd 配置文件
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
# 找到containerd.runtimes.runc.options，添加 SystemdCgroup = true
# 所有节点将sandbox_image的Pause镜像改成符合自己版本的地址registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.6

systemctl daemon-reload && systemctl enable --now containerd

# 配置 crictl 运行时
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# 配置 kubelet 使用 containered
cat >/etc/sysconfig/kubelet<<EOF
KUBELET_KUBEADM_ARGS="--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF

systemctl daemon-reload && systemctl enable --now kubelet
```

# 3. kubeadm 配置

## 3.1 生成配置文件

```yaml
# kubeadm config print init-defaults

# 修改文件内容为 admin.yaml
# 需要替换一下 "MASTERIP 或 VIP" 

apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: MASTER_IP 或 VIP
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: master1
  taints: null
---
apiServer:
  extraArgs:
    authorization-mode: Node,RBAC
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: MASTER_IP:6443 或 VIP:6443
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: iregistry.fuckyou.com/kubernetes
kind: ClusterConfiguration
kubernetesVersion: 1.25.0
networking:
  dnsDomain: cluster.local
  podSubnet: 193.244.0.0/16
  serviceSubnet: 196.20.0.0/16
scheduler: {}
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: iptables
```

## 3.2 创建集群

```bash
# kubeadm init --config /root/new2.yaml  --upload-certs

kubeadm join 10.81.82.100:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:c8a3372277bc673f40f0827972194d782676a014cf720494fe4a9046630edad8 \
        --control-plane --certificate-key e813490b38152e80264e709c095017121cbe29571f032cf43e3bf78d2d3ac3bc

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.81.82.100:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:c8a3372277bc673f40f0827972194d782676a014cf720494fe4a9046630edad8

# kubeadm init phase upload-certs --upload-certs --config=/root/new2.yaml
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
c34159d9a44cbc5d5d8e207aa500200cff7aa75cfc9f634e3045324604288940

# 修改 join 命令
# 添加 master
kubeadm join 10.81.82.100:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:c8a3372277bc673f40f0827972194d782676a014cf720494fe4a9046630edad8 \
        --control-plane --certificate-key c34159d9a44cbc5d5d8e207aa500200cff7aa75cfc9f634e3045324604288940

# 添加 node
kubeadm join 10.81.82.100:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:c8a3372277bc673f40f0827972194d782676a014cf720494fe4a9046630edad8
```

## 3.3 安装 metric-server

```bash
# https://github.com/kubernetes-sigs/metrics-server
...
containers:
      - args:
        - --cert-dir=/tmp
        - --kubelet-insecure-tls             # 新加
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
...
```

## 3.4 安装 calico

```bash
# 本次使用的是 k8s 1.25, 根据 calico 的文档可以看到需要使用 3.24 版本
# https://docs.tigera.io/calico/3.24/getting-started/kubernetes/requirements
# https://docs.tigera.io/calico/3.24/getting-started/kubernetes/quickstart#install-calico
# https://docs.tigera.io/calico/3.24/operations/image-options/imageset#create-an-imageset
# 联通性检查：https://github.com/alibaba/kubeskoop：

# vimdiff xx.yaml xx.yaml.org 可以对比二者的修改

# https://raw.githubusercontent.com/projectcalico/calico/v3.24.6/manifests/tigera-operator.yaml
# 如果你能访问外网，那么本文件中的 image: 指定的镜像仓库不需要修改
kubectl apply -f calico_v3.24.6/calico_3.24.6/tigera-operator_v3.24.6.yaml

# https://raw.githubusercontent.com/projectcalico/calico/v3.24.6/manifests/custom-resources.yaml
# 1. 如果你能连接外网，可以把这个删除，同时也不需要执行 kubectl apply xxxx/imageset.yaml
# registry: iregistry.fuckyou.com
  imagePath: "kubernetes/calico"
  imagePrefix: ""
# 2. 根据自己的环境修改 cidr，我在使用 kubeadm 时使用 podSubnet 为 10.244.0.0/16，所以需要修改
kubectl apply -f calico_v3.24.6/calico_3.24.6/custom-resources_v3.24.6.yaml

# 修改 imageset.yaml
# https://docs.tigera.io/calico/3.24/operations/image-options/imageset#update-the-operator-deployment-with-a-digest
kubectl apply -f calico_v3.24.6/calico_3.24.6/imageset.yaml
```

# 4. 删除集群

```bash
# 清理通过 kubeadm 安装的集群
kubeadm reset -f

# 删除文件
rm -rf /etc/cni /etc/kubernetes /var/lib/dockershim /var/lib/etcd /var/lib/kubelet /var/run/kubernetes ~/.kube/*

# 清理 iptables
iptables -F && iptables -X
iptables -t nat -F && iptables -t nat -X
iptables -t raw -F && iptables -t raw -X
iptables -t mangle -F && iptables -t mangle -X

# 重启 runtime
systemctl daemon-reload && systemctl restart containerd docker
```

# 5. Q&A

## 5.1 ns 无法删除

```bash
kubectl proxy
curl -H "Content-Type: application/json" -XPUT -d '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"knative-serving"},"spec":{"finalizers":[]}}' http://localhost:8001/api/v1/namespaces/knative-serving/finalize
```
