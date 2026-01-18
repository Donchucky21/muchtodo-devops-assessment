#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-muchtodo}"

kind get clusters | grep -qx "$CLUSTER_NAME" || kind create cluster --name "$CLUSTER_NAME"

kubectl create namespace muchtodo --dry-run=client -o yaml | kubectl apply -f -

# Load images
kind load docker-image muchtodo-backend:latest --name "$CLUSTER_NAME" || true

# Apply manifests
kubectl apply -f kubernetes/

# Avoid remote pulls for local image
kubectl patch deploy backend -n muchtodo --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]' || true

kubectl rollout status deploy/mongodb -n muchtodo
kubectl rollout status deploy/backend -n muchtodo
