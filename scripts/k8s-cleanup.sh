#!/usr/bin/env bash
set -euo pipefail
kubectl delete -f kubernetes/ --ignore-not-found
