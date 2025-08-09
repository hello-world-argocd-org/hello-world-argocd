#!/usr/bin/env bash
set -euo pipefail

# ---------- Config ----------
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-argocd-demo}"
ARGO_NAMESPACE="${ARGO_NAMESPACE:-argocd}"
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
ARGO_HELM_RELEASE="${ARGO_HELM_RELEASE:-argocd}"
ARGO_HELM_VERSION="${ARGO_HELM_VERSION:-5.51.6}"   # chart version (adjust as needed)
ARGOCDFQDN="${ARGOCDFQDN:-}"                       # optional, for ingress of ArgoCD itself

# Your repos
ARGOCD_CONFIG_REPO="${ARGOCD_CONFIG_REPO:-https://github.com/hello-world-argocd-org/hello-world-argocd.git}"
ARGOCD_CONFIG_REV="${ARGOCD_CONFIG_REV:-main}"
ARGOCD_CONFIG_PATH="${ARGOCD_CONFIG_PATH:-.}"      # where your ApplicationSet yamls live

# Environments (namespaces)
ENVS=("dev" "stage" "prod")

# ---------- 0. Prereqs ----------
command -v kind >/dev/null || { echo "kind not found"; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl not found"; exit 1; }
command -v helm >/dev/null || { echo "helm not found"; exit 1; }

# ---------- 1. Kind ----------
if ! kind get clusters | grep -qx "$KIND_CLUSTER_NAME"; then
  echo "Creating kind cluster: $KIND_CLUSTER_NAME"
  kind create cluster --name "$KIND_CLUSTER_NAME"
else
  echo "Kind cluster '$KIND_CLUSTER_NAME' already exists"
fi

# ---------- 2. Namespaces ----------
kubectl create namespace "$ARGO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
for ns in "${ENVS[@]}"; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# ---------- 3. Ingress Controller (for your app ingress) ----------
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace "$INGRESS_NAMESPACE" --create-namespace \
  --set controller.publishService.enabled=true \
  --wait

# ---------- 4. Argo CD via Helm (ApplicationSet enabled) ----------
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null
helm upgrade --install "$ARGO_HELM_RELEASE" argo/argo-cd \
  --namespace "$ARGO_NAMESPACE" \
  --version "$ARGO_HELM_VERSION" \
  --set applicationSet.enabled=true \
  --wait

# Wait for core components
kubectl -n "$ARGO_NAMESPACE" rollout status deploy/argocd-application-controller --timeout=180s || true
kubectl -n "$ARGO_NAMESPACE" rollout status deploy/argocd-repo-server --timeout=180s || true
kubectl -n "$ARGO_NAMESPACE" rollout status deploy/argocd-server --timeout=300s || true

# ---------- 5. (Optional) Add GitHub token secret if your repos are private ----------
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  kubectl -n "$ARGO_NAMESPACE" create secret generic gh-token --dry-run=client \
    --from-literal=token="$GITHUB_TOKEN" -o yaml | kubectl apply -f -
  echo "Created secret 'gh-token' in $ARGO_NAMESPACE with your GITHUB_TOKEN"
fi

# ---------- 6. Bootstrap Argo CD: create an Application that points to your argocd-config repo ----------
# This assumes your hello-world-argocd repo contains the ApplicationSet YAMLs.
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-bootstrap
  namespace: ${ARGO_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${ARGOCD_CONFIG_REPO}
    targetRevision: ${ARGOCD_CONFIG_REV}
    path: ${ARGOCD_CONFIG_PATH}
    # If private repo and you configured Argo CD repo credentials in the UI/secret,
    # you don't need anything else here.
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ARGO_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "➡️  Argo CD bootstrap Application created. It should pull your ApplicationSets and generate Apps (dev/stage/prod)."

# ---------- 7. Helpful output ----------
echo
echo "== Info =="
echo "Namespaces: ${ENVS[*]}"
echo "Argo CD ns: ${ARGO_NAMESPACE}"
echo
echo "Port-forward Argo CD UI (in separate shell):"
echo "kubectl -n ${ARGO_NAMESPACE} port-forward svc/argocd-server 8080:80"
echo "Open: http://localhost:8080"
echo
echo "Default admin password (initial, randomized):"
echo "kubectl -n ${ARGO_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
