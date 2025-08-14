#!/usr/bin/env bash
set -euo pipefail
set -x

# Required env vars (exported by the workflow before calling this script)
: "${AWS_REGION:?}"
: "${ECR:?}"
: "${TAG:?}"
: "${PUSER:?}"
: "${PPASS:?}"
: "${PDB:?}"
: "${ECR_PW_B64:?}"

# 1) Install k3s if missing (make kubeconfig readable for kubectl)
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | env K3S_KUBECONFIG_MODE=644 sh -
fi

# Ensure curl exists (Amazon Linux/Ubuntu)
if ! command -v curl >/dev/null 2>&1; then
  if command -v yum >/dev/null 2>&1; then
    yum install -y curl
  else
    apt-get update -y && apt-get install -y curl
  fi
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 2) Download repo at the exact commit/tag we’re deploying
WORKDIR=/opt/k8s
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
curl -L "https://github.com/Uthmanade001/example-voting-app/archive/${TAG}.tar.gz" -o /tmp/repo.tgz
tar xzf /tmp/repo.tgz -C "$WORKDIR" --strip-components=1

# 3) Replace placeholders
sed -i "s|__ECR__|$ECR|g; s|__TAG__|$TAG|g" "$WORKDIR"/k8s/*.yaml

# 4) Namespace & secrets
k3s kubectl apply -f "$WORKDIR/k8s/namespace.yaml"

k3s kubectl -n voting create secret generic db \
  --from-literal=POSTGRES_USER="$PUSER" \
  --from-literal=POSTGRES_PASSWORD="$PPASS" \
  --from-literal=POSTGRES_DB="$PDB" \
  --dry-run=client -o yaml | k3s kubectl apply -f -

# ECR imagePull secret (password supplied by runner; decode safely)
REG_SERVER="${ECR#https://}"
ECR_PW="$(echo "$ECR_PW_B64" | base64 -d)"
k3s kubectl -n voting create secret docker-registry ecr-creds \
  --docker-server="$REG_SERVER" \
  --docker-username=AWS \
  --docker-password="$ECR_PW" \
  --dry-run=client -o yaml | k3s kubectl apply -f -

# 5) Apply workloads (no wildcards)
k3s kubectl -n voting apply -f "$WORKDIR/k8s/postgres.yaml"
k3s kubectl -n voting apply -f "$WORKDIR/k8s/redis.yaml"
k3s kubectl -n voting apply -f "$WORKDIR/k8s/vote.yaml"
k3s kubectl -n voting apply -f "$WORKDIR/k8s/result.yaml"
k3s kubectl -n voting apply -f "$WORKDIR/k8s/worker.yaml"

# 6) Rollout status & diagnostics
k3s kubectl -n voting rollout status deployment/redis --timeout=180s || true
k3s kubectl -n voting rollout status deployment/vote --timeout=180s || true
k3s kubectl -n voting rollout status deployment/result --timeout=180s || true
k3s kubectl -n voting rollout status deployment/worker --timeout=180s || true
k3s kubectl -n voting get pods -o wide || true
k3s kubectl -n voting get svc -o wide || true
