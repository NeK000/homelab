#!/usr/bin/env bash

# logging.sh

YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${YELLOW}[INFO] $*${NC}"
}

log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    echo -e "${WHITE}[DEBUG] $*${NC}"
  fi
}

log_error() {
  echo -e "${RED}[ERROR] $*${NC}" >&2
}