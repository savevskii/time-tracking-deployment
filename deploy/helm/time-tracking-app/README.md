## Helm Chart: time-tracking-app

This chart deploys the Time Tracking backend, frontend, Keycloak, and PostgreSQL (via subcharts/packaged charts) into a Kubernetes namespace.

The main usage, local kind cluster bootstrap steps, and HTTPS certificate instructions have been consolidated into the root `README.md` to avoid duplication.

Refer to the repository root `README.md` for:
- Cluster bootstrap and Argo CD setup
- Local HTTPS certificate generation and secrets
- Helm upgrade/install example

### Values
Override values per environment under `deploy/envs/<env>/time-tracking-app/values.yaml`.

To perform a manual install/upgrade:
```bash
helm upgrade --install time-tracking deploy/helm/time-tracking-app \
  -n time-tracking-dev \
  -f deploy/envs/dev/time-tracking-app/values.yaml
```

### Notes
- TLS secrets referenced in values must exist before Argo CD/Helm sync.
- Image pull secrets (e.g. `ghcr-creds`) must be in the target namespace.
- See root README for more operational details.
