#!/usr/bin/env bash

RESOURCE_GROUP=$(terraform output -raw aks_resource_group | grep -v 'terraform-bin' | grep -v 'Terraform exited with code' | awk -F': ' '{print $2}' | grep -v '^0$')
CLUSTER_NAME=$(terraform output -raw aks_cluster_name | grep -v 'terraform-bin' | grep -v 'Terraform exited with code' | awk -F': ' '{print $2}' | grep -v '^0$')

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME