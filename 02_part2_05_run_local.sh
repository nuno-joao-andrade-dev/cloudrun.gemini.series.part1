#!/bin/bash
set -e

# Ensure required vars are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_NAME" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🏠 Running Locally..."

cd go-workshop

# Standard Postgres Connection Config
export DB_HOST="127.0.0.1"
export DB_PORT="5433"
export DB_USER="go_workshop"
export DB_PASS="<YOUR_SECURE_PASSWORD>" # Ensure this matches what you set in the DB
export DB_NAME="users_db"
export AUTH_USER="admin"
export AUTH_PASS="<YOUR_AUTH_PASSWORD>"
export PORT="8080"

echo "🔓 Enabling Public IP for local testing..."
gcloud sql instances patch $INSTANCE_NAME --assign-ip

echo "---------------------------------------------------"
echo "⚠️  Ensure you are authenticated:"
echo "   gcloud auth application-default login --project $PROJECT_ID"
echo ""
echo "⚠️  Ensure the Cloud SQL Auth Proxy is running in another terminal:"
echo "   ./cloud-sql-proxy --port=5433 $PROJECT_ID:$REGION:$INSTANCE_NAME"
echo "---------------------------------------------------"
read -p "Press [Enter] when the proxy is ready..."

echo "running the app..."
go run main.go

echo "🛑 When done, disable Public IP: gcloud sql instances patch $INSTANCE_NAME --no-assign-ip"
