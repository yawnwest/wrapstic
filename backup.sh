#!/bin/bash

RESTIC_OUTPUT=NULL

main() {
  START_TIME=$(date +%s)
  load_configuration
  check_mail_support
  if execute_restic "$@"; then
    status="successful"
  else
    status="failed"
  fi
  END_TIME=$(date +%s)
  DURATION=$(((END_TIME - START_TIME) / 60))
  MSG=$(echo -e "Duration - $DURATION minutes\n\n$RESTIC_OUTPUT")
  mail "INFO - BACKUP $status" "$MSG"
  exit 0
}

load_configuration() {
  if [ -f .env ]; then
    . .env
  fi

  export RESTIC_PASSWORD=$RESTIC_PASSWORD
  export RESTIC_REPOSITORY=$RESTIC_REPOSITORY
}

check_mail_support() {
  if [ -z "$MAIL_TO" ] || [ -z "$MAIL_FROM" ] || [[ -z $(command -v sendmail) ]]; then
    # We want this to output $MAIL_TO and $MAIL_FROM without expansion
    # shellcheck disable=SC2016
    info 'disabled sending mails as either $MAIL_TO and $MAIL_FROM are not set or sendmail is not installed'
    MAIL_DISABLED=true
    return
  fi

  if [ "$(uname)" == "Darwin" ]; then
    warning "disabled sending mails although it is configured it is not supported on macOS"
    MAIL_DISABLED=true
    return
  fi
}

execute_restic() {
  r=0
  set -o pipefail
  if ! output=$(restic "$@" 2>&1 | tee /dev/tty); then
    error "backup failed"
    r=1
  fi
  # shellcheck disable=SC2001
  RESTIC_OUTPUT=$(sed 's/^/> /' <<<"$output")
  set +o pipefail
  return $r
}

# mail <subject> <body>
mail() {
  if [ "$MAIL_DISABLED" = true ]; then return; fi

  if ! output=$({
    echo "From: $MAIL_FROM"
    echo "Subject: $1"
    echo "$2"
  } | sendmail -v "$MAIL_TO" 2>&1); then
    error "failed to send mail"
    error "$(echo "$output" | grep -vE '^\[(<-|->)\] ')"
  fi
}

log() { echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"; }
info() { log "info - $1"; }
warning() { log "warning - $1"; }
error() { log "error - $1"; }

main "${@:1}"
