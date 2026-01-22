#!/bin/bash
set -e

echo "🧪 Running Tests..."

cd go-workshop
go test -v ./...

echo "✅ Tests complete."