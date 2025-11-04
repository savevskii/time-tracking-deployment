# Time Tracking GitOps

Infrastructure repository for the Time Tracking diploma project. The repo follows GitOps practices with Helm charts and Argo CD to deploy the Spring Boot backend, React frontend, Keycloak, and PostgreSQL into Kubernetes clusters. Initial focus is a local `kind` environment that can be expanded to additional stages.

## Repository Layout

- `deploy/helm/` – Helm charts for the platform (e.g., backend app, Keycloak, PostgreSQL)
- `deploy/envs/` – Environment-specific overrides (`deploy/envs/<env>/<component>/values.yaml`)
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
2. **Install Argo CD with Helm**
   ```bash
   kubectl create namespace argocd
   helm repo add argo https://argoproj.github.io/argo-helm
   helm repo update
   helm upgrade --install argocd argo/argo-cd \
     --namespace argocd \
     --set applicationset.enabled=true
   ```
3. **Allow Argo CD to serve HTTP behind the ingress**
   ```bash
   kubectl -n argocd patch configmap argocd-cmd-params-cm \
     --type merge --patch '{"data":{"server.insecure":"true"}}'
   kubectl -n argocd rollout restart deployment argocd-server
   ```
4. **Expose Argo CD via NGINX ingress (HTTP passthrough)**
   ```bash
   kubectl apply -f deploy/infra/argocd/ingress.yaml
   ```
   The ingress terminates at `http://argocd.localtest.me` and proxies to the Argo CD server on port 80.
5. **Login to Argo CD**
   ```bash
   argocd login argocd.localtest.me \
     --grpc-web \
     --plaintext \
     --username admin \
     --password $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)
   ```
   You can now open `http://argocd.localtest.me` in a browser and sign in with the same credentials.
   6. **Register the Git repository in Argo CD**  
      Update the repo URL below with your Git remote (HTTP(S) or SSH):
      ```bash
      argocd repo add https://github.com/savevskii/time-tracking-deployment.git \
       --username savevskii \
       --password <your-github-token> \
       --name time-tracking-app-repo
      ```
6. **Apply GitOps manifests**
   ```bash
   kubectl apply -f deploy/argocd/dev/appprojects/platform.yaml
   kubectl apply -f deploy/argocd/dev/bootstrap.yaml
   ```
   The ApplicationSet will create the `time-tracking` release in the `time-tracking-dev` namespace using the values from `deploy/envs/dev/time-tracking-app/values.yaml`.

## Next Steps

- Replace `https://github.com/savevskii/time-tracking-deployment.git` placeholders with the actual remote URL in Argo CD manifests.
- Populate environment-specific values under `deploy/envs/<env>/<component>/values.yaml`.
- Run `helm dependency update` inside `deploy/helm/time-tracking-app` after chart changes.
- Add CI pipelines to build container images, version Helm charts, and raise PRs that promote updates through environments.
- Introduce additional Argo CD Application definitions for staging/production clusters once available.
