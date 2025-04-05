#!/usr/bin/env bash
set -eu

# API endpoint for Name.com nameserver updates
API_URL="https://api.name.com/v4/domains/$DOMAIN:setNameservers"

NAME_COM_NS1="ns1.name.com"
NAME_COM_NS2="ns2.name.com"
NAME_COM_NS3="ns3.name.com"
NAME_COM_NS4="ns4.name.com"

# Construct the JSON payload for the nameserver update
PAYLOAD=$(cat <<-EOF
{
  "nameservers": [
    "$AZURE_NS1",
    "$AZURE_NS2",
    "$AZURE_NS3",
    "$AZURE_NS4",
    "$NAME_COM_NS1",
    "$NAME_COM_NS2",
    "$NAME_COM_NS3",
    "$NAME_COM_NS4"
  ]
}
EOF
)

# Update nameservers using the Name.com API
curl -X POST "$API_URL" \
  -u "$USERNAME:$TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

echo "Azure DNS nameservers updated successfully."

# Optional: Add an A record for your application (as in your original script)
# DNS record details
RECORD_TYPE="A"
HOST="api"
ANSWER=$(kubectl get svc -n kube-system ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
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