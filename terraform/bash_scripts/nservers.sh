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