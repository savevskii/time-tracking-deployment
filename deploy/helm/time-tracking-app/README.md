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

## Local HTTPS certificates

To access the ingress hosts over HTTPS locally, create self-signed certificates (mkcert works too; below uses `openssl`) and store them as TLS secrets referenced in the dev values file.

### time-tracking.localtest.me

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout time-tracking-local.key \
  -out time-tracking-local.crt \
  -subj "/CN=time-tracking.localtest.me" \
  -addext "subjectAltName = DNS:time-tracking.localtest.me"

kubectl -n time-tracking-dev create secret tls time-tracking-local-tls \
  --cert=time-tracking-local.crt \
  --key=time-tracking-local.key
```

### keycloak.localtest.me

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout keycloak-local.key \
  -out keycloak-local.crt \
  -subj "/CN=keycloak.localtest.me" \
  -addext "subjectAltName = DNS:keycloak.localtest.me"

kubectl -n time-tracking-dev create secret tls keycloak-local-tls \
  --cert=keycloak-local.crt \
  --key=keycloak-local.key
```

After creating the secrets, run `helm upgrade --install ... -f deploy/envs/dev/time-tracking-app/values.yaml` (or let Argo CD sync) and visit the HTTPS endpoints. Trust the certificates in your browser/OS if prompted.
