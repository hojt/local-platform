# local-platform

Infrastructure for the local development platform.

## Purpose

This repository owns the local Kubernetes platform used during development.

Current platform capabilities include:

* containerized development environment
* Kubernetes cluster
* local container registry
* GitOps
* HTTP routing through Gateway API
* task-based automation

Current implementations include:

* Dev Containers for the development environment
* Kind for Kubernetes
* Podman for container operations
* Argo CD for GitOps
* Envoy Gateway for Gateway API

Future platform capabilities may include:

* CI pipelines
* externally reachable LoadBalancer services
* TLS and certificate management
* observability

Alternative implementations may also be evaluated as the homelab evolves.

Examples include:

* Flux for GitOps
* Cilium for networking and Gateway API
* cloud-provider-kind for local LoadBalancer integration
* Ingress
* Traefik
* HAProxy
* Istio

Specific tools are generally treated as implementations of platform
capabilities rather than permanent architectural choices.

## Prerequisites

The developer host is intentionally kept lightweight.

Required on the host:

* Fedora Atomic
* Podman
* Dev Container CLI
* tmux
* Git
* terminal and editor of choice

Repository-specific tooling runs inside the Dev Container.

```text
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

## Golden Path

Start or reconnect to the development environment:

```bash
./dev.sh
```

Inside the Dev Container, bring up the local platform:

```bash
task up
```

The platform currently consists of:

```text
Local Container Registry
          │
          ▼
     Kind Cluster
       │      │
       │      ├─────────────┐
       ▼                    ▼
    Argo CD            Envoy Gateway
                            │
                            ▼
                      Gateway API
```

Inspect the running platform:

```bash
task status
```

Or inspect individual components:

```bash
task registry:status
task cluster:status
task argocd:status
task envoy:status
```

The desired state of workloads is maintained separately in
`local-environments`.

After the platform is running, bootstrap the Argo CD applications from that
repository:

```bash
task argocd:bootstrap
```

From that point, workload changes are reconciled from Git.

When host access to workloads through the Gateway API is needed, forward the
local Envoy Gateway:

```bash
task envoy:forward
```

For example, `example-backend` can then be reached with:

```bash
curl http://localhost:8080/api/greeting
```

When finished, tear down the local platform:

```bash
task down
```

The golden path is intentionally small:

```text
./dev.sh
    │
    ▼
 task up
    │
    ▼
local-environments
    │
    ▼
Argo CD reconciliation
    │
    ▼
Gateway API routing
    │
    ▼
 workloads
    │
    ▼
 task down
```

## Development Environment

`dev.sh` is the normal entrypoint for working with this repository.

Start a new repository-specific tmux session, or reconnect to an existing one:

```bash
./dev.sh
```

Rebuild the Dev Container when its definition has changed:

```bash
./dev.sh rebuild
```

`dev.sh` verifies host prerequisites, starts or reuses the repository-specific
tmux session, starts the Dev Container, and opens a shell inside it.

Most repository operations are exposed through Task:

```bash
task --list
```

### Dev Container

The Dev Container provides the tooling required to develop and operate the
local platform.

The normal entrypoint is `./dev.sh`, but the Dev Container can also be operated
manually.

Build the Dev Container:

```bash
devcontainer build \
  --workspace-folder . \
  --docker-path podman
```

Start it:

```bash
devcontainer up \
  --workspace-folder . \
  --docker-path podman
```

Open a shell inside it:

```bash
devcontainer exec \
  --workspace-folder . \
  --docker-path podman \
  bash
```

Personal developer configuration remains outside the repository where
practical. Selected host configuration, such as Git and editor configuration,
may be mounted into the Dev Container.

## Platform Lifecycle

The complete local platform can normally be managed through:

```bash
task up
task status
task down
```

`task up` currently brings up:

```text
registry
   │
   ▼
cluster
   │
   ├──────────────┐
   ▼              ▼
Argo CD      Envoy Gateway
                  │
                  ▼
             Gateway config
```

Individual components also expose lifecycle tasks for development,
troubleshooting, and experimentation.

This separation keeps the common workflow simple while still allowing each
platform component to be operated independently.

## Kubernetes

The local platform currently uses Kind to provide Kubernetes.

The Kubernetes cluster lifecycle is owned by `local-platform`. Kind is the
current implementation and may be replaced or complemented by other Kubernetes
distributions as the homelab evolves.

Create the cluster:

```bash
task cluster:create
```

Show cluster status:

```bash
task cluster:status
```

Delete the cluster:

```bash
task cluster:delete
```

Useful direct inspection commands include:

```bash
kind get clusters
kubectl get nodes
```

## Local Container Registry

The platform provides a local OCI registry used by workloads running in the
Kind cluster.

Application repositories are responsible for building and publishing their
container images. `local-platform` provides and operates the registry.

Create the registry:

```bash
task registry:create
```

Show registry status:

```bash
task registry:status
```

List repositories currently published to the registry:

```bash
task registry:images
```

List available tags for an image:

```bash
task registry:tags IMAGE=example-backend
```

For example:

```text
{"name":"example-backend","tags":["0.2.0"]}
```

Delete the registry:

```bash
task registry:delete
```

An image can also be pushed manually:

```bash
podman push \
  --tls-verify=false \
  localhost:5001/example-backend:0.2.0
