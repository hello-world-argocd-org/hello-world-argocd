#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/hello-world-argocd-org/hello-world.git}"
BRANCH="${BRANCH:-main}"

# Auth for private repos
if [[ -n "${GITHUB_TOKEN:-}" && -n "${GITHUB_USER:-}" ]]; then
  REPO_URL="${REPO_URL/https:\/\//https:\/\/${GITHUB_USER}:${GITHUB_TOKEN}@}"
fi

WORKDIR="$(mktemp -d)"
git config --global user.name "${GITHUB_USER:-local-user}"
git config --global user.email "${GIT_EMAIL:-local-user@example.com}"

git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"

STAMP="$(date -Is)"
git commit --allow-empty -m "chore: trigger app CI (${STAMP})"
git push origin "$BRANCH"

echo "✅ Pushed empty commit to app repo: $REPO_URL ($BRANCH)"
