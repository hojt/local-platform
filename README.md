# local-platform

Infrastructure for the local development platform.

## Purpose

This repository owns the local Kubernetes platform used during
development.

Current platform capabilities include:

-   containerized development environment
-   Kubernetes cluster
-   local container registry
-   GitOps
-   HTTP and HTTPS routing through Gateway API
-   TLS certificate management
-   local host integration for trusted HTTPS and hostname resolution
-   task-based automation

Current implementations include:

-   Dev Containers for the development environment
-   Kind for Kubernetes
-   Podman for container operations
-   Argo CD for GitOps
-   Envoy Gateway for Gateway API
-   cert-manager for certificate management

Future platform capabilities may include:

-   CI pipelines
-   externally reachable LoadBalancer services
-   observability

Alternative implementations may also be evaluated as the homelab
evolves.

Examples include:

-   Flux for GitOps
-   Cilium for networking and Gateway API
-   cloud-provider-kind for local LoadBalancer integration
-   Ingress
-   Traefik
-   HAProxy
-   Istio

Specific tools are generally treated as implementations of platform
capabilities rather than permanent architectural choices.

## Prerequisites

The developer host is intentionally kept lightweight.

Required on the host:

-   Fedora Atomic
-   Podman
-   Dev Container CLI
-   tmux
-   Git
-   terminal and editor of choice

Repository-specific tooling runs inside the Dev Container.

``` text
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

``` bash
./dev.sh
```

Inside the Dev Container, bring up the local platform:

``` bash
task up
```

The platform currently consists of:

``` text
Local Container Registry
          │
          ▼
     Kind Cluster
       │
       ├──────────────┬────────────────┐
       ▼              ▼                ▼
    Argo CD      Envoy Gateway    cert-manager
                      │                │
                      └───────┬────────┘
                              ▼
                         Gateway API
```

Inspect the running platform:

``` bash
task status
```

Or inspect individual components:

``` bash
task registry:status
task cluster:status
task argocd:status
task envoy:status
task cert-manager:status
```

The desired state of workloads is maintained separately in
`local-environments`.

After the platform is running, bootstrap the Argo CD applications from
that repository:

``` bash
task argocd:bootstrap
```

From that point, workload changes are reconciled from Git.

When host access to workloads through the Gateway API is needed, forward
the local Envoy Gateway:

``` bash
task envoy:forward
```

The forward exposes the Gateway over HTTP on port 8080 and HTTPS on port
8443.

Without host integration, an HTTPS route can be tested explicitly with
curl:

``` bash
curl -k \
  --resolve example.local:8443:127.0.0.1 \
  https://example.local:8443/api/greeting
```

For a more convenient local workflow, export the platform CA, trust it
on the developer host, and add the local hostname mapping as described
in [Local Host Integration](#local-host-integration).

When finished, tear down the local platform:

``` bash
task down
```

The golden path is intentionally small:

``` text
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

Start a new repository-specific tmux session, or reconnect to an
existing one:

``` bash
./dev.sh
```

Rebuild the Dev Container when its definition has changed:

``` bash
./dev.sh rebuild
```

`dev.sh` verifies host prerequisites, starts or reuses the
repository-specific tmux session, starts the Dev Container, and opens a
shell inside it.

Most repository operations are exposed through Task:

``` bash
task --list
```

### Dev Container

The Dev Container provides the tooling required to develop and operate
the local platform.

The normal entrypoint is `./dev.sh`, but the Dev Container can also be
operated manually.

Build the Dev Container:

``` bash
devcontainer build \
  --workspace-folder . \
  --docker-path podman
```

Start it:

``` bash
devcontainer up \
  --workspace-folder . \
  --docker-path podman
```

Open a shell inside it:

``` bash
devcontainer exec \
  --workspace-folder . \
  --docker-path podman \
  bash
```

Personal developer configuration remains outside the repository where
practical. Selected host configuration, such as Git and editor
configuration, may be mounted into the Dev Container.

## Platform Lifecycle

The complete local platform can normally be managed through:

``` bash
task up
task status
task down
```

`task up` currently brings up:

