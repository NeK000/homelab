#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

ENV_FILE="${2:-$SCRIPT_DIR/my.env}"
WORKDIR="$SCRIPT_DIR/compose_deployments"

log_debug "Using environment file: $ENV_FILE"

mkdir -p "$WORKDIR"

for repo_info in $repos; do
  owner_repo=$(echo $repo_info | cut -d@ -f1)
  branch=$(echo $repo_info | cut -d@ -f2)
  owner=$(echo $owner_repo | cut -d/ -f1)
  repo=$(echo $owner_repo | cut -d/ -f2)

  log_info "Deploying $owner/$repo ($branch)..."
  REPO_DIR="$WORKDIR/$owner-$repo"
  mkdir -p "$REPO_DIR"
  cd "$REPO_DIR"

  curl -sL -o docker-compose.yml "https://raw.githubusercontent.com/$owner/$repo/$branch/docker-compose.yml"
  cp "$ENV_FILE" .env
  docker compose -f docker-compose.yml up -d

  cd - > /dev/null
  rm -rf "$REPO_DIR"
done

docker image prune -f