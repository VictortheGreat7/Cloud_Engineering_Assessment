#!/usr/bin/env bash
set -eu

RECORD_TYPE="A"
HOST="api"

# Get the record ID of the matching A record
RECORD_ID=$(curl -s -X GET "https://api.name.com/v4/domains/$DOMAIN/records" \
    -u "$USERNAME:$TOKEN" \
    -H "Content-Type: application/json" | \
    jq ".records[] | select(.host==\"$HOST\" and .type==\"$RECORD_TYPE\") | .id")

# Delete the record if ID was found
if [ -n "$RECORD_ID" ]; then
  curl -X DELETE "https://api.name.com/v4/domains/$DOMAIN/records/$RECORD_ID" \
       -u "$USERNAME:$TOKEN" \
       -H "Content-Type: application/json"
  echo "A record deleted successfully."
else
  echo "No matching A record found for host '$HOST'."
fi
