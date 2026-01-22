#!/bin/bash
set -e

echo "🛡️  Activating Security Policy on Backend..."

if ! gcloud compute security-policies describe workshop-armor-policy > /dev/null 2>&1; then
    echo "❌ Security policy 'workshop-armor-policy' not found. Please run 06_part6_security_policy.sh first."
    exit 1
fi

gcloud compute backend-services update workshop-backend \
    --global \
    --security-policy workshop-armor-policy
