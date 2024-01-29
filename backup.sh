#!/bin/bash

main() {
  load_configuration
  restic "$@"
  exit 0
}

load_configuration() {
  if [ ! -f .env ]; then
    error ".env file with configuration not found"
    exit 1
  fi

  . .env

  export RESTIC_PASSWORD=$RESTIC_PASSWORD
  export RESTIC_REPOSITORY=$RESTIC_REPOSITORY
}

log() { echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"; }
error() { log "error - $1"; }

main "${@:1}"
