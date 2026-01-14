#!/usr/bin/env bash
set -euo pipefail
docker build -t muchtodo-backend:local -f Dockerfile .
