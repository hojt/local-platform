# local-platform

Infrastructure for the local development platform.

## Purpose

This repository owns the local Kubernetes platform used during
development.

Current platform capabilities include:

-   containerized development environment
-   Kubernetes cluster
-   local container registry
-   GitOps engine
-   HTTP and HTTPS routing through Gateway API
-   TLS certificate management
-   encrypted GitOps secret management
-   observability
-   direct local access to Gateway workloads
-   local host integration for trusted HTTPS, hostname resolution, and
    required kernel limits
-   task-based automation

Current implementations include:

-   Dev Containers for the development environment
-   Kind for Kubernetes
-   Podman for container operations
-   Argo CD for GitOps
-   Envoy Gateway for Gateway API
-   cert-manager for certificate management
-   Sealed Secrets for encrypted GitOps secrets
-   OpenTelemetry Collector for telemetry ingestion and processing
-   Prometheus for metrics storage and querying
-   Tempo for trace storage and querying
-   Grafana for observability exploration and visualization

Future platform capabilities may include:

-   CI pipelines
-   more complete local LoadBalancer integration
-   persistent observability storage
-   a dedicated log backend
-   richer dashboards and alerting

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
-   alternative OpenTelemetry-compatible observability backends

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

The rootless Podman and Kind platform also requires enough per-user
inotify instances on the host as the number of platform components
grows.

The recommended host value is:

``` text
fs.inotify.max_user_instances = 1024
```

The host-side `inotify.sh` helper can inspect and configure this limit.

This setting is kept outside `task up` because it modifies the developer
host.

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

Inspect and configure the host inotify limit when needed:

``` bash
./inotify.sh status
./inotify.sh install
```

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
          ├───────────────┬────────────────┬────────────────┐
          ▼               ▼                ▼                ▼
     Sealed Secrets   Observability      Argo CD       Gateway/TLS
                           │                              │
                           ├── Prometheus                 ├── Envoy Gateway
                           ├── Tempo                      └── cert-manager
                           ├── Grafana
                           └── OTel Collector
                                  │
                                  ▼
                              Telemetry
                                  │
                                  ▼
                               Workloads
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
task sealed-secrets:status
task observability:status
task prometheus:status
task tempo:status
task grafana:status
task otel:status
```

The desired state of workloads is maintained separately in
`local-environments`.

After the platform lifecycle has installed Argo CD, register the desired-state
applications from that repository:

``` bash
task argocd:bootstrap
```

From that point, workload changes are reconciled from Git.

Application repositories are responsible for building and publishing the
container images referenced by `local-environments`.

The local Gateway is reachable directly from the developer host through
fixed Kind port mappings. No long-running `kubectl port-forward` process
is required for normal workload access.

Configure the remaining host-side integration:

``` bash
./trust-ca.sh install
./hosts.sh install
```

The example backend can then be reached over HTTP:

``` bash
curl http://example.local:8080/api/greeting
```

Or over trusted HTTPS:

``` bash
curl https://example.local:8443/api/greeting
```

When finished, tear down the local platform:

``` bash
task down
```

Host-side inotify configuration, trust, and hostname configuration are
intentionally separate from the platform lifecycle. They can be managed
explicitly when needed:

``` bash
./inotify.sh remove
./trust-ca.sh remove
./hosts.sh remove
```

The golden path is intentionally small:

``` text
host prerequisites
    │
    ▼
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
Gateway API routing + observability
    │
    ▼
direct host access
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

`task up` currently brings up the platform in dependency-aware order:

``` text
registry
   │
   ▼
cluster
   │
   ▼
registry integration
   │
   ▼
Sealed Secrets key restore
   │
   ▼
Sealed Secrets controller
   │
   ▼
observability namespace
   │
   ├── Prometheus
   ├── Tempo
   ├── Grafana
   └── OpenTelemetry Collector
   │
   ▼
Argo CD
   │
   ▼
Envoy Gateway
   │
   ▼
cert-manager
   │
   ▼
Gateway configuration
```

Observability starts early so platform and workload telemetry can be
received as soon as producers become available. Its startup and status
order is `observability` -> Prometheus -> Tempo -> Grafana -> OpenTelemetry
Collector.

