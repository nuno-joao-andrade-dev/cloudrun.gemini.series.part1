#!/bin/bash
set -e

# Ensure required vars are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_NAME" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🚀 Deploying to Cloud Run..."

# Create SA
if ! gcloud iam service-accounts describe workshop-sa@$PROJECT_ID.iam.gserviceaccount.com > /dev/null 2>&1; then
    echo "Creating Service Account..."
    gcloud iam service-accounts create workshop-sa --display-name="Workshop SA"
else
    echo "Service Account already exists."
fi

# Grant DB Access
echo "Granting Cloud SQL Client role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:workshop-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

# Build Container
echo "Building Container Image..."
cd go-workshop
if [ ! -f Dockerfile ]; then
    echo "❌ Dockerfile not found in go-workshop directory!"
    exit 1
fi
gcloud builds submit --tag gcr.io/$PROJECT_ID/go-workshop

# Fetch DB Private IP
echo "Fetching Cloud SQL Private IP..."
DB_HOST=$(gcloud sql instances describe $INSTANCE_NAME --flatten="ipAddresses[]" --format="csv[no-heading](ipAddresses.ipAddress, ipAddresses.type)" | grep ",PRIVATE" | cut -d',' -f1)
if [ -z "$DB_HOST" ]; then
    echo "❌ Could not find Private IP for instance $INSTANCE_NAME. Is Private IP enabled?"
    exit 1
fi
echo "DB Private IP: $DB_HOST"

# Deploy
echo "Deploying Service..."

if [ -z "$AUTH_PASS" ]; then
    echo "⚠️  AUTH_PASS is not set. Using default '<YOUR_AUTH_PASSWORD>'. Please export AUTH_PASS."
    AUTH_PASS="<YOUR_AUTH_PASSWORD>"
fi
if [ -z "$DB_PASS" ]; then
    echo "⚠️  DB_PASS is not set. Using default '<YOUR_SECURE_PASSWORD>'. Please export DB_PASS."
    DB_PASS="<YOUR_SECURE_PASSWORD>"
fi

gcloud run deploy go-service \
    --image gcr.io/$PROJECT_ID/go-workshop \
    --region $REGION \
    --allow-unauthenticated \
    --service-account workshop-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --network=workshop-vpc \
    --subnet=workshop-subnet \
    --set-env-vars DB_HOST="$DB_HOST" \
    --set-env-vars DB_PORT="5432" \
    --set-env-vars DB_USER="go_workshop" \
    --set-env-vars DB_NAME="users_db" \
    --set-env-vars DB_PASS="$DB_PASS" \
    --set-env-vars AUTH_USER="admin" \
    --set-env-vars AUTH_PASS="$AUTH_PASS"