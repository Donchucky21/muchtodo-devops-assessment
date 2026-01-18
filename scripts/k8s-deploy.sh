#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-muchtodo}"

# Create kind cluster (with NodePort mapping for 30080 evidence)
if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  cat <<YAML >/tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
YAML
  kind create cluster --name "$CLUSTER_NAME" --config /tmp/kind-config.yaml
fi

kubectl create namespace muchtodo --dry-run=client -o yaml | kubectl apply -f -

# Build backend image from repo root
docker build -t container-assessment-backend:latest .

# Pull + load images into kind (prevents ImagePullBackOff)
docker pull mongo:4.4.30
kind load docker-image container-assessment-backend:latest --name "$CLUSTER_NAME"
kind load docker-image mongo:4.4.30 --name "$CLUSTER_NAME"

# Apply manifests
kubectl apply -f kubernetes/

# Ensure local backend image isn't pulled remotely
kubectl patch deploy backend -n muchtodo --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]' || true

kubectl rollout status deploy/mongodb -n muchtodo --timeout=180s
kubectl rollout status deploy/backend -n muchtodo --timeout=180s

echo
kubectl -n muchtodo get pods -o wide
kubectl -n muchtodo get svc