During shutdown the producer-facing OpenTelemetry Collector is removed
late, followed by Grafana, Tempo, Prometheus, and finally the shared
`observability` namespace.

The Kind cluster is created with fixed host-to-node port mappings for
the local Gateway:

``` text
127.0.0.1:8080 -> Kind node :30080
127.0.0.1:8443 -> Kind node :30443
```

The Envoy data plane uses the corresponding fixed NodePorts, providing
stable local access across clean platform bootstraps.

Sealed Secrets key material has a lifecycle independent of the disposable Kind
cluster.

During `task down`, the complete Sealed Secrets key set is backed up before the
controller and cluster are deleted. During `task up`, any existing key backup is
restored before the Sealed Secrets controller is installed.

``` text
task down
   │
   ├── sealed-secrets:backup
   ├── platform component deletion
   └── cluster:delete

task up
   │
   ├── cluster:create
   ├── sealed-secrets:restore
   ├── sealed-secrets:install
   └── remaining platform bootstrap
```

The restore operation is re-entrant. If no key backup exists, restore is
skipped and the controller creates its initial sealing key. If a backup exists,
the keys are restored before the controller starts so clean cluster recreation
does not create unnecessary replacement keys.

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

The Kind node exposes fixed container ports to the developer host so the
Envoy Gateway can be reached without port forwarding.

The current mapping is:

``` text
Host :8080  -> Kind node :30080
Host :8443  -> Kind node :30443
```

These mappings are established when the Kind node is created and
therefore depend on stable NodePorts on the Envoy Gateway service.

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
{"name":"example-backend","tags":["0.6.0"]}
```

Delete the registry:

``` bash
task registry:delete
```

An image can also be pushed manually:

``` bash
podman push \
  --tls-verify=false \
  localhost:5001/example-backend:0.6.0
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
  ├── cert-manager
  ├── Sealed Secrets controller
  ├── Observability platform
  └── Gateway API
          │
          ▼
local-environments
          │
          ├── desired workload state
          └── encrypted SealedSecret resources
          │
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

The initial Argo CD application definitions are owned by
`local-environments` and registered after the platform lifecycle has installed
Argo CD. After that registration, normal workload changes are performed through
Git and reconciled by Argo CD.

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

## Secret Management

The local platform uses Sealed Secrets for GitOps-compatible secret
management.

Plaintext secret values are not stored in Git. Workload repositories instead
store `SealedSecret` resources that contain encrypted secret data. The Sealed
Secrets controller runs inside the destination cluster and materializes normal
Kubernetes `Secret` resources there.

The responsibility boundary is:

``` text
local-platform
        │
        ├── Sealed Secrets controller
        └── sealing key lifecycle
                 │
                 ▼
local-environments
        │
        └── SealedSecret
                 │
                 ▼
        Kubernetes Secret
                 │
                 ▼
              Workload
```

### Sealed Secrets

Install the controller:

``` bash
task sealed-secrets:install
```

Show controller and sealing key status:

``` bash
task sealed-secrets:status
```

Back up the current sealing keys:

``` bash
task sealed-secrets:backup
```

Restore backed-up sealing keys:

``` bash
task sealed-secrets:restore
```

Delete the controller:

``` bash
task sealed-secrets:delete
```

The sealing keys are stored by the controller as Kubernetes TLS secrets.
Automatic key renewal may create additional keys over time. Old keys remain
important because existing `SealedSecret` resources may still depend on them.

The backup therefore contains the complete current key set, not only the newest
key.

Local backups are stored under:

``` text
.local/sealed-secrets/keys.yaml
```

The `.local/` directory is excluded from Git.

The backup contains private cryptographic key material and must be treated as
sensitive persistent state. The local file is sufficient for development and
recovery testing, but stronger external backup protection is expected for
non-local environments.

The normal platform lifecycle automatically integrates key backup and restore:

``` text
clean shutdown
    │
    ▼
backup complete sealing key set
    │
    ▼
delete disposable cluster

create new cluster
    │
    ▼
restore existing sealing keys
    │
    ▼
install Sealed Secrets controller
    │
    ▼
existing SealedSecret ciphertext remains decryptable
```

This keeps the Kubernetes cluster disposable while allowing encrypted GitOps
state to remain stable across cluster recreation.

