# Self-Hosted Runner Setup Guide

This guide explains how to configure the world clock application for deployment to a private AKS cluster using a self-hosted GitHub Actions runner.

## Overview

The self-hosted runner architecture provides enhanced security by:
- **Private AKS Cluster**: API server is not publicly accessible
- **VNet-isolated Runner**: GitHub Actions runner runs in the same VNet as the cluster
- **Network Policies**: Zero-trust security model restricts pod-to-pod communication
- **Secure Access**: Only the self-hosted runner can deploy to the cluster

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Virtual Network                         │  │
│  │                                                            │  │
│  │  ┌──────────────────┐    ┌──────────────────────────┐    │  │
│  │  │  Self-Hosted     │───▶│  Private AKS Cluster     │    │  │
│  │  │  Runner VM       │    │  (API server private)    │    │  │
│  │  │  - GitHub Runner │    │                          │    │  │
│  │  │  - kubectl       │    │  ┌────────────────────┐  │    │  │
│  │  │  - Azure CLI     │    │  │  Backend Pods      │  │    │  │
│  │  │  - kubelogin     │    │  │  Frontend Pods     │  │    │  │
│  │  └──────────────────┘    │  └────────────────────┘  │    │  │
│  │         │                └──────────────────────────┘    │  │
│  │         │ SSH Access                                     │  │
│  │         ▼                                                │  │
│  │  ┌──────────────────┐                                   │  │
│  │  │  Public IP       │◀── SSH from authorized IPs       │  │
│  │  └──────────────────┘                                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  GitHub Actions Workflow                                        │
│  ├─ Build Images (GitHub-hosted runner)                        │
│  └─ Deploy to Cluster (Self-hosted runner)                     │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. Azure subscription with appropriate permissions
2. GitHub repository with Actions enabled
3. Docker Hub account
4. SSH key pair for runner VM access

## Setup Steps

### 1. Generate SSH Keys

```bash
mkdir -p terraform/ssh_keys
ssh-keygen -t rsa -b 4096 -C "github-selfhosted-runner" -f terraform/ssh_keys/id_rsa
```

### 2. Enable Private Cluster in Terraform

Edit `terraform/main.tf` and uncomment the private cluster configuration:

```hcl
# Uncomment these lines:
private_cluster_enabled             = true
private_dns_zone_id                 = "System"
private_cluster_public_fqdn_enabled = false
```

### 3. Enable Self-Hosted Runner Resources

Edit `terraform/self-hosted-runner.tf` and uncomment all resources (remove the `/*` and `*/` comments).

### 4. Create cloud-init Template

Copy `cloud-init-template.yaml` to `cloud-init.yaml.tpl`:

```bash
cp terraform/cloud-init-template.yaml terraform/cloud-init.yaml.tpl
```

### 5. Get GitHub Runner Token

1. Go to your GitHub repository
2. Navigate to Settings → Actions → Runners
3. Click "New self-hosted runner"
4. Select Linux and x64
5. Copy the token from the configuration command

### 6. Add GitHub Secrets

Add the following secret to your repository:
- `RUNNER_TOKEN`: The GitHub Actions runner token

### 7. Deploy Infrastructure

First deployment uses GitHub-hosted runner to create infrastructure:

```bash
cd terraform
terraform init
terraform apply
```

**Important**: Note the `runner_ssh_command` and `runner_public_ip` from the outputs.

### 8. Configure the Runner

SSH into the runner VM and complete the configuration:

```bash
# SSH into the VM (use the command from Terraform output)
ssh -i ssh_keys/id_rsa adminuser@<RUNNER_PUBLIC_IP>

# Run the configuration script
/home/adminuser/configure-runner.sh https://github.com/YOUR-ORG/YOUR-REPO <RUNNER_TOKEN>

# Configure kubectl access
az login
az aks get-credentials --resource-group <RG_NAME> --name <CLUSTER_NAME>
kubelogin convert-kubeconfig -l azurecli

# Verify access
kubectl get nodes
```

### 9. Update GitHub Actions Workflow

Option A: Use the example workflow:
```bash
cp .github/workflows/build-with-self-hosted.yaml.example .github/workflows/build.yaml
```

Option B: Modify existing workflow:

Change the `deploy-infrastructure` job to use self-hosted runner:

```yaml
deploy-infrastructure:
  runs-on: [self-hosted, linux, x64, aks-private]
  needs: build-images
```

### 10. Verify Deployment

Push changes and trigger the workflow. The workflow will:
1. Build Docker images on GitHub-hosted runner
2. Deploy to private cluster using self-hosted runner

## Network Policies

The application uses comprehensive network policies that work with private clusters:

- **Default Deny**: All traffic denied by default
- **Selective Allow**: Only nginx ingress and load tests can access pods
- **DNS Access**: Pods can resolve DNS in kube-system namespace
- **No Inter-Pod Communication**: Frontend and backend communicate only through ingress

View active policies:
```bash
kubectl get networkpolicies -n time-api
kubectl describe networkpolicy backend-allow-dns-access -n time-api
```

## Security Considerations

### Advantages of Self-Hosted Runner Architecture

1. **Private API Server**: Cluster API is not exposed to the internet
2. **VNet Isolation**: All communication stays within Azure VNet
3. **Controlled Access**: Only the runner VM can access the cluster
4. **Network Policies**: Additional layer of security within the cluster
5. **Audit Trail**: All deployments logged through Azure and GitHub

### Security Best Practices

1. **Restrict SSH Access**: Update NSG rules to allow SSH only from specific IPs
2. **Rotate Runner Token**: Regenerate runner token periodically
3. **Monitor Runner Activity**: Check GitHub Actions logs regularly
4. **Update Runner**: Keep the runner software up to date
5. **Use Managed Identity**: Configure runner VM with managed identity for Azure access

## Troubleshooting

### Cannot Access Cluster from Runner

```bash
# Check AKS credentials
az aks get-credentials --resource-group <RG> --name <CLUSTER>

# Convert kubeconfig for AAD authentication
kubelogin convert-kubeconfig -l azurecli

# Test connection
kubectl get nodes
```

### Runner Not Appearing in GitHub

```bash
# Check runner service status
sudo systemctl status actions.runner.*

# View runner logs
sudo journalctl -u actions.runner.* -f

# Restart runner service
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Network Policy Issues

```bash
# Check if pods can access DNS
kubectl exec -it <pod-name> -n time-api -- nslookup kubernetes.default

# Test ingress connectivity
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://world-clock-backend-service.time-api.svc.cluster.local:80/health
```

## Cleanup

To remove all resources including the self-hosted runner:

```bash
cd terraform
terraform destroy
```

## Additional Resources

- [GitHub Self-Hosted Runners Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Azure Private Cluster Documentation](https://docs.microsoft.com/en-us/azure/aks/private-clusters)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
