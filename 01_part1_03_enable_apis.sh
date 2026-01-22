#!/bin/bash
set -e

echo "🚀 Enabling Google Cloud APIs..."
gcloud services enable \
    sqladmin.googleapis.com \
    run.googleapis.com \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    logging.googleapis.com
