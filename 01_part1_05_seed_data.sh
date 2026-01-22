#!/bin/bash
set -e

# Ensure required vars are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ] || [ -z "$INSTANCE_NAME" ] || [ -z "$DB_PASS" ]; then
    echo "❌ Missing environment variables. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🔓 Temporarily enabling Public IP for seeding..."
gcloud sql instances patch $INSTANCE_NAME --assign-ip

echo "🌱 Seed Data Instructions"
echo "========================="
echo "This step requires two terminal windows."

echo ""
echo ">>> Terminal 1: Start the Cloud SQL Auth Proxy"
echo "./cloud-sql-proxy --port=5433 $PROJECT_ID:$REGION:$INSTANCE_NAME"

echo ""
echo ">>> Terminal 2: Connect via psql"
echo "PGPASSWORD=$DB_PASS psql \\"
echo "    --host=127.0.0.1 \\"
echo "    --port=5433 \\"
echo "    --username=postgres \\"
echo "    --dbname=postgres"

echo ""
echo ">>> Once connected in Terminal 2, copy and paste the contents of 'seed.sql' (or run the following SQL):"
cat seed.sql

echo ""
echo "🛑 IMPORTANT: After seeding, disable the public IP to secure the instance:"
echo "gcloud sql instances patch $INSTANCE_NAME --no-assign-ip"