``` text
registry
   │
   ▼
cluster
   │
   ├──────────────┬────────────────┐
   ▼              ▼                ▼
Argo CD      Envoy Gateway    cert-manager
                  │                │
                  └───────┬────────┘
                          ▼
                    Gateway config
```

Individual components also expose lifecycle tasks for development,
troubleshooting, and experimentation.

This separation keeps the common workflow simple while still allowing
each platform component to be operated independently.

## Kubernetes

The local platform currently uses Kind to provide Kubernetes.

The Kubernetes cluster lifecycle is owned by `local-platform`. Kind is
the current implementation and may be replaced or complemented by other
Kubernetes distributions as the homelab evolves.

Create the cluster:

``` bash
task cluster:create
```

Show cluster status:

``` bash
task cluster:status
```

Delete the cluster:

``` bash
task cluster:delete
```

Useful direct inspection commands include:

``` bash
kind get clusters
kubectl get nodes
```

## Local Container Registry

The platform provides a local OCI registry used by workloads running in
the Kind cluster.

Application repositories are responsible for building and publishing
their container images. `local-platform` provides and operates the
registry.

Create the registry:

``` bash
task registry:create
```

Show registry status:

``` bash
task registry:status
```

List repositories currently published to the registry:

``` bash
task registry:images
```

List available tags for an image:

``` bash
task registry:tags IMAGE=example-backend
```

For example:

``` text
{"name":"example-backend","tags":["0.2.0"]}
```

Delete the registry:

``` bash
task registry:delete
```

An image can also be pushed manually:

``` bash
podman push \
  --tls-verify=false \
  localhost:5001/example-backend:0.2.0
```

## GitOps

The local platform includes Argo CD as the initial GitOps engine.

Argo CD is installed and operated by `local-platform`, while the desired
state of workloads is maintained separately in the `local-environments`
repository.

The responsibility boundary is intentionally explicit:

``` text
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
architecture allows alternative GitOps tools, such as Flux, to be
evaluated alongside or instead of Argo CD in the future.

### Argo CD

Install Argo CD:

``` bash
task argocd:install
```

Show its current status:

``` bash
task argocd:status
```

Refresh Argo CD applications:

``` bash
task argocd:refresh
```

Force a hard refresh, including cached manifests:

``` bash
task argocd:refresh:hard
```

Delete Argo CD:

``` bash
task argocd:delete
```

Application definitions and environment state are intentionally not
maintained in this repository.

The initial Argo CD applications are bootstrapped from
`local-environments`. After that bootstrap, normal workload changes are
performed through Git and reconciled by Argo CD.

## Certificate Management

The local platform uses cert-manager for TLS certificate management.

The local certificate hierarchy consists of a self-signed bootstrap
issuer and a locally generated root CA. The root CA is then used to
issue certificates for the shared Gateway. This allows the host to trust
one local CA instead of trusting individual leaf certificates.

Install cert-manager:

``` bash
task cert-manager:install
```

Configure the local issuers and root CA:

``` bash
task cert-manager:configure
```

Show cert-manager status:

``` bash
task cert-manager:status
```

Export the current local root CA from Kubernetes:

``` bash
task cert-manager:export-ca
```

The generated CA is local development infrastructure. Recreating the
platform may generate a new root CA, in which case the host trust store
must be updated to trust the newly exported CA.

Delete cert-manager:

``` bash
task cert-manager:delete
```

The local CA is intended for development only. A different certificate
issuer can be introduced when environments require publicly or
internally trusted certificates.

## Gateway API

The local platform uses Kubernetes Gateway API for north-south HTTP and
HTTPS routing.

Envoy Gateway is the initial Gateway API implementation.

`local-platform` owns:

-   the Envoy Gateway controller
-   the `GatewayClass`
-   the shared `Gateway`
-   the shared HTTP and HTTPS listeners
-   local TLS certificate integration

Workload-specific routing is owned by `local-environments` and expressed
using standard Gateway API resources such as `HTTPRoute`.

The responsibility boundary is:

``` text
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

Keeping workload routes based on the standard Gateway API makes it
possible to experiment with alternative Gateway API implementations in
the future without necessarily changing application routing manifests.

### Envoy Gateway

Install Envoy Gateway and the Gateway API CRDs:

``` bash
task envoy:install
```

