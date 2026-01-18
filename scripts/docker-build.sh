#!/usr/bin/env bash
set -euo pipefail

# Build backend image from repo root Dockerfile
docker build -t container-assessment-backend:latest .
echo "✅ Docker image built: container-assessment-backend:latest"
