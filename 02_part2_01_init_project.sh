#!/bin/bash
set -e

echo "📦 Initializing Go Project..."

mkdir -p go-workshop
cd go-workshop

if [ ! -f go.mod ]; then
    go mod init github.com/youruser/go-workshop
else
    echo "go.mod already exists, skipping init."
fi

# Create directory structure
mkdir -p models handlers middleware

# Install Dependencies
echo "⬇️  Installing Go dependencies..."
# Remove old dependencies if present (optional but good for clean switching)
go get cloud.google.com/go/cloudsqlconn@none 2>/dev/null || true
go get github.com/jackc/pgx/v4
go get github.com/DATA-DOG/go-sqlmock

echo "✅ Project initialized."