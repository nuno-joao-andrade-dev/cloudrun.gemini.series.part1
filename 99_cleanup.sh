#!/bin/bash
# set -e # Don't exit on error so we can attempt to delete all even if some fail

# Ensure required vars are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_NAME" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🧹 Starting Cleanup..."

# 1. Delete Load Balancer components
echo "🗑️ Deleting Load Balancer components..."
gcloud compute forwarding-rules delete workshop-lb-rule --global --quiet || true
gcloud compute target-http-proxies delete workshop-http-proxy --quiet || true
gcloud compute url-maps delete workshop-url-map --quiet || true
gcloud compute backend-services delete workshop-backend --global --quiet || true
gcloud compute network-endpoint-groups delete go-service-neg --region=$REGION --quiet || true
gcloud compute addresses delete workshop-lb-ip --global --quiet || true

# 2. Delete Cloud Armor Policy
echo "🗑️ Deleting Cloud Armor Policy..."
gcloud compute security-policies delete workshop-armor-policy --quiet || true

# 3. Delete Cloud Run Service
echo "🗑️ Deleting Cloud Run Service..."
gcloud run services delete go-service --region=$REGION --quiet || true

echo "⏳ Waiting 30 seconds for Serverless Network resources to release..."
sleep 30

# 4. Delete Cloud SQL Instance
echo "🗑️ Deleting Cloud SQL Instance ($INSTANCE_NAME)..."
gcloud sql instances delete $INSTANCE_NAME --quiet || true

# 5. Delete Network (VPC & Subnet)
echo "🗑️ Deleting Network components..."
echo "   - Deleting Private Service Access Range..."
gcloud compute addresses delete google-managed-services-default --global --quiet || true

echo "   - Deleting Subnet..."
gcloud compute networks subnets delete workshop-subnet --region=$REGION --quiet || true

echo "   - Deleting VPC..."
gcloud compute networks delete workshop-vpc --quiet || true

# 6. Delete Service Account
echo "🗑️ Deleting Service Account..."
gcloud iam service-accounts delete workshop-sa@$PROJECT_ID.iam.gserviceaccount.com --quiet || true

echo "✨ Cleanup complete!"
