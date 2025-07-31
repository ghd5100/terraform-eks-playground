apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${ca_data}
    server: ${endpoint}
    # server: https://127.0.0.1:8443
    name: ${cluster_name}
    # name: arn:aws:eks:ap-northeast-2:116981781177:cluster/my-eks-cluster
contexts:
- context:
    cluster: ${cluster_name}
    user: ${cluster_name}
  name: ${cluster_name}
current-context: ${cluster_name}
kind: Config
preferences: {}
users:
- name: ${cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - ${cluster_name}