#!/usr/bin/env bash
set -eu

# # Decrypt env file
# gpg --quiet --decrypt .env.gpg > .env.tmp
# source .env.tmp
# rm .env.tmp

USERNAME="VictortheGreat"
TOKEN="a44c00dcf5b1efc0ecdc3ab2884a146cdf0c3c82"
DOMAIN="mywonder.works"

# DNS record details
RECORD_TYPE="A"
HOST="api"
ANSWER=$(kubectl get svc -n kube-system ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
TTL="300"

# API endpoint
API_URL="https://api.name.com/v4/domains/$DOMAIN/records"

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