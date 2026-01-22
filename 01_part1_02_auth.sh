#!/bin/bash
set -e

# Ensure PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID is not set. Please source 01_part1_01_env_vars.sh first."
    exit 1
fi

echo "🔐 Authenticating..."
# Note: If you encounter issues, you might need to prefix with DISPLAY=":0"
gcloud auth login --no-launch-browser
gcloud auth application-default login --project $PROJECT_ID --no-launch-browser
