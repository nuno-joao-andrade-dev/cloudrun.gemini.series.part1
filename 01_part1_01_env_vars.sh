#!/bin/bash
# NOTE: Source this script to set environment variables in your current shell.
# Usage: source 01_part1_01_env_vars.sh

export PROJECT_ID="your-project-id-here"
export REGION="us-central1"
export DB_PASS="<YOUR_SECURE_PASSWORD>" # ⚠️ CHANGE THIS!
export INSTANCE_NAME="workshop-db"

echo "Configuring gcloud project..."
gcloud config set project $PROJECT_ID