The explicit backup and restore tasks remain available for troubleshooting,
disaster-recovery exercises, and manual key lifecycle operations.

## Observability

The local platform uses an OpenTelemetry-first observability
architecture.

Application workloads export telemetry using OpenTelemetry Protocol
(OTLP). The OpenTelemetry Collector provides a stable ingestion and
processing layer between workloads and observability backends.

The current architecture is:

``` text
Workload
   │
   │ OTLP
   ▼
OpenTelemetry Collector
   │
   ├── logs ────────► debug exporter
   │
   ├── traces ──────► debug exporter
   │       │
   │       └────────► Tempo
   │                   :4317 OTLP/gRPC
   │                   :3200 query API
   │                         │
   │                         ▼
   │                      Grafana
   │
   └── metrics
          │
          ├─────────► debug exporter
          │
          ▼
   Prometheus exporter
        :8889
          │
          │ scrape
          ▼
      Prometheus
          │
          │ PromQL
          ▼
        Grafana
```

The current implementation intentionally keeps the stack small. Metrics have
a storage and query backend in Prometheus. Traces are exported to both the
detailed Collector debug exporter and Tempo using OTLP/gRPC. Logs remain
exported only through the debug exporter, and the metrics and logs pipelines
are otherwise unchanged.

All observability components currently share the `observability`
namespace. The namespace has its own lifecycle and is not owned by any
individual observability component.

### OpenTelemetry Collector

The OpenTelemetry Collector receives OTLP over:

``` text
gRPC: 4317
HTTP: 4318
```

Install the Collector:

``` bash
task otel:install
```

Show Collector status:

``` bash
task otel:status
```

Inspect recently received telemetry:

``` bash
kubectl \
  --context kind-local \
  --namespace observability \
  logs deployment/otel-collector \
  --since=2m
```

Follow telemetry live:

``` bash
kubectl \
  --context kind-local \
  --namespace observability \
  logs deployment/otel-collector \
  --follow
```

Delete the Collector:

``` bash
task otel:delete
```

The metrics pipeline also exposes Prometheus-compatible metrics on port
`8889`.

For troubleshooting, the endpoint can be inspected directly using a
temporary port forward:

``` bash
kubectl \
  --context kind-local \
  --namespace observability \
  port-forward service/otel-collector 8889:8889
```

Then:

``` bash
curl --silent http://localhost:8889/metrics
```

The verified application trace flow is:

``` text
browser frontend span
    -> W3C trace context
    -> Quarkus backend span
    -> OpenTelemetry Collector
    -> Tempo
    -> Grafana Explore
```

### Prometheus

Prometheus provides metrics storage and PromQL querying.

It scrapes the OpenTelemetry Collector's Prometheus exporter rather than
scraping application workloads directly:

``` text
otel-collector.observability.svc:8889
```

Install Prometheus:

``` bash
task prometheus:install
```

Show Prometheus status:

``` bash
task prometheus:status
```

Delete Prometheus:

``` bash
task prometheus:delete
```

For local exploration, expose the UI temporarily:

``` bash
kubectl \
  --context kind-local \
  --namespace observability \
  port-forward service/prometheus 9090:9090
```

The UI is then available at:

``` text
http://localhost:9090
```

Example application metrics include:

``` text
http_server_requests_milliseconds_count
jvm_classes_loaded
```

Prometheus currently uses disposable local storage. Persistence and
retention are intentionally deferred until they solve a concrete
development need.

### Tempo

Tempo provides the local tracing backend. It runs in monolithic,
single-binary mode and receives OTLP/gRPC internally on port `4317`.
Its query API is available only inside the cluster on port `3200`; Tempo is
not exposed outside the cluster.

Tempo uses local ephemeral storage through an `emptyDir` mounted at
`/var/tempo`:

``` text
WAL:          /var/tempo/wal
trace blocks: /var/tempo/blocks
```

Trace data is lost when the Tempo pod is recreated.

Install Tempo:

``` bash
task tempo:install
```

Show Tempo status:

``` bash
task tempo:status
```

Delete Tempo:

``` bash
task tempo:delete
```

Persistent trace storage, object storage, the metrics generator, span
metrics, service graphs, exemplars, and deeper Prometheus/Tempo correlation
remain deferred until a concrete need is demonstrated.

