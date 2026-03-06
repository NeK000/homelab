#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  doppler-compose.sh <docker compose args>

Examples:
  doppler-compose.sh up -d
  doppler-compose.sh ps
  doppler-compose.sh down
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$SCRIPT_DIR"
AUTH_FILE="$STACK_DIR/../ts_authkey"

cd "$STACK_DIR" || die "failed to cd into $STACK_DIR"

command -v doppler >/dev/null 2>&1 || die "doppler is not installed or not in PATH"
command -v docker >/dev/null 2>&1 || die "docker is not installed or not in PATH"
docker compose version >/dev/null 2>&1 || die "docker compose (v2) is not available"

if [[ ! -f docker-compose.yaml && ! -f docker-compose.yml ]]; then
  die "no docker-compose.yaml or docker-compose.yml found in $STACK_DIR"
fi

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

tmp_auth_file="$(mktemp "${AUTH_FILE}.tmp.XXXXXX")"
cleanup() {
  rm -f "$tmp_auth_file"
}
trap cleanup EXIT

doppler secrets get TAILSCALE_AUTH_KEY -p homelab -c dev --plain >"$tmp_auth_file" \
  || die "failed to read TAILSCALE_AUTH_KEY from Doppler"

mv "$tmp_auth_file" "$AUTH_FILE" || die "failed to write auth key to $AUTH_FILE"
chmod 600 "$AUTH_FILE" || die "failed to set permissions on $AUTH_FILE"

exec doppler run -c dev -p homelab -- docker compose "$@"
