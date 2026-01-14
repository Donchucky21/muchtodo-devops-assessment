#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="muchtodo"

if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
EOF
fi

# Build and load image into kind
docker build -t muchtodo-backend:local -f Dockerfile .
kind load docker-image muchtodo-backend:local --name "${CLUSTER_NAME}"

# Apply manifests
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml || true

kubectl -n muchtodo get pods,svc,ingress
echo "NodePort: http://localhost:30080/health"
