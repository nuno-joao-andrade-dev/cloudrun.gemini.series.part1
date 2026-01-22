#!/bin/bash
set -e

# Ensure required vars are set
if [ -z "$REGION" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🌐 Setting up Load Balancer..."

# 1. Reserve Static IP
echo "Reserving Static IP..."
if ! gcloud compute addresses describe workshop-lb-ip --global > /dev/null 2>&1; then
    gcloud compute addresses create workshop-lb-ip --global
else
    echo "IP 'workshop-lb-ip' already exists."
fi

# 2. Create Serverless NEG
echo "Creating Serverless NEG..."
if ! gcloud compute network-endpoint-groups describe go-service-neg --region=$REGION > /dev/null 2>&1; then
    gcloud compute network-endpoint-groups create go-service-neg \
        --region=$REGION \
        --network-endpoint-type=serverless  \
        --cloud-run-service=go-service
else
    echo "NEG 'go-service-neg' already exists."
fi

# 3. Build the Load Balancer
echo "Building Load Balancer..."

# Backend Service
if ! gcloud compute backend-services describe workshop-backend --global > /dev/null 2>&1; then
    gcloud compute backend-services create workshop-backend --global
    gcloud compute backend-services add-backend workshop-backend \
        --global \
        --network-endpoint-group=go-service-neg \
        --network-endpoint-group-region=$REGION
else
    echo "Backend Service 'workshop-backend' already exists."
fi

# Routing
if ! gcloud compute url-maps describe workshop-url-map > /dev/null 2>&1; then
    gcloud compute url-maps create workshop-url-map --default-service workshop-backend
else
    echo "URL Map 'workshop-url-map' already exists."
fi

if ! gcloud compute target-http-proxies describe workshop-http-proxy > /dev/null 2>&1; then
    gcloud compute target-http-proxies create workshop-http-proxy --url-map workshop-url-map
else
    echo "Target HTTP Proxy 'workshop-http-proxy' already exists."
fi

# Forwarding Rule (Frontend)
if ! gcloud compute forwarding-rules describe workshop-lb-rule --global > /dev/null 2>&1; then
    gcloud compute forwarding-rules create workshop-lb-rule \
        --global \
        --target-http-proxy=workshop-http-proxy \
        --ports=80 \
        --address=workshop-lb-ip
else
    echo "Forwarding Rule 'workshop-lb-rule' already exists."
fi

echo "✅ Load Balancer setup complete."
