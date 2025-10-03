#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_FILE="${1:-$SCRIPT_DIR/repos.yaml}"

yq_docker() {
  docker run --rm -v "$SCRIPT_DIR:/work" mikefarah/yq:4 "$@"
}

repos=$(yq_docker eval '.repos[] | .owner + "/" + .repo + "@" + .branch' "/work/$(basename "$YAML_FILE")" | tr -d '"')