# Time Tracking GitOps

Infrastructure repository for the Time Tracking diploma project. The repo follows GitOps practices with Helm charts and Argo CD to deploy the Spring Boot backend, React frontend, Keycloak, and PostgreSQL into Kubernetes clusters. Initial focus is a local `kind` environment that can be expanded to additional stages.

## Repository Layout

- `deploy/helm/` – Helm charts for the platform (e.g., backend app, Keycloak, PostgreSQL)
- `deploy/environments/` – Environment-specific overrides (`deploy/environments/<env>/values.yaml`)
- `deploy/argocd/` – Argo CD AppProjects, Applications, and ApplicationSets
- `deploy/infra/` – Cluster bootstrap assets (e.g., local `kind` definition)

## Prerequisites

- Docker (tested with Docker Desktop or Colima
- `kubectl`, `helm`, `kind`, and `argocd` CLI tools installed locally
- Clone of this repository and access to the Git remote Argo CD will watch

## Bootstrap Local Kind Environment

1. **Create the cluster**
   ```bash
   kind create cluster --name time-tracking --config deploy/infra/kind/cluster.yaml
   ```
2. **Enable ingress on the cluster**
   ```bash
   kubectl label node time-tracking-control-plane ingress-ready=true
   ```
3. **Install NGINX ingress controller**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/kind/deploy.yaml
   ```
4. **Create secret so the cluster can pull images from GitHub Container Registry**
   ```bash
   kubectl create namespace time-tracking-dev
   kubectl create secret docker-registry ghcr-creds \
     --docker-server=ghcr.io \
     --docker-username=savevskii \
     --docker-password=<secret-here> \
     --namespace=time-tracking-dev
   ```
5. **Install Argo CD with Helm**
   ```bash
   kubectl create namespace argocd
   helm repo add argo https://argoproj.github.io/argo-helm
   helm repo update
   helm upgrade --install argocd argo/argo-cd \
     --namespace argocd \
     --set applicationset.enabled=true
   ```
6. **Allow Argo CD to serve HTTP behind the ingress**
   ```bash
   kubectl -n argocd patch configmap argocd-cmd-params-cm \
     --type merge --patch '{"data":{"server.insecure":"true"}}'
   kubectl -n argocd rollout restart deployment argocd-server
   ```
7. **Expose Argo CD via NGINX ingress (HTTP passthrough)**
   ```bash
   kubectl apply -f deploy/infra/argocd/ingress.yaml
   ```
   The ingress terminates at `http://argocd.localtest.me` and proxies to the Argo CD server on port 80.
8. **Login to Argo CD**
   ```bash
   argocd login argocd.localtest.me \
     --grpc-web \
     --plaintext \
     --username admin \
     --password $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)
   ```
   You can now open `http://argocd.localtest.me` in a browser and sign in with the same credentials.
9. **Register the Git repository in Argo CD**  
   Update the repo URL below with your Git remote (HTTP(S) or SSH):
   ```bash
   argocd repo add https://github.com/savevskii/time-tracking-deployment.git \
     --name time-tracking-deployment-repo
   ```
10. **(Optional) Create local HTTPS certificates and TLS secrets**  
    If you want to access the application and Keycloak over HTTPS locally, create self-signed certs (you can also use `mkcert`). Store them as TLS secrets referenced by the dev Helm values file before syncing the application.

    time-tracking.localtest.me:
    ```bash
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout time-tracking-local.key \
      -out time-tracking-local.crt \
      -subj "/CN=time-tracking.localtest.me" \
      -addext "subjectAltName = DNS:time-tracking.localtest.me"
    ```
    ```bash
    kubectl -n time-tracking-dev create secret tls time-tracking-local-tls \
      --cert=time-tracking-local.crt \
      --key=time-tracking-local.key
    ```

    keycloak.localtest.me:
    ```bash
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout keycloak-local.key \
      -out keycloak-local.crt \
      -subj "/CN=keycloak.localtest.me" \
      -addext "subjectAltName = DNS:keycloak.localtest.me"
    ```
    ```bash
    kubectl -n time-tracking-dev create secret tls keycloak-local-tls \
      --cert=keycloak-local.crt \
      --key=keycloak-local.key
    ```

    After creating the secrets you can proceed with the application sync (step 11). If using Argo CD, just ensure the secrets exist before the Application first syncs. For manual Helm install/upgrade:
    ```bash
    helm upgrade --install time-tracking deploy/helm/time-tracking-app \
      -n time-tracking-dev \
      -f deploy/environments/dev/values.yaml
    ```
    Trust the certs in your OS/browser if prompted.
11. **Apply GitOps manifests**
    ```bash
    kubectl apply -f deploy/argocd/dev/appprojects/platform.yaml
    kubectl apply -f deploy/argocd/dev/bootstrap.yaml
    ```
    The ApplicationSet will create the `time-tracking` release in the `time-tracking-dev` namespace using the values from `deploy/environments/dev/values.yaml`.

## Next Steps

- Introduce additional Argo CD Application definitions for staging/production clusters once available.
