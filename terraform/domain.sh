#!/usr/bin/env bash
set -eu

# # Decrypt env file
# gpg --quiet --decrypt .env.gpg > .env.tmp
# source .env.tmp
# rm .env.tmp

# DNS record details
RECORD_TYPE="A"
HOST="api"
ANSWER=$(kubectl get svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
TTL="300"

# API endpoint
API_URL="https://api.dev.name.com/v4/domains/$DOMAIN/records"

# Add DNS record
curl -X POST "$API_URL" \
  -u "$USERNAME:$TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"host\": \"$HOST\",
    \"type\": \"$RECORD_TYPE\",
    \"answer\": \"$ANSWER\",
    \"ttl\": $TTL
  }"