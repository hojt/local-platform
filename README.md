# local-platform

Infrastructure for the local development platform.

## Purpose

This repository owns the local Kubernetes platform used during development.

Current responsibilities:

- Devcontainer
- kind cluster
- Task automation
- Local registry

Future responsibilities:

- CI Pipeline (Tekton)
- GitOps (Flux or ArgoCD)
- Ingress
- Observability

## Prerequisites

Host:

- Fedora Atomic
- Podman
- DevContainer CLI

Everything else runs inside the devcontainer.

```
Host
    │
    ▼
dev.sh
    │
    ▼
Dev Container
    │
    ▼
Task
    │
    ▼
scripts/
```

## Develop

`./dev.sh` - Starts a new tmux session (or reuses an existing) and builds/connects to devcontainer.

## Usage

Build the devcontainer

`devcontainer build --workspace-folder . --docker-path podman`

Start it

`devcontainer up --workspace-folder . --docker-path podman`

Open a shell inside the devcontainer

`devcontainer exec --workspace-folder . --docker-path podman bash`

Inside the devcontainer

`task cluster:create`
`task cluster:status`
`task cluster:delete`

`kind get clusters`

`kubectl get nodes`

```bash
podman push \
  --tls-verify=false \
  localhost:5001/example-backend:0.1.0
```
