# Terraform Configuration Separation Guide

## Overview

The Terraform configuration is separated into distinct concerns to match the self-hosted branch architecture pattern:

1. **Base Infrastructure** (`terraform/*.tf`) - AKS cluster, VNet, core resources
2. **Runner Infrastructure** (`terraform/runner-infra/`) - Self-hosted runner VM (optional)
3. **Application Deployment** (`terraform/deploy.tf`) - Kubernetes deployments

## Directory Structure

```
terraform/
├── main.tf                    # AKS cluster, base infrastructure
├── network.tf                 # VNet, subnets, NAT gateway
├── deploy.tf                  # Application deployment (K8s resources)
├── netpolicy.tf               # Network policies
├── monitoring.tf              # Log Analytics, monitoring
├── outputs.tf                 # Outputs for other modules
├── variables.tf               # Input variables
├── providers.tf               # Provider configuration
├── backend.tf                 # Terraform state backend
├── self-hosted-runner.tf      # Legacy (see runner-infra/ instead)
├── runner-infra/              # SEPARATE: Runner VM infrastructure
│   ├── main.tf                # Runner VM, subnet, NSG
│   ├── data.tf                # Data sources to reference main infra
│   ├── variables.tf           # Runner-specific variables
│   ├── providers.tf           # Provider with separate state
│   └── README.md              # Runner-specific documentation
└── app-deploy/                # FUTURE: Application deployment separation
    ├── main.tf                # Would contain deploy.tf resources
    ├── README.md              # Deployment-specific documentation
    └── ...
```

## Separation Strategy

### 1. Base Infrastructure (Rarely Changes)

**Location**: `terraform/*.tf` (main directory)

**Contains**:
- Resource Group
- Virtual Network and Subnets
- NAT Gateway
- AKS Cluster
- NGINX Ingress Controller
- Log Analytics Workspace
- Azure AD Integration
- RBAC Configuration

**Lifecycle**: Created once, rarely modified

**Deployment**: 
```bash
cd terraform/
terraform init
terraform apply -target=azurerm_resource_group.time_api_rg \
                -target=azurerm_kubernetes_cluster.time_api_cluster \
                -target=azurerm_virtual_network.time_api_vnet
```

### 2. Runner Infrastructure (Optional, One-time)

**Location**: `terraform/runner-infra/`

**Contains**:
- Runner VM (Ubuntu 22.04)
- Dedicated Subnet
- Network Security Group
- Public IP for SSH
- Cloud-init Configuration
- Managed Identity

**Lifecycle**: Created once if using private cluster, persists independently

**Deployment**:
```bash
# First, ensure base infrastructure is deployed
cd terraform/
terraform output resource_group_name
terraform output vnet_name

# Then deploy runner infrastructure
cd runner-infra/
terraform init
terraform apply
```

**State**: Separate state file (`runner-infra.terraform.tfstate`)

### 3. Application Deployment (Frequent Changes)

**Location**: `terraform/deploy.tf` (currently in main directory)

**Contains**:
- Kubernetes Namespace
- Backend Deployment (Flask API)
- Frontend Deployment (React + nginx)
- Services (ClusterIP)
- Ingress Rules
- Network Policies
- Load Test Jobs

**Lifecycle**: Deployed/updated frequently with each application change

**Deployment**:
```bash
cd terraform/
terraform init
terraform apply -target=kubernetes_deployment_v1.world_clock_backend \
                -target=kubernetes_deployment_v1.world_clock_frontend \
                -target=kubernetes_service_v1.world_clock_backend \
                -target=kubernetes_service_v1.world_clock_frontend \
                -target=kubernetes_ingress_v1.world_clock_ingress
```

**Future**: Could move to `app-deploy/` directory with separate state

## GitHub Actions Workflow Separation

The `.github/workflows/build.yaml` workflow reflects this separation with distinct jobs:

### Job 1: Build (Always GitHub-hosted)
```yaml
build:
  runs-on: ubuntu-latest
  # Builds and pushes Docker images
  # No cluster access needed
```

