#!/usr/bin/env bash
set -eu

# Define repository name for reuse
REPO_NAME=""

# Declare an associative array to hold secrets and their corresponding values
declare -A secrets=(
  ["AZURE_CREDENTIALS"]='{
    "clientId": "",
    "clientSecret": "",
    "subscriptionId": "",
    "tenantId": ""
  }'
  ["ARM_CLIENT_ID"]=""
  ["ARM_CLIENT_SECRET"]=""
  ["ARM_SUBSCRIPTION_ID"]=""
  ["ARM_TENANT_ID"]=""
  ["MY_USER_OBJECT_ID"]=""
  ["DOMAIN"]=""
  ["DOMAIN_API_USERNAME"]=""
  ["DOMAIN_API_TOKEN"]=""
  ["DOCKER_USERNAME"]=""
  ["DOCKER_PASSWORD"]=""
)

# Iterate over the secrets and set them using `gh secret set`
for secret_name in "${!secrets[@]}"; do
  gh secret set "$secret_name" --repo "$REPO_NAME" --body "${secrets[$secret_name]}"
done

echo "All secrets have been set successfully!"
