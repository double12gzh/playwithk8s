# ref: https://github.com/elastic/helm-charts/tree/7.7.1/elasticsearch/
helm repo add elastic https://helm.elastic.co
helm install elasticsearch --version 7.7.1 elastic/elasticsearch --namespace monitoring
helm install logstash --version 7.7.1 elastic/logstash --namespace monitoring
helm install kibana --version 7.7.1 elastic/kibana --namespace monitoring
