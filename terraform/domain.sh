#!/usr/bin/env bash
set -eu

USERNAME="VictortheGreat"
TOKEN="a44c00dcf5b1efc0ecdc3ab2884a146cdf0c3c82"
DOMAIN="mywonder.works"

NAMESERVERS=$(terraform output -json name_servers)

# API endpoint for Name.com nameserver updates
API_URL="https://api.name.com/v4/domains/$DOMAIN/nameservers"

AZURE_NS1=$(echo "$NAMESERVERS" | grep -v 'terraform-bin' | grep -v 'Terraform exited with code' | grep -oP '"\K[^"]+(?=")' | head -n 1 | sed 's/,//; s/\.$//' | grep -v '^0$')
AZURE_NS2=$(echo "$NAMESERVERS" | grep -v 'terraform-bin' | grep -v 'Terraform exited with code' | grep -oP '"\K[^"]+(?=")' | head -n 2 | tail -n 1 | sed 's/,//; s/\.$//' | grep -v '^0$')
AZURE_NS3=$(echo "$NAMESERVERS" | grep -v 'terraform-bin' | grep -v 'Terraform exited with code' | grep -oP '"\K[^"]+(?=")' | head -n 3 | tail -n 1 | sed 's/,//; s/\.$//' | grep -v '^0$')
AZURE_NS4=$(echo "$NAMESERVERS" | grep -v 'terraform-bin' | grep -v 'Terraform exited with code' | grep -oP '"\K[^"]+(?=")' | head -n 4 | tail -n 1 | sed 's/,//; s/\.$//' | grep -v '^0$')

# Construct the JSON payload for the nameserver update
PAYLOAD=$(cat <<-EOF
{
  "nameservers": [
    "$AZURE_NS1",
    "$AZURE_NS2",
    "$AZURE_NS3",
    "$AZURE_NS4"
  ]
}
EOF
)

# Update nameservers using the Name.com API
curl -X PUT "$API_URL" \
  -u "$USERNAME:$TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

echo "Azure DNS nameservers updated successfully."

# # Optional: Add an A record for your application (as in your original script)
# # DNS record details
# RECORD_TYPE="A"
# HOST="api"
# ANSWER=$(kubectl get svc -n kube-system ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# TTL="300"

# # API endpoint for A record addition
# API_URL_A_RECORD="https://api.name.com/v4/domains/$DOMAIN/records"

# # Add DNS record
# curl -X POST "$API_URL_A_RECORD" \
#         -u "$USERNAME:$TOKEN" \
#         -H "Content-Type: application/json" \
#         -d "{
#                 \"host\": \"$HOST\",
#                 \"type\": \"$RECORD_TYPE\",
#                 \"answer\": \"$ANSWER\",
#                 \"ttl\": $TTL
#         }"

# echo "A record updated successfully."