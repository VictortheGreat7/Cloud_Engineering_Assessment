# Runner Infrastructure

This directory contains Terraform configuration for the **self-hosted GitHub Actions runner** infrastructure only.

## Purpose

This is separated from the main application deployment to allow:
- **Independent lifecycle**: Runner VM persists while app is deployed/updated
- **Different apply timing**: Runner created once, app deployed frequently
- **Clear separation**: Infrastructure vs application concerns

## What's Included

- Runner VM (Ubuntu 22.04)
- Dedicated subnet for runner
- Network Security Group
- Public IP for SSH access
- Cloud-init automation

## Usage

### Initial Setup (One-time)

```bash
# 1. From main terraform directory, get outputs needed
cd ../
terraform output resource_group_name
terraform output vnet_name

# 2. Create SSH keys
mkdir -p ssh_keys
ssh-keygen -t rsa -b 4096 -C "github-runner" -f ssh_keys/id_rsa

# 3. Copy cloud-init template
cp ../cloud-init-template.yaml cloud-init.yaml.tpl

# 4. Navigate to runner-infra directory
cd runner-infra/

# 5. Uncomment resources in main.tf

# 6. Create terraform.tfvars.json
cat <<EOF > terraform.tfvars.json
{
  "resource_group_name": "<from step 1>",
  "vnet_name": "<from step 1>",
  "runner_token": "<get from GitHub>"
}
EOF

# 7. Deploy runner infrastructure
terraform init
terraform plan
terraform apply
```

### Updating Runner

If you need to update the runner (rare):

```bash
terraform plan
terraform apply
```

### Destroying Runner

To remove the runner infrastructure:

```bash
terraform destroy
```

## Relationship to Main Infrastructure

- **Depends on**: Main infrastructure must be deployed first (VNet, Resource Group)
- **Independent of**: Application deployments (those happen in ../app-deploy/)
- **Referenced by**: Workflow uses this runner for private cluster access

## Workflow Integration

After deploying runner infrastructure:
1. SSH to runner VM using output command
2. Configure runner with GitHub
3. Update `.github/workflows/build.yaml` deploy job to use `runs-on: [self-hosted, linux, x64]`
4. Application deployments will now use this runner
