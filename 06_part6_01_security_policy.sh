#!/bin/bash
set -e

echo "🛡️  Creating Cloud Armor Security Policy..."

if ! gcloud compute security-policies describe workshop-armor-policy > /dev/null 2>&1; then
    gcloud compute security-policies create workshop-armor-policy \
        --description "Workshop Security Policy"

    # Rule 1: Allow valid traffic
    gcloud compute security-policies rules create 1000 \
        --security-policy workshop-armor-policy \
        --action "allow" \
        --src-ip-ranges "0.0.0.0/0"

    # Rule 2: Block SQLi (The "Fortress" Rule)
    gcloud compute security-policies rules create 9000 \
        --security-policy workshop-armor-policy \
        --expression "evaluatePreconfiguredExpr('sqli-stable')" \
        --action "deny-403"
    
    echo "✅ Policy created."
else
    echo "Policy 'workshop-armor-policy' already exists."
fi
