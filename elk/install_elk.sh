# ref: https://github.com/elastic/helm-charts/tree/7.7.1/elasticsearch/
helm repo add elastic https://helm.elastic.co
helm install elasticsearch --version 7.7.1 elastic/elasticsearch --namespace monitoring
helm install logstash --version 7.7.1 elastic/logstash --namespace monitoring
helm install kibana --version 7.7.1 elastic/kibana --namespace monitoring

# 方式二：通过ECK安装
# ref: https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html
# https://www.qikqiak.com/post/elastic-cloud-on-k8s/
# 1. 安装 ECK
kubectl apply -f https://download.elastic.co/downloads/eck/1.4.0/all-in-one.yaml

# 2. 安装ES
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.11.1
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF

# 3. 安装kibana
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 7.11.1
  count: 1
  elasticsearchRef:
    name: quickstart
EOF
# 注意： kibana中的spec.elasticsearchRef.name 要与 elasticsearch中的metadata.name 一致
