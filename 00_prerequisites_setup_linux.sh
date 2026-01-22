#!/bin/bash
set -e

echo "🛠️  Checking and Installing Dependencies..."

read -p "This script will install Go 1.25.6, Google Cloud SDK, Cloud SQL Proxy, and PostgreSQL Client. Do you want to proceed? (y/N) " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Aborting installation."
    exit 1
fi

# 1. Install Go (Linux/amd64 example)
if ! command -v go &> /dev/null; then
    echo "❌ Go not found. Attempting to install Go 1.25.6..."
    wget -q https://go.dev/dl/go1.25.6.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.25.6.linux-amd64.tar.gz
    rm go1.25.6.linux-amd64.tar.gz
    # Update PATH for this session
    export PATH=$PATH:/usr/local/go/bin
    echo "✅ Go installed. (Remember to add /usr/local/go/bin to your PATH permanently)"
else
    echo "✅ Go is already installed."
fi

# 2. Install gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found."
    echo "📥 Installing Google Cloud SDK..."
    # Non-interactive install
    curl https://sdk.cloud.google.com | bash -s -- --disable-prompts
    echo "✅ Google Cloud SDK installed. Please restart your shell or source the path file."
else
    echo "✅ gcloud is already installed."
fi

# 3. Cloud SQL Proxy
if [ ! -f ./cloud-sql-proxy ]; then
    echo "📥 Downloading Cloud SQL Auth Proxy..."
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
    chmod +x cloud-sql-proxy
    echo "✅ Cloud SQL Auth Proxy installed."
else
    echo "✅ Cloud SQL Auth Proxy is present."
fi

# 4. PostgreSQL Client
if ! command -v psql &> /dev/null; then
    echo "📥 Installing PostgreSQL Client..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y postgresql-client
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y postgresql
    else
        echo "⚠️  OS not detected. Please install 'postgresql-client' manually."
    fi
else
    echo "✅ psql is already installed."
fi

echo "🎉 Dependency check complete!"