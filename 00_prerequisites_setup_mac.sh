#!/bin/bash
set -e

echo "🛠️  Checking and Installing Dependencies (macOS)..."

read -p "This script will check/install Homebrew, Go (latest), Google Cloud SDK, Cloud SQL Proxy, and PostgreSQL Client. Do you want to proceed? (y/N) " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Aborting installation."
    exit 1
fi

# 0. Install Homebrew if missing
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installed."
else
    echo "✅ Homebrew is already installed."
fi

# 1. Install Go
if ! command -v go &> /dev/null; then
    echo "❌ Go not found. Installing via Homebrew..."
    brew install go
    echo "✅ Go installed."
else
    echo "✅ Go is already installed."
fi

# 2. Install gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Installing via Homebrew..."
    brew install --cask google-cloud-sdk
    echo "✅ Google Cloud SDK installed."
else
    echo "✅ gcloud is already installed."
fi

# 3. Cloud SQL Proxy
if [ ! -f ./cloud-sql-proxy ]; then
    echo "📥 Downloading Cloud SQL Auth Proxy..."
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.amd64
    chmod +x cloud-sql-proxy
    echo "✅ Cloud SQL Auth Proxy installed."
else
    echo "✅ Cloud SQL Auth Proxy is present."
fi

# 4. PostgreSQL Client
if ! command -v psql &> /dev/null; then
    echo "📥 Installing PostgreSQL Client..."
    brew install libpq
    # Link libpq to path if needed (instructional)
    echo "⚠️  Ensure libpq is in your PATH: export PATH=\"/usr/local/opt/libpq/bin:$PATH\""
else
    echo "✅ psql is already installed."
fi

echo "🎉 Dependency check complete!"