### Grafana

Grafana provides the initial observability user interface.

Prometheus is provisioned declaratively as Grafana's default datasource:

``` text
http://prometheus.observability.svc:9090
```

Tempo is provisioned declaratively as Grafana's tracing datasource:

``` text
http://tempo.observability.svc:3200
```

No manual datasource setup should be required after a clean platform
bootstrap.

Install Grafana:

``` bash
task grafana:install
```

Show Grafana status:

``` bash
task grafana:status
```

Delete Grafana:

``` bash
task grafana:delete
```

Expose Grafana temporarily to the developer host:

``` bash
kubectl \
  --context kind-local \
  --namespace observability \
  port-forward service/grafana 3000:3000
```

Grafana is then available at:

``` text
http://localhost:3000
```

Grafana remains available to the developer host through the temporary
`kubectl port-forward` above. The current focus is manual exploration and
learning through PromQL and Grafana Explore; traces can be inspected in
Explore by trace ID.

Dashboards will be added incrementally after useful queries and
visualizations have first been understood and validated manually.

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
-   the local exposure of the Gateway data plane

Workload-specific routing is owned by `local-environments` and expressed
using standard Gateway API resources such as `HTTPRoute`.

The responsibility boundary is:

``` text
local-platform
        │
        ├── Envoy Gateway controller
        ├── GatewayClass
        ├── Gateway
        └── local Gateway exposure
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

The Envoy data plane uses stable NodePorts for the shared Gateway:

``` text
HTTP:  30080
HTTPS: 30443
```

The Kind control-plane node maps these ports directly to the developer
host:

``` text
127.0.0.1:8080 -> 30080
127.0.0.1:8443 -> 30443
```

This makes the Gateway directly reachable from the host without
requiring a long-running `kubectl port-forward` process.

With local hostname resolution configured, HTTP routes are available
through:

``` bash
curl http://example.local:8080/api/greeting
```

With the local root CA also trusted, HTTPS routes are available through:

``` bash
curl https://example.local:8443/api/greeting
```

The NodePorts are intentionally fixed because Kind port mappings are
configured when the cluster is created and therefore need stable
destination ports.

The local Gateway terminates TLS using certificates managed by
cert-manager.

For troubleshooting, the Gateway can still be exposed temporarily using:

``` bash
task envoy:forward
```

Port forwarding is not required for normal local development.

Delete Envoy Gateway:

``` bash
task envoy:delete
```

The current host ports are deliberately non-privileged ports. More
transparent local access on ports 80 and 443 can be evaluated separately
without changing the Gateway API routing model.

### inotify exhaustion

The Envoy data plane uses inotify and may fail during startup when the
host's per-user inotify instance limit is exhausted.

A typical symptom is an Envoy `CrashLoopBackOff` with an error similar
to:

``` text
assert failure: inotify_fd_ >= 0
Consider increasing value of fs.inotify.max_user_watches and/or
fs.inotify.max_user_instances via sysctl
```

For this local rootless Podman and Kind environment, configure the host
through:

``` bash
./inotify.sh install
```

See [Local Host Integration](#local-host-integration) for details.

## Local Host Integration

The Kubernetes platform is intentionally isolated from permanent host
configuration, but a small amount of optional or required host
integration makes local development considerably more reliable and
convenient.

There are three separate concerns:

1.  provide sufficient inotify resources for the rootless container
    platform
2.  trust the local root CA on the Fedora host
3.  resolve local Gateway hostnames to `127.0.0.1`

These operations are explicit and reversible. They are not hidden inside
`task up` because they modify the developer host.

### inotify limits

The local platform runs multiple services through rootless Podman and
Kind. As the platform grows, the Fedora host's default limit for
per-user inotify instances may be too low.

Envoy Gateway in particular requires an available inotify instance
during data-plane startup. When the limit is exhausted, Envoy may enter
`CrashLoopBackOff`.

The platform currently recommends:

``` text
fs.inotify.max_user_instances = 1024
```

Inspect the current value:

``` bash
./inotify.sh status
```

Configure the recommended value:

``` bash
./inotify.sh install
```

The helper persists the host configuration under `/etc/sysctl.d/` and
applies it immediately.

Remove the repository-managed setting and reload the remaining host
sysctl configuration:

``` bash
./inotify.sh remove
```


Only `fs.inotify.max_user_instances` is adjusted because that is the
limit currently demonstrated to be relevant to this platform. The
`fs.inotify.max_user_watches` limit is left unchanged until a concrete
need requires otherwise.

### Certificate trust

Export the root CA from the running platform inside the Dev Container:

``` bash
task cert-manager:export-ca
```

On the Fedora host, install the exported CA:

``` bash
./trust-ca.sh install
```

Remove it again with:

``` bash
./trust-ca.sh remove
```

Because the root CA is generated by the local platform, a clean platform
bootstrap may replace it. When that happens, export the new CA and
reinstall the host trust entry.

This keeps certificate generation owned by Kubernetes while host trust
remains an explicit developer-machine operation.

### Hostname resolution

`hosts.sh` manages the local `/etc/hosts` entry used by the example
Gateway hostname.

Install the mapping:

``` bash
./hosts.sh install
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

