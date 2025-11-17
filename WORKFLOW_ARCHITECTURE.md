# GitHub Actions Workflow Architecture

## Overview

The `.github/workflows/build.yaml` workflow is designed to support **both public and private AKS cluster deployments** with minimal changes.

## Current Configuration (Public Cluster)

The workflow currently uses **GitHub-hosted runners** for all jobs, which works with public AKS clusters where the API server is accessible from the internet.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest    # GitHub-hosted runner
    # Builds and pushes Docker images
  
  deploy:
    runs-on: ubuntu-latest    # GitHub-hosted runner
    # Deploys to cluster via kubectl
```

## Why Split into Two Jobs?

The workflow is split into `build` and `deploy` jobs to prepare for self-hosted runner architecture:

1. **Build job** (GitHub-hosted):
   - Builds Docker images
   - Tests containers
   - Pushes to Docker Hub
   - ✅ No cluster access needed

2. **Deploy job** (GitHub-hosted OR self-hosted):
   - Runs Terraform apply
   - Configures kubectl
   - Deploys to Kubernetes
   - ⚠️ Requires cluster API access

## Self-Hosted Runner Configuration (Private Cluster)

When using a private AKS cluster (API server not publicly accessible), the deploy job must run on a self-hosted runner within the same VNet:

### Step 1: Enable Infrastructure

Uncomment resources in:
- `terraform/self-hosted-runner.tf` - VM infrastructure
- `terraform/main.tf` - Private cluster settings

### Step 2: Update Workflow

Change the deploy job:

```yaml
deploy:
  runs-on: [self-hosted, linux, x64]  # Changed from ubuntu-latest
  needs: build
```

### Step 3: Deploy

1. Deploy infrastructure: `terraform apply`
2. SSH to runner VM and configure
3. Subsequent deployments use self-hosted runner

## Workflow Execution Comparison

### Public Cluster (Current)
```
┌─────────────────┐     ┌──────────────────┐
│ GitHub-hosted   │────▶│  Public AKS      │
│ Runner          │     │  Cluster         │
│ (build + deploy)│     │  (API accessible)│
└─────────────────┘     └──────────────────┘
```

### Private Cluster (Self-Hosted)
```
┌─────────────────┐     ┌────────────────────────────────┐
│ GitHub-hosted   │     │  Azure VNet                    │
│ Runner (build)  │     │                                │
└─────────────────┘     │  ┌──────────────────┐         │
                        │  │ Self-hosted      │──────┐  │
                        │  │ Runner (deploy)  │      │  │
                        │  └──────────────────┘      │  │
                        │                            ▼  │
                        │  ┌──────────────────────────┐ │
                        │  │ Private AKS Cluster      │ │
                        │  │ (API not public)         │ │
                        │  └──────────────────────────┘ │
                        └────────────────────────────────┘
```

## Benefits of This Architecture

1. **Flexibility**: Works with both public and private clusters
2. **Security**: Can enforce private cluster with VNet isolation
3. **Efficiency**: Docker builds use GitHub infrastructure (faster, free)
4. **Simplicity**: Only one line needs to change in workflow
5. **Cost-effective**: Self-hosted runner only for deployments, not builds

## Security Considerations

### Public Cluster
- ✅ Network policies enforce pod-level security
- ⚠️ API server accessible from internet (with RBAC)
- ✅ Suitable for development/testing

### Private Cluster
- ✅ Network policies enforce pod-level security
- ✅ API server only accessible from VNet
- ✅ Self-hosted runner is the only deployment path
- ✅ Suitable for production environments

## Migration Path

Current setup makes it easy to migrate from public to private:

1. **Phase 1** (Current): Public cluster, GitHub-hosted runners
2. **Phase 2**: Deploy self-hosted runner VM (test)
3. **Phase 3**: Switch workflow to use self-hosted for deploy job
4. **Phase 4**: Enable private cluster mode
5. **Phase 5**: Production with full private cluster security

## Related Files

- `.github/workflows/build.yaml` - Main workflow (updated)
- `.github/workflows/build-with-self-hosted.yaml.example` - Reference example
- `terraform/self-hosted-runner.tf` - Runner VM infrastructure
- `terraform/main.tf` - Cluster configuration
- `SELF_HOSTED_RUNNER_GUIDE.md` - Detailed setup guide
