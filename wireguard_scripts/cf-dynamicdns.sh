#!/bin/bash

source /etc/cloudflare/credentials.conf

CURRENT_IP=$(curl -s https://api.ipify.org)

# Validate IP before proceeding
if [[ ! $CURRENT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$(date): Failed to get valid IP: '$CURRENT_IP'" >> /var/log/cf-ddns.log
    exit 1
fi

CACHE_FILE="/tmp/cf_last_ip"
LAST_IP=$(cat "$CACHE_FILE" 2>/dev/null)

if [ "$CURRENT_IP" = "$LAST_IP" ]; then
    exit 0
fi

# Get Record ID
RECORD_ID=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=A&name=${CF_RECORD_NAME}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    | python3 -c "import sys,json; data=json.load(sys.stdin); print(data['result'][0]['id']) if data['result'] else print('')")

if [ -z "$RECORD_ID" ]; then
    echo "$(date): Failed to get Record ID for ${CF_RECORD_NAME}" >> /var/log/cf-ddns.log
    exit 1
fi

# Update record
RESPONSE=$(curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":60,\"proxied\":false}")

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "$(date): Updated ${CF_RECORD_NAME} to ${CURRENT_IP}" >> /var/log/cf-ddns.log
    echo "$CURRENT_IP" > "$CACHE_FILE"
else
    echo "$(date): Failed. Response: $RESPONSE" >> /var/log/cf-ddns.log
fi
