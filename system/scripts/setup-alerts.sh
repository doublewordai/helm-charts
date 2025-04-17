#!/bin/bash

EMAIL="$1"
PASSWORD="$2"
SLACK_WEBHOOK="$3"
INSTALL_RAG_ALERT="$4"

kubectl port-forward -n monitoring svc/signoz 8080:8080 >/dev/null 2>&1 &
PF_PID=$!


until curl -s http://localhost:8080/api/v1/health; do
  echo "Waiting for localhost:8080..."
  sleep 2
done

echo "[provision] Authenticating as $EMAIL..."

curl -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"confirmPassword\":\"$PASSWORD\",\"name\":\"Provisioner\"}" \
  | grep -o '"accessJwt":"[^"]*' | cut -d'"' -f4

TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}" | grep -o '"accessJwt":"[^"]*' | cut -d'"' -f4)
echo "[provision] Token received, provisioning alert..."

curl -X POST http://localhost:8080/api/v1/rules \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @"./scripts/gateway_alert.json" #Note that this script is running in the context of the helmfile dir.

echo "[provision] Provisioning channel..."

if [ -n "$SLACK_WEBHOOK" ]; then


  curl -X POST http://localhost:8080/api/v1/channels \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    --data "$(
      sed -e "s|{SLACK_WEBHOOK}|$SLACK_WEBHOOK|g" \
          ./scripts/slack_channel.json
    )"
fi

if [ -n "$INSTALL_RAG_ALERT" ]; then

curl -X POST http://localhost:8080/api/v1/rules \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @"./scripts/server_alert.json"

fi



kill $PF_PID

