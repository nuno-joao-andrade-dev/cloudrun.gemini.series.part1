#!/bin/bash
set -e

# Ensure required vars are set
if [ -z "$INSTANCE_NAME" ] || [ -z "$REGION" ] || [ -z "$DB_PASS" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🌐 Setting up Network (VPC)..."
# 1. Create VPC and Subnet
if ! gcloud compute networks describe workshop-vpc > /dev/null 2>&1; then
    gcloud compute networks create workshop-vpc --subnet-mode=custom
else
    echo "Network 'workshop-vpc' already exists."
fi

if ! gcloud compute networks subnets describe workshop-subnet --region=$REGION > /dev/null 2>&1; then
    gcloud compute networks subnets create workshop-subnet \
        --network=workshop-vpc \
        --range=10.0.0.0/24 \
        --region=$REGION
else
    echo "Subnet 'workshop-subnet' already exists."
fi

# 2. Configure Private Service Access
echo "🔧 Configuring Private Service Access..."
if ! gcloud compute addresses describe google-managed-services-default --global > /dev/null 2>&1; then
    gcloud compute addresses create google-managed-services-default \
        --global \
        --purpose=VPC_PEERING \
        --prefix-length=16 \
        --network=workshop-vpc
else
    echo "Address range already allocated."
fi

# Connect peering (idempotent-ish, will fail if already connected but usually harmless or we can check)
# Simplest check is listing peerings
if ! gcloud services vpc-peerings list --network=workshop-vpc | grep -q "servicenetworking-googleapis-com"; then
    gcloud services vpc-peerings connect \
        --service=servicenetworking.googleapis.com \
        --ranges=google-managed-services-default \
        --network=workshop-vpc
else
    echo "VPC Peering already exists."
fi

echo "🗄️ Creating Cloud SQL Instance ($INSTANCE_NAME)..."
# Create the instance
if ! gcloud sql instances describe $INSTANCE_NAME > /dev/null 2>&1; then
    gcloud sql instances create $INSTANCE_NAME \
        --database-version=POSTGRES_16 \
        --tier=db-f1-micro \
        --edition=ENTERPRISE \
        --region=$REGION \
        --root-password=$DB_PASS \
        --network=workshop-vpc \
        --no-assign-ip
else
    echo "Instance '$INSTANCE_NAME' already exists."
fi

echo "🗄️ Creating Database 'users_db'..."
# Create the specific database
gcloud sql databases create users_db --instance=$INSTANCE_NAME || echo "Database 'users_db' likely exists."