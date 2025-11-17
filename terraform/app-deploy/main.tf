# Application Deployment Configuration
# This Terraform configuration deploys ONLY the application to an existing AKS cluster
# It is separate from the infrastructure provisioning

# This configuration assumes:
# 1. AKS cluster exists (created by main terraform in parent directory)
# 2. kubectl is configured to access the cluster
# 3. Docker images are already built and pushed

# Include Kubernetes deployment resources from parent directory
# The actual deployment is in ../deploy.tf
# This directory exists to allow separate terraform state for app deployments

# Note: In practice, you would copy deploy.tf here and update paths
# For now, we reference the parent directory's deployment configuration

# Placeholder - see ../deploy.tf for actual deployment configuration
