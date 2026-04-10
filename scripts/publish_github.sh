#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   export GITHUB_USER="seu_usuario"
#   export GITHUB_TOKEN="ghp_xxx"
#   export REPO_NAME="ia-para-todos-blog"
#   bash scripts/publish_github.sh

: "${GITHUB_USER:?Defina GITHUB_USER}"
: "${GITHUB_TOKEN:?Defina GITHUB_TOKEN}"
REPO_NAME="${REPO_NAME:-ia-para-todos-blog}"

cd "$(dirname "$0")/.."

# Cria repo se não existir
http_code=$(curl -s -o /tmp/repo_check.json -w "%{http_code}" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}")

if [[ "$http_code" == "404" ]]; then
  curl -s \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"${REPO_NAME}\",\"private\":false}" >/tmp/repo_create.json
fi

git remote remove origin 2>/dev/null || true
git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
git push -u origin main

echo "Publicado: https://${GITHUB_USER}.github.io/${REPO_NAME}/"
echo "Ative em Settings > Pages > Deploy from branch > main /(root)"
