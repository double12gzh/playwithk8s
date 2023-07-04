搭建 k8s1.25 + containerd

# 0. 基础环境

| 主机名  | IP 地址         | 角色   | os        | kernel          |
| ------- | --------------- | ------ | --------- | --------------- |
| master1 | 192.168.155.111 | master | centos7u6 | 5.10.0-1.0.0.25 |
| master2 | 192.168.155.112 | master | centos7u6 | 5.10.0-1.0.0.25 |
| master3 | 192.168.155.113 | master | centos7u6 | 5.10.0-1.0.0.25 |
| node1   | 192.168.155.114 | worker | centos7u6 | 5.10.0-1.0.0.25 |

| 软件         | 版本           |
| ------------ | -------------- |
| docker-ce    | 24.0.0         |
| pod 网络     | 193.244.0.0/16 |
| service 网络 | 196.20.0.0/16  |

# 1. 参数配置

## 1.1 集群规划

a. 节点配置

```json
{
    "clusters": "172.17.0.3,172.17.0.4,172.17.0.5,172.17.0.6", # 集群节点，前三个为 master 节点, 其它的为 worker 节点
    "leading_server": "172.17.0.2", # 默认取第 1 个节点
    "password": "12345"
}
```

b. k8s 参数配置

```bash
# TODO
# 需要把 group_vars/all.yaml 中的参数移到 planning.json
```

## 1.2 环境配置

```bash
bash playbooks/prepare.sh
```

# 2. 部署 k8s

```bash
bash playbooks/deploy.sh
```

# 3. 集群扩容

TODO

# 4. 集群缩容

TODO

# 5. 集群清理

TODO
