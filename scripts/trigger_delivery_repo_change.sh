#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/hello-world-argocd-org/hello-world-delivery.git}"
BRANCH="${BRANCH:-main}"
ENV_PATH="${ENV_PATH:-envs/dev/values.yaml}" # Adjust if different

# Auth for private repos
if [[ -n "${GITHUB_TOKEN:-}" && -n "${GITHUB_USER:-}" ]]; then
  REPO_URL="${REPO_URL/https:\/\//https:\/\/${GITHUB_USER}:${GITHUB_TOKEN}@}"
fi

WORKDIR="$(mktemp -d)"
git config --global user.name "${GITHUB_USER:-local-user}"
git config --global user.email "${GIT_EMAIL:-local-user@example.com}"

git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"

if [[ ! -f "$ENV_PATH" ]]; then
  echo "ERROR: ${ENV_PATH} not found."
  exit 1
fi

STAMP="$(date -Is)"
if grep -q '^config:' "$ENV_PATH"; then
  if grep -q 'CUSTOM_MESSAGE' "$ENV_PATH"; then
    perl -0777 -pe "s/(CUSTOM_MESSAGE:\s*).*/\${1}\"Updated ${STAMP}\"/g" -i "$ENV_PATH"
  else
    awk -v stamp="$STAMP" '
      BEGIN{printed=0}
      /^config:/ && !printed { print; print "  CUSTOM_MESSAGE: \"Hello from delivery ("stamp")\""; printed=1; next }
      { print }
    ' "$ENV_PATH" > "$ENV_PATH.tmp" && mv "$ENV_PATH.tmp" "$ENV_PATH"
  fi
else
  cat >> "$ENV_PATH" <<EOF

config:
  CUSTOM_MESSAGE: "Hello from delivery (${STAMP})"
EOF
fi

git add "$ENV_PATH"
git commit -m "feat: update CUSTOM_MESSAGE to trigger rollout (${STAMP})"
git push origin "$BRANCH"

echo "✅ Updated ${ENV_PATH} in delivery repo: $REPO_URL ($BRANCH)"
