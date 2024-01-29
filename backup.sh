#!/bin/bash

main() {
  load_configuration
  check_mail_support
  restic "$@"
  mail "INFO" "info - $1"
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

check_mail_support() {
  if [ -z "$MAIL_TO" ] || [ -z "$MAIL_FROM" ] || [[ -z $(command -v sendmail) ]]; then
    # We want this to output $MAIL_TO and $MAIL_FROM without expansion
    # shellcheck disable=SC2016
    info 'disabled sending mails as either $MAIL_TO and $MAIL_FROM are not set or sendmail is not installed'
    MAIL_DISABLED=true
  fi

  if [ "$(uname)" == "Darwin" ]; then
    warning "disabled sending mails although it is configured it is not supported on macOS"
    MAIL_DISABLED=true
  fi
}

# mail <cmd> <subject> <body>
mail() {
  if [ "$MAIL_DISABLED" = true ]; then return; fi

  if ! output=$({
    echo "From: $MAIL_FROM"
    echo "Subject: $1 $HOSTNAME - $2"
    echo "$3"
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
