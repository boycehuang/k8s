# Install Kubernates Dashboard UI
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

# Startup
kubectl proxy

# Create Login User and Role
kubectl create -f k8s-DashboardUI-ServiceAccount.yaml
kubectl create -f k8s-DashboardUI-ClusterRoleBinding.yaml

# Get Token
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# Login Page
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login