```

## GitOps

The local platform includes Argo CD as the initial GitOps engine.

Argo CD is installed and operated by `local-platform`, while the desired state
of workloads is maintained separately in the `local-environments` repository.

The responsibility boundary is intentionally explicit:

```text
local-platform
  │
  ├── Kubernetes
  ├── Container Registry
  ├── Argo CD
  └── Gateway API
          │
          ▼
local-environments
          │
          │ desired state
          ▼
     Workloads
```

The GitOps engine itself is considered an implementation detail. The
architecture allows alternative GitOps tools, such as Flux, to be evaluated
alongside or instead of Argo CD in the future.

### Argo CD

Install Argo CD:

```bash
task argocd:install
```

Show its current status:

```bash
task argocd:status
```

Refresh Argo CD applications:

```bash
task argocd:refresh
```

Force a hard refresh, including cached manifests:

```bash
task argocd:refresh:hard
```

Delete Argo CD:

```bash
task argocd:delete
```

Application definitions and environment state are intentionally not maintained
in this repository.

The initial Argo CD applications are bootstrapped from `local-environments`.
After that bootstrap, normal workload changes are performed through Git and
reconciled by Argo CD.

## Gateway API

The local platform uses Kubernetes Gateway API for north-south HTTP routing.

Envoy Gateway is the initial Gateway API implementation.

`local-platform` owns:

* the Envoy Gateway controller
* the `GatewayClass`
* the shared `Gateway`

Workload-specific routing is owned by `local-environments` and expressed using
standard Gateway API resources such as `HTTPRoute`.

The responsibility boundary is:

```text
local-platform
        │
        ├── Envoy Gateway controller
        ├── GatewayClass
        └── Gateway
                 │
                 ▼
local-environments
        │
        └── HTTPRoute
                 │
                 ▼
              Service
                 │
                 ▼
              Workload
```

Keeping workload routes based on the standard Gateway API makes it possible to
experiment with alternative Gateway API implementations in the future without
necessarily changing application routing manifests.

### Envoy Gateway

Install Envoy Gateway and the Gateway API CRDs:

```bash
task envoy:install
```

Configure the local `GatewayClass` and `Gateway`:

```bash
task envoy:configure
```

Show Envoy Gateway status:

```bash
task envoy:status
```

Forward the local Gateway to the developer host:

```bash
task envoy:forward
```

The current local access method uses port forwarding because the Kind cluster
does not yet provide an external address for `LoadBalancer` services.

While the forward is running, workloads exposed through `HTTPRoute` can be
reached through:

```text
http://localhost:8080
```

For example:

```bash
curl http://localhost:8080/api/greeting
```

Delete Envoy Gateway:

```bash
task envoy:delete
```

A more complete local LoadBalancer solution is intentionally left for a future
increment. Possible approaches include `cloud-provider-kind` or other
Kubernetes networking implementations.

## Repository Structure

```text
.
├── .devcontainer/
├── manifests/
│   └── gateway/
│       └── envoy/
│           ├── gatewayclass.yaml
│           ├── gateway.yaml
│           └── kustomization.yaml
├── scripts/
├── Taskfile.yaml
├── dev.sh
└── README.md
```

The main entrypoints are deliberately few:

* `dev.sh` manages the developer environment.
* `Taskfile.yaml` exposes the operator-facing commands.
* `scripts/` contains reusable and non-trivial platform automation.
* `manifests/` contains declarative platform configuration owned by this
  repository.
* `.devcontainer/` defines the repository development environment.

Task provides the user-facing interface.

Reusable or non-trivial automation is implemented as shell scripts under
`scripts/`. Simple commands may be kept directly in the Taskfile when doing so
keeps the underlying operation visible and easy to understand.

## Design Principles

The repository follows the broader design principles and architecture decisions
documented in the `homelab` repository.

In particular:

* keep the developer host lightweight
* prefer reproducible environments
* expose common operations through Task
* keep repository responsibilities explicit
* prefer open and portable technologies
* prefer standard APIs where practical
* evolve the platform incrementally
* avoid abstractions before they solve a concrete problem

`local-platform` owns the platform itself.

Application source code belongs in application repositories, while desired
environment state and workload-specific routing belong in
`local-environments`.

