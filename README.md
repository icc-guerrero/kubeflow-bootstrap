# Kubeflow FluxCD Bootstrap

A Helm chart for bootstrapping [Kubeflow](https://www.kubeflow.org/) on Kubernetes using [FluxCD](https://fluxcd.io/) GitOps principles.

## Overview

This project provides a declarative, GitOps-based approach to deploying Kubeflow on Kubernetes clusters. Instead of manually applying manifests, it leverages FluxCD's `GitRepository` and `Kustomization` resources to automatically sync and reconcile Kubeflow components from the [official Kubeflow manifests repository](https://github.com/kubeflow/manifests).

### Key Features

- **GitOps-Native**: Uses FluxCD for continuous reconciliation of Kubeflow components
- **Modular Architecture**: Enable/disable individual components based on your needs
- **Multi-Auth Support**: Integrated Dex authentication with OAuth2 Proxy and support for external identity providers (Azure AD B2C, OIDC)
- **Dependency Management**: Proper ordering of component deployment with FluxCD dependencies
- **Configurable**: Extensive configuration options via Helm values

## Prerequisites

- Kubernetes cluster (v1.25+)
- [FluxCD](https://fluxcd.io/docs/installation/) installed on the cluster
- [Helm](https://helm.sh/) v3+
- `kubectl` configured to access your cluster

## Architecture

The chart deploys Kubeflow components in a specific order using FluxCD Kustomizations:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Infrastructure                              │
├─────────────────────────────────────────────────────────────────────┤
│  cert-manager  →  Istio CRDs  →  Istio Install  →  Cluster Gateway  │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         Authentication                              │
├─────────────────────────────────────────────────────────────────────┤
│              Dex  →  OAuth2 Proxy  →  Central Dashboard             │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      Kubeflow Components                            │
├─────────────────────────────────────────────────────────────────────┤
│  Pipelines │ Notebooks │ Profiles │ Training Operator │ KServe      │
└─────────────────────────────────────────────────────────────────────┘
```

## Installation

### Add the Helm Repository

```bash
helm repo add kubeflow-bootstrap https://icc-guerrero.github.io/kubeflow-bootstrap
helm repo update
```

### Install the Chart

```bash
helm install kubeflow kubeflow-bootstrap/kubeflow-flux-bootstrap \
  --namespace kubeflow-system \
  --create-namespace \
  --values my-values.yaml
```

### Install from Source

```bash
git clone https://github.com/icc-guerrero/kubeflow-bootstrap.git
cd kubeflow-bootstrap
helm install kubeflow ./kubeflow \
  --namespace kubeflow-system \
  --create-namespace \
  --values my-values.yaml
```

## Configuration

### Basic Configuration

Create a `values.yaml` file with your configuration:

```yaml
# Project namespace (where FluxCD resources will be created)
namespaces:
  project: my-kubeflow

# Kubeflow version
kubeflow:
  manifestsRepo: https://github.com/kubeflow/manifests
  refTag: v1.10.1

# Enable/disable components
enable:
  certManager: true
  istio: true
  knative: true
  kserve: true
  dex: true
  centralDashboard: true
  pipelines: true
  notebooks: true
  profiles: true
  trainingOperator: true
```

### Authentication Configuration

Configure Dex for authentication:

```yaml
dex:
  # Public URL where Dex is accessible
  issuerUrl: "https://kubeflow.example.com/dex"
  logLevel: "info"
  skipApprovalScreen: true
  enablePasswordDB: true
  
  # Static users (for development/testing)
  staticPasswords:
    - email: "admin@example.com"
      hashFromEnv: "DEX_USER_PASSWORD"
      username: "admin"
      userID: "admin-id"

oauth2Proxy:
  enabled: true
  overlay: m2m-dex-only  # Options: m2m-dex-only, m2m-dex-and-kind, m2m-dex-and-eks
  cookieDomains:
    - "example.com"
  whitelistDomains:
    - "example.com"
```

### External Identity Provider (OIDC)

Configure an external identity provider like Azure AD B2C:

```yaml
dex:
  connectors:
    - type: oidc
      id: azure-b2c
      name: "Azure AD B2C"
      config:
        issuer: "https://your-tenant.b2clogin.com/your-tenant-id/your-policy/v2.0/"
        redirectURI: "https://kubeflow.example.com/dex/callback"
        clientID: "your-client-id"
        clientSecret: "your-client-secret"
        insecureSkipEmailVerified: true
        scopes:
          - openid
          - profile
          - email
```

## Components

| Component | Description | Default |
|-----------|-------------|---------|
| **cert-manager** | TLS certificate management | Enabled |
| **Istio** | Service mesh for traffic management and security | Enabled |
| **Knative Serving** | Serverless workload support (required for KServe) | Enabled |
| **Dex** | OpenID Connect identity provider | Enabled |
| **OAuth2 Proxy** | Authentication proxy | Enabled |
| **Central Dashboard** | Kubeflow web UI | Enabled |
| **Pipelines** | ML pipeline orchestration | Enabled |
| **Notebooks** | Jupyter notebook support | Enabled |
| **Profiles** | Multi-tenancy and namespace management | Enabled |
| **Training Operator** | Distributed training (TFJob, PyTorchJob, etc.) | Enabled |
| **KServe** | Model serving and inference | Enabled |

## Values Reference

### Namespace Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespaces.project` | Project namespace for FluxCD resources | `unicc-aihub` |
| `namespaces.certManager` | cert-manager namespace | `cert-manager` |
| `namespaces.istioSystem` | Istio system namespace | `istio-system` |
| `namespaces.knative` | Knative serving namespace | `knative-serving` |
| `namespaces.kubeflow` | Kubeflow namespace | `kubeflow` |
| `namespaces.oauth2proxy` | OAuth2 Proxy namespace | `oauth2-proxy` |
| `namespaces.auth` | Auth (Dex) namespace | `auth` |

### Component Toggles

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enable.certManager` | Deploy cert-manager | `true` |
| `enable.istio` | Deploy Istio service mesh | `true` |
| `enable.knative` | Deploy Knative Serving | `true` |
| `enable.kserve` | Deploy KServe | `true` |
| `enable.dex` | Deploy Dex identity provider | `true` |
| `enable.centralDashboard` | Deploy Central Dashboard | `true` |
| `enable.pipelines` | Deploy Kubeflow Pipelines | `true` |
| `enable.notebooks` | Deploy Notebook components | `true` |
| `enable.profiles` | Deploy Profiles controller | `true` |
| `enable.trainingOperator` | Deploy Training Operator | `true` |

### Timing Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kustomizations.intervals.default` | Reconciliation interval | `5m` |
| `kustomizations.timeouts.short` | Short timeout for simple resources | `5m` |
| `kustomizations.timeouts.medium` | Medium timeout | `10m` |
| `kustomizations.timeouts.long` | Long timeout for complex deployments | `15m` |

## Upgrading

To upgrade to a new version:

```bash
helm repo update
helm upgrade kubeflow kubeflow-bootstrap/kubeflow-flux-bootstrap \
  --namespace kubeflow-system \
  --values my-values.yaml
```

## Uninstallation

```bash
helm uninstall kubeflow --namespace kubeflow-system
```

> **Note**: This will remove FluxCD Kustomization resources. The actual Kubeflow components may take some time to be garbage collected by Kubernetes.

## Troubleshooting

### Check FluxCD Reconciliation Status

```bash
# List all Kustomizations
kubectl get kustomizations -n <project-namespace>

# Check a specific Kustomization
kubectl describe kustomization kubeflow-pipelines -n <project-namespace>
```

### View FluxCD Logs

```bash
kubectl logs -n flux-system deployment/kustomize-controller
```

### Common Issues

1. **Components stuck in "Not Ready"**: Check if dependencies are satisfied
2. **Authentication issues**: Verify Dex issuer URL matches your ingress configuration
3. **Timeout errors**: Increase `kustomizations.timeouts` values for slow clusters

## Development

### Releasing a New Version

1. Update the version in `kubeflow/Chart.yaml`
2. Run the release script:

```bash
./release.sh
```

This will:
- Package the Helm chart
- Update the Helm repository index
- Prepare files for publishing

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Kubeflow](https://www.kubeflow.org/) - The ML toolkit for Kubernetes
- [FluxCD](https://fluxcd.io/) - GitOps for Kubernetes
- [Kubeflow Manifests](https://github.com/kubeflow/manifests) - Official Kubeflow deployment manifests
