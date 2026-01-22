#!/bin/bash
set -e

# Ensure required vars are set
if [ -z "$REGION" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🔒 Restricting Ingress for Cloud Run Service..."
gcloud run services update go-service \
    --region $REGION \
    --ingress internal-and-cloud-load-balancing
