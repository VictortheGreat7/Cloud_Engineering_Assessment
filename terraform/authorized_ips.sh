#!/bin/bash

# Check if the curl command exists and install it if it doesn't
if ! sudo which curl &> /dev/null; then
  echo "Error: curl command not found. Installing curl..."
  sudo apt-get update
  sudo apt-get install -y curl
fi

# Get the ip address of the current machine
IP_ADDRESS=$(curl -s ifconfig.me)/32

# Terraform variables file
TFVARS_FILE="terraform.tfvars"
# Kubernetes ingress file
K8SINGRESS_FILE="../microservices_manifests/ingress.yaml"

# Check if the curl command was successful
if [ $? -eq 0 ]; then
  # Read existing content
  EXISTING_TFVARS_CONTENT=$(grep "workstation_IP = " "$TFVARS_FILE" 2>/dev/null)
  EXISTING_INGRESS_CONTENT=$(grep "nginx.ingress.kubernetes.io/whitelist-source-range" "$K8SINGRESS_FILE" 2>/dev/null)
  
  if [ -n "$EXISTING_TFVARS_CONTENT" ]; then
    # If the line exists, append the new IP inside the square brackets
    sudo sed -i "s|\(workstation_IP = \[.*\)\]|\1, \"$IP_ADDRESS\"]|" "$TFVARS_FILE"
  else
    # If the line doesn't exist, append it
    echo "workstation_IP = [\"$IP_ADDRESS\"]" >> "$TFVARS_FILE"
  fi

  # if [ -n "$EXISTING_INGRESS_CONTENT" ]; then
  #   # If the line exists, append the new IP inside the square brackets
  #   sudo sed -i "s|\(nginx.ingress.kubernetes.io/whitelist-source-range: \"[^\"]*\)\"\(.*\)$|\1, ${IP_ADDRESS}\"\2|" "../microservices_manifests/ingress.yaml"
  # else
  #   # If the line doesn't exist, append it
  #   sudo sed -i '0,/annotations:/b; /annotations:/a\\    nginx.ingress.kubernetes.io/whitelist-source-range: \"'"$IP_ADDRESS"'\"' ../microservices_manifests/ingress.yaml
  # fi

  # Check if writing to the file was successful
  if [ $? -eq 0 ]; then
    echo "Successfully updated allowed ip addresses in $TFVARS_FILE and/or $K8SINGRESS_FILE"
  else
    echo "Error: Failed to write to $TFVARS_FILE and/or $K8SINGRESS_FILE"
  fi
else
  echo "Error: Failed to retrieve current ip address"
fi

# sudo sed -i '/annotations:/a\    nginx.ingress.kubernetes.io/whitelist-source-range: ""' ../microservices_manifests/ingress.yaml

# sudo sed -i "s|nginx.ingress.kubernetes.io/whitelist-source-range: |&\"${IP_ADDRESS}\"|" "../microservices_manifests/ingress.yaml"

# sudo sed -i "s|\(nginx.ingress.kubernetes.io/whitelist-source-range: \"[^\"]*\)\"\(.*\)$|\1, ${IP_ADDRESS}\"\2|" "../microservices_manifests/ingress.yaml"