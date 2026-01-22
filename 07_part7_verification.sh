#!/bin/bash
set -e

echo "✅ Final Verification..."

# 1. Get IP
echo "Fetching Load Balancer IP..."
LB_IP=$(gcloud compute addresses describe workshop-lb-ip --global --format='value(address)')
echo "Load Balancer IP: $LB_IP"

if [ -z "$AUTH_PASS" ]; then
    echo "⚠️  AUTH_PASS is not set. Using default '<YOUR_AUTH_PASSWORD>'."
    AUTH_PASS="<YOUR_AUTH_PASSWORD>"
fi

echo ""
echo "👉 Test 1: Normal Access (Should work)"
echo "Running: curl -u admin:$AUTH_PASS http://$LB_IP/"
curl -u admin:$AUTH_PASS http://$LB_IP/ || echo "Command failed (might be expected if LB is not ready)"

echo ""
echo "👉 Test 2: Direct Access (Should Fail)"
CLOUD_RUN_URL=$(gcloud run services describe go-service --region $REGION --format='value(status.url)')
echo "Running: curl $CLOUD_RUN_URL"
curl -I $CLOUD_RUN_URL || echo "Command failed (expected if restricted)"

echo ""
echo "👉 Test 3: SQL Injection Attack (Should Fail - 403 Forbidden)"
echo "Running: curl \"http://$LB_IP/?item=1' OR '1'='1\""
curl -I "http://$LB_IP/?item=1' OR '1'='1" || echo "Command failed"

echo ""
echo "Note: If you see 502 Bad Gateway or 404, the Load Balancer might still be provisioning. Wait a few minutes."