Configure the local `GatewayClass` and `Gateway`:

``` bash
task envoy:configure
```

Show Envoy Gateway status:

``` bash
task envoy:status
```

Forward the local Gateway to the developer host:

``` bash
task envoy:forward
```

The current local access method uses port forwarding because the Kind
cluster does not yet provide an external address for `LoadBalancer`
services.

While the forward is running, workloads exposed through `HTTPRoute` can
be reached through:

``` text
HTTP:  http://localhost:8080
HTTPS: https://localhost:8443
```

HTTPS routes use their configured Gateway API hostname. For example:

``` bash
curl -k \
  --resolve example.local:8443:127.0.0.1 \
  https://example.local:8443/api/greeting
```

The local Gateway terminates TLS using certificates managed by
cert-manager.

Delete Envoy Gateway:

``` bash
task envoy:delete
```

A more complete local LoadBalancer solution is intentionally left for a
future increment. Possible approaches include `cloud-provider-kind` or
other Kubernetes networking implementations.

## Local Host Integration

The Kubernetes platform is intentionally isolated from permanent host
configuration, but a small amount of optional host integration makes
local HTTPS considerably more convenient.

There are two separate concerns:

1.  trust the local root CA on the Fedora host
2.  resolve local Gateway hostnames to `127.0.0.1`

### Certificate trust

Export the root CA from the running platform inside the Dev Container:

``` bash
task cert-manager:export-ca
```

Install the exported CA in the Fedora host trust store using the
host-side helper created for this purpose. The helper can also remove
the certificate again when it is no longer needed.

Because the root CA is generated by the local platform, a clean platform
bootstrap may replace it. When that happens, export the new CA and
refresh the host trust entry.

This keeps certificate generation owned by Kubernetes while host trust
remains an explicit developer-machine operation.

### Hostname resolution

`hosts.sh` manages the local `/etc/hosts` entry used by the example
Gateway hostname.

Add the mapping:

``` bash
./hosts.sh add
```

This maps:

``` text
127.0.0.1 example.local
```

Remove it again with:

``` bash
./hosts.sh remove
```

The helper keeps this host-specific operation outside the Dev Container
and makes the change explicit and reversible.

With the CA trusted, the hostname configured, and `task envoy:forward`
running, the example backend can be reached without `-k` or `--resolve`:

``` bash
curl https://example.local:8443/api/greeting
```

This is the preferred local developer experience while port forwarding
remains the mechanism used to expose the Gateway.

## Repository Structure

``` text
.
├── .devcontainer/
├── manifests/
│   ├── cert-manager/
│   │   ├── selfsigned/
│   │   │   ├── clusterissuer.yaml
│   │   │   └── kustomization.yaml
│   │   └── ...
│   └── gateway/
│       └── envoy/
│           ├── gatewayclass.yaml
│           ├── gateway.yaml
│           └── kustomization.yaml
├── scripts/
├── Taskfile.yaml
├── dev.sh
├── hosts.sh
└── README.md
```

The main entrypoints are deliberately few:

-   `dev.sh` manages the developer environment.
-   `Taskfile.yaml` exposes the operator-facing commands.
-   `scripts/` contains reusable and non-trivial platform automation.
-   `manifests/` contains declarative platform configuration owned by
    this repository.
-   `hosts.sh` manages host-side local hostname resolution.
-   `.devcontainer/` defines the repository development environment.

Task provides the user-facing interface.

Reusable or non-trivial automation is implemented as shell scripts under
`scripts/`. Simple commands may be kept directly in the Taskfile when
doing so keeps the underlying operation visible and easy to understand.

Host-specific operations that require privileges or modify the developer
machine are kept explicit rather than hidden inside `task up`.

## Design Principles

The repository follows the broader design principles and architecture
decisions documented in the `homelab` repository.

In particular:

-   keep the developer host lightweight
-   prefer reproducible environments
-   expose common operations through Task
-   keep repository responsibilities explicit
-   prefer open and portable technologies
-   prefer standard APIs where practical
-   evolve the platform incrementally
-   avoid abstractions before they solve a concrete problem

`local-platform` owns the platform itself.

Application source code belongs in application repositories, while
desired environment state and workload-specific routing belong in
`local-environments`.