### Local access

With hostname resolution configured:

``` bash
curl http://example.local:8080/api/greeting
```

With both hostname resolution and the local CA installed:

``` bash
curl https://example.local:8443/api/greeting
```

No `-k`, `--resolve`, or long-running port-forward process is required
for the normal HTTPS workflow.

The resulting local request path is:

``` text
Developer Host
      │
      │ example.local:8080 / :8443
      ▼
127.0.0.1
      │
      ▼
Kind extraPortMappings
      │
      ├── :8080  -> node :30080
      └── :8443  -> node :30443
                         │
                         ▼
                    Envoy Gateway
                         │
                         ▼
                     HTTPRoute
                         │
                         ▼
                       Service
                         │
                         ▼
                      Workload
```

## Repository Structure

``` text
.
├── .devcontainer/
├── .local/
│   └── sealed-secrets/
│       └── keys.yaml
├── manifests/
│   ├── cert-manager/
│   │   ├── selfsigned/
│   │   │   ├── clusterissuer.yaml
│   │   │   └── kustomization.yaml
│   │   └── ...
│   ├── gateway/
│   │   └── envoy/
│   │       ├── gatewayclass.yaml
│   │       ├── gateway.yaml
│   │       ├── kustomization.yaml
│   │       └── ...
│   ├── grafana/
│   │   ├── configmap-datasources.yaml
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   ├── kind/
│   │   └── ...
│   ├── observability/
│   │   └── namespace.yaml
│   ├── otel/
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   ├── prometheus/
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   └── tempo/
│       ├── configmap.yaml
│       ├── deployment.yaml
│       ├── kustomization.yaml
│       └── service.yaml
├── scripts/
├── Taskfile.yml
├── dev.sh
├── hosts.sh
├── inotify.sh
├── trust-ca.sh
└── README.md
```

The main entrypoints are deliberately few:

-   `dev.sh` manages the developer environment.
-   `Taskfile.yml` exposes the operator-facing commands.
-   `scripts/` contains reusable and non-trivial platform automation.
-   `manifests/` contains declarative platform configuration owned by
    this repository.
-   `hosts.sh` manages host-side local hostname resolution.
-   `inotify.sh` manages the host-side inotify instance limit required
    by the rootless local platform.
-   `trust-ca.sh` manages host-side trust of the local development CA.
-   `.devcontainer/` defines the repository development environment.
-   `.local/` contains generated local state, including sensitive Sealed
    Secrets key backups, and is excluded from Git.

Task provides the user-facing interface inside the Dev Container.

Reusable or non-trivial platform automation is implemented as shell
scripts under `scripts/`. Simple commands may be kept directly in the
Taskfile when doing so keeps the underlying operation visible and easy
to understand.

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
-   use OpenTelemetry as the application-facing observability boundary
-   keep observability backends replaceable behind that boundary
-   never store plaintext workload secrets or private sealing keys in Git
-   keep recovery-critical key material independent of disposable clusters
-   evolve the platform incrementally
-   validate small capabilities manually before automating them
-   avoid abstractions before they solve a concrete problem

`local-platform` owns the platform itself.

Application source code belongs in application repositories, while
desired environment state and workload-specific routing belong in
`local-environments`.
