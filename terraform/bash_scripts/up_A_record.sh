#!/usr/bin/env bash
set -eu

# DNS record details
RECORD_TYPE="A"
HOST="api"
ANSWER=$(kubectl get svc -n nginx-ingress ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
TTL="300"

# API endpoint for A record addition
API_URL_A_RECORD="https://api.name.com/v4/domains/$DOMAIN/records"

# Add DNS record
curl -X POST "$API_URL_A_RECORD" \
        -u "$USERNAME:$TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
                \"host\": \"$HOST\",
                \"type\": \"$RECORD_TYPE\",
                \"answer\": \"$ANSWER\",
                \"ttl\": $TTL
        }"

echo "A record updated successfully."