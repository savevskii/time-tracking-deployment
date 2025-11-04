# Repository Guidelines

## Diploma Thesis Context
- Project underpins diploma thesis titled "Automation of the web application testing, building and delivery process".
- CI now runs on GitHub Actions in this repository.
- CD follows GitOps principles via Kubernetes and Argo CD using the `time-tracking-deployment` repository.
- Exploring modern CI/CD pipelines that incorporate AI agents.
- Frontend app code lives in `time-tracking-app-ui`.
- Backend app code lives in `time-tracking-app`.
- K8s helm charts and GitOps manifests are in the `time-tracking-deployment` repository.


## CI/CD Pipeline Goals
- `time-tracking-app` (CI) should trigger on PRs and pushes; run `mvn -B clean verify`, aggregate coverage, and block merges on failures.
- Successful main-branch builds should produce versioned backend Docker images, publish build artifacts, and surface test/security reports.
- Integrate container/image scanning (Snyk/Trivy) plus dependency/license checks before release artifacts are published.
- On release tagging, push images to the container registry and emit metadata (digest, version, changelog) for the CD repo to consume.
- `time-tracking-deployment` (CD) should watch for new image metadata, update Helm chart values or Kustomize overlays with the fresh tag, run chart/unit tests, and open automated PRs for review.
- Argo CD syncs the approved manifest changes into Kubernetes; ensure post-deploy smoke tests run, report status back to GitHub, and support automated rollback on failure signals.
- Evaluate inserting AI agents for pipeline assistance (e.g., summarize CI findings, generate deployment PR descriptions, suggest remediation steps) while keeping human approvals in the loop.

## CI/CD Tooling Decisions
- Container images live in GitHub Container Registry (GHCR); follow GitHub best practices for naming (`ghcr.io/<org>/time-tracking-app:<semver>`).
- Adopt SemVer tagging; release workflow tags the repo and propagates the version to images and Helm chart updates.
- Security checks: run Trivy (image/file system), Snyk (SCA), and OWASP Dependency-Check on every build before publishing artifacts.
- Test coverage: use JaCoCo uploads sent to Codecov for PR diff reporting.
- Helm remains the packaging mechanism in `time-tracking-deployment`; workflows will update chart values with new image tags.
- Post-deploy smoke tests deferred for now; revisit when CD automation matures.
- CI publishes the backend executable jar as an artifact so downstream Docker jobs can consume it without rebuilding.
- AI agent integration points to be defined later once baseline pipelines are stable.

## Repository Structure
- `deploy/helm/` — Helm charts (e.g., `time-tracking-app` bundling backend, PostgreSQL, Keycloak).
- `deploy/envs/<env>/<component>/values.yaml` — Environment-specific overrides consumed by Argo CD Applications.
- `deploy/argocd/` — AppProjects, Applications, and ApplicationSets driving GitOps sync (ApplicationSet for `time-tracking`).
- `deploy/infra/` — Ancillary cluster assets such as kind cluster config and the Argo CD ingress manifest.

## Argo CD Notes
- The chart installs Argo CD via Helm with the ApplicationSet controller enabled.
- After install, patch `argocd-cmd-params-cm` to set `server.insecure=true`; ingress exposes HTTP at `argocd.localtest.me` via NGINX.
- Default admin password lives in `argocd-initial-admin-secret`; CLI login uses `argocd login argocd.localtest.me --grpc-web --plaintext ...`.
