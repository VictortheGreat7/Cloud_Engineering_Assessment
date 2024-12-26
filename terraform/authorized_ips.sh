#!/bin/bash

# Exit immediately if a command exits with a non-zero status or an undefined variable is used
# set -eu

# Check if the curl command exists and install it if it doesn't
if ! sudo which curl &> /dev/null; then
  echo "Error: curl command not found. Installing curl..."
  sudo apt-get update
  sudo apt-get install -y curl
fi

# Terraform variables file
TFVARS_FILE="terraform.tfvars"

# Get the ip address of the current machine
IP_ADDRESS=$(curl -s ifconfig.me)/32

# Check if the curl command was successful
if [ $? -eq 0 ]; then
  # Read existing content
  EXISTING_TFVARS_CONTENT=$(grep "workstation_IP_address = " "$TFVARS_FILE" 2>/dev/null)
  
  if [ -n "$EXISTING_TFVARS_CONTENT" ]; then
    # If the line exists, replace whatever is in the double quotes with the new ip address
    sudo sed -i "s|workstation_IP_address = \".*\"|workstation_IP_address = \"$IP_ADDRESS\"|" "$TFVARS_FILE"
  else
    # If the line doesn't exist, append it
    echo "workstation_IP_address = \"$IP_ADDRESS\"" >> "$TFVARS_FILE"
  fi

  # Check if writing to the file was successful
  if [ $? -eq 0 ]; then
    echo "Successfully updated allowed ip addresses in $TFVARS_FILE"
  else
    echo "Error: Failed to write to $TFVARS_FILE"
  fi
else
  echo "Error: Failed to retrieve current ip address"
fi
