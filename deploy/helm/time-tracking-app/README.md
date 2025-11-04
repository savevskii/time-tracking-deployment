# Instructions how to install it

1. Install kind cluster:
kind create cluster --name dev --config ../kind/cluster.yaml
2. Enable ingress:
   kubectl label node kind-control-plane ingress-ready=true
   kubectl label node kind-worker ingress-ready=true3
. Install NGINX ingress controller:
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/kind/deploy.yaml
3. kind load docker-image yourImageTag
4. Run the following command to download dependencies:
`helm dependency update`
4.Run the following command to install or upgrade the Helm chart:
helm upgrade --install time-tracking . \
-f values-dev.yaml \
--namespace time-tracking-dev \
--create-namespace