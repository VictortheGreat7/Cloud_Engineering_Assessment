# Application Deployment

This directory contains Terraform configuration for **deploying the application** to an existing AKS cluster.

## Purpose

This is separated from infrastructure provisioning to allow:
- **Frequent updates**: Deploy app changes without touching infrastructure
- **Different apply timing**: Infrastructure stable, apps deploy often
- **Clear separation**: Infrastructure vs application deployment

## What's Included

- Kubernetes namespace
- Backend deployment (Flask API)
- Frontend deployment (React + nginx)
- Services (ClusterIP)
- Ingress rules
- Network policies
- Load test jobs

## Usage

### Prerequisites

1. Main infrastructure must be deployed (AKS cluster, VNet, etc.)
2. Docker images must be built and pushed to Docker Hub
3. kubectl must be configured to access the cluster

### Deploy Application

```bash
# From this directory
terraform init
terraform plan
terraform apply
```

### Update Application

After building and pushing new Docker images:

```bash
# Update image tags in variables or use workspace
terraform apply -var="backend_image_tag=abc123" -var="frontend_image_tag=abc123"
```

### Destroy Application

To remove the application from the cluster:

```bash
terraform destroy
```

## Relationship to Other Terraform Configs

- **Depends on**: Main infrastructure (../main.tf, ../network.tf, etc.)
- **Independent of**: Runner infrastructure (../runner-infra/)
- **Used by**: GitHub Actions workflow for continuous deployment

## Workflow Integration

The `.github/workflows/build.yaml` workflow:
1. Builds and pushes Docker images (build job)
2. Deploys application using this configuration (deploy job)
3. Can run on GitHub-hosted or self-hosted runner
4. Uses separate terraform state for app deployments

## Current Implementation Note

Currently, the application deployment is in `../deploy.tf` in the parent directory.
For full separation, you would:
1. Move deploy.tf here
2. Update backend configuration for separate state
3. Update workflow to use this directory for app deployments
4. Keep parent directory for infrastructure only

This directory structure is prepared for that migration.