### Job 2: Provision Infrastructure (GitHub-hosted, Rare)
```yaml
provision-infra:
  runs-on: ubuntu-latest
  if: ${{ github.event.inputs.provision_infrastructure == 'true' }}
  # Creates AKS cluster, VNet, core resources
  # Runs when infrastructure changes needed
```

### Job 3: Provision Runner (GitHub-hosted, One-time)
```yaml
provision-runner:
  runs-on: ubuntu-latest
  if: ${{ github.event.inputs.provision_runner == 'true' }}
  # Creates runner VM in separate terraform directory
  # Uses separate state file
  # Runs once for private cluster setup
```

### Job 4: Deploy Application (GitHub-hosted OR Self-hosted)
```yaml
deploy-app:
  runs-on: ubuntu-latest  # or [self-hosted, linux, x64]
  if: ${{ github.event.inputs.deploy_application != 'false' }}
  # Deploys application using targeted terraform apply
  # Runs frequently
  # Can use self-hosted runner for private cluster
```

## Workflow Inputs

The workflow accepts inputs to control what gets deployed:

```yaml
workflow_dispatch:
  inputs:
    provision_infrastructure: 'true' | 'false'  # Deploy base infra
    provision_runner: 'true' | 'false'           # Deploy runner VM
    deploy_application: 'true' | 'false'         # Deploy app
```

## Typical Usage Scenarios

### Scenario 1: Initial Setup (Public Cluster)

```bash
# Workflow inputs:
provision_infrastructure: true
provision_runner: false
deploy_application: true

# Result:
# 1. Base infrastructure created
# 2. Runner skipped
# 3. Application deployed
```

### Scenario 2: Initial Setup (Private Cluster)

```bash
# Workflow inputs:
provision_infrastructure: true
provision_runner: true
deploy_application: false

# Result:
# 1. Base infrastructure created
# 2. Runner VM created
# 3. SSH to runner, configure it
# 4. Update workflow deploy-app job to use self-hosted
# 5. Run workflow again with deploy_application: true
```

### Scenario 3: Application Update

```bash
# Workflow inputs:
provision_infrastructure: false
provision_runner: false
deploy_application: true

# Result:
# 1. Infrastructure skipped
# 2. Runner skipped
# 3. Only application redeployed
```

### Scenario 4: Destroy Runner

```bash
# Manual from command line:
cd terraform/runner-infra/
terraform destroy

# Or update workflow for destruction
```

## Benefits of This Separation

1. **Independent Lifecycles**
   - Infrastructure stable, application changes frequently
   - Runner persists, application updates don't affect it

2. **Separate State Files**
   - Runner infrastructure has its own state
   - Reduces risk of state corruption
   - Allows independent management

3. **Clear Dependencies**
   - Runner depends on base infrastructure
   - Application depends on base infrastructure
   - Runner and application are independent

4. **Workflow Flexibility**
   - Control what gets deployed via workflow inputs
   - Skip infrastructure on most runs
   - Deploy runner only when needed

5. **Cost Optimization**
   - Don't recreate infrastructure on every deploy
   - Runner VM persists (not recreated)
   - Only application pods restart

## Migration from Legacy Setup

If you have the legacy `self-hosted-runner.tf` in the main directory:

1. Resources are already commented out
2. New `runner-infra/` directory is the replacement
3. Use `runner-infra/` for new deployments
4. `self-hosted-runner.tf` can be removed (kept for reference)

## Comparison to Self-Hosted Branch

This architecture matches the self-hosted branch pattern:

| Aspect | Self-Hosted Branch | This Branch |
|--------|-------------------|-------------|
| Infrastructure separation | ✅ Yes | ✅ Yes |
| Runner in separate directory | ✅ Yes | ✅ Yes |
| Separate state files | ✅ Yes | ✅ Yes |
| Workflow separation | ✅ Yes | ✅ Yes |
| Targeted terraform apply | ✅ Yes | ✅ Yes |

## Next Steps

1. **Current State**: Separation structure is in place
2. **Optional Migration**: Move `deploy.tf` to `app-deploy/` directory
3. **Update Workflow**: Already configured with separated jobs
4. **Documentation**: All guides updated

The infrastructure is ready for both public and private cluster deployments with proper separation of concerns.
