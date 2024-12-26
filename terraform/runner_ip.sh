#!/bin/bash

MAIN_TF_FILE="main.tf"
TFVARS_FILE="terraform.tfvars"
IP_ADDRESS=$(curl -s ifconfig.me)/32

# Update authorized_ip_ranges if workstation_IP_address is not empty
if grep -q 'workstation_IP_address\s*=\s*"[^"]\+"' "$TFVARS_FILE"; then
    if [ -f "$MAIN_TF_FILE" ]; then
        if grep -q 'authorized_ip_ranges\s*=' "$MAIN_TF_FILE"; then
            # Check if IP is already in authorized_ip_ranges to avoid duplicates
            if ! grep -q "$IP_ADDRESS" "$MAIN_TF_FILE"; then
                sed -i '/authorized_ip_ranges\s*=/ s|\]|, "'$IP_ADDRESS'"]|' "$MAIN_TF_FILE"
                echo "Successfully updated authorized_ip_ranges in $MAIN_TF_FILE"
            else
                echo "IP address already exists in authorized_ip_ranges"
            fi
        else
            echo "authorized_ip_ranges not found in $MAIN_TF_FILE"
        fi
    else
        echo "Error: $MAIN_TF_FILE not found"
    fi
else
    echo "Error: workstation_IP_address is empty in $TFVARS_FILE"
fi