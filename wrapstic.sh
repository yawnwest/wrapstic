#!/bin/bash

MAIL_DISABLED=false
CMD=NULL
OUTPUT=NULL
REPO_INIT=NULL
FREE_STORAGE="-"

main() {
  start_time=$(date +%s)
  load_configuration
  check_mail_support
  set_cmd "$@"
  check_prequisites
  preq_met=$?
  if [ "$preq_met" = 0 ]; then # all requirements met
    initialize_repository
    init_repo=$?
    if [ ! "$init_repo" = 2 ]; then # repo successfully/already initialized
      log "start $CMD"
      if execute_restic "$@"; then # restic successful
        status="successful"
      else # restic failed
        status="failed"
      fi
    else # repo not initialized
      status="failed"
    fi
  elif [ "$preq_met" = 1 ]; then # prequisites not met
    status="failed"
  else # a backup is already running
    status="successful"
  fi
  if [ ! "$preq_met" = 1 ]; then # prequsites met
    check_free_storage
  fi
  end_time=$(date +%s)
  duration=$(((end_time - start_time) / 60))
  log "--- SUMMARY ---"
  log "Status: $CMD $status"
  log "Duration: $duration minutes"
  log "Storage usage: $FREE_STORAGE"
  msg=$(echo -e "Duration - $duration minutes\nRepository initialization - $REPO_INIT\nStorage usage - $FREE_STORAGE\n\n$OUTPUT")
  mail "INFO - $CMD $status" "$msg"
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
    warning "disabled sending mails. although it is configured it is not supported on macOS"
    MAIL_DISABLED=true
    return
  fi
}

set_cmd() {
  for arg in "$@"; do
    if [[ $arg != -* ]]; then
      r="$arg"
      break
    fi
  done

  if [ -z "$r" ]; then
    r="Unknown command"
  fi

  CMD=$(echo "$r" | awk '{print toupper( substr( $0, 1, 1 ) ) substr( $0, 2 ); }')
}

check_prequisites() {
  if ! command -v restic &>/dev/null; then
    OUTPUT="restic is not installed"
    error "$OUTPUT"
    return 1
  fi
  if ! nc -z "$SERVER" 23 2>/dev/null; then
    OUTPUT="${SERVER}:23 not reachable"
    error "$OUTPUT"
    return 1
  fi
  if pgrep -x "restic" >/dev/null; then
    OUTPUT="backup job is already running. skip backup"
    info "$OUTPUT"
    return 2
  fi
  return 0
}

initialize_repository() {
  if restic cat config >/dev/null 2>&1; then
    REPO_INIT="repository $RESTIC_REPOSITORY already initialized"
    log "$REPO_INIT"
    return 0
  else
    log "repository $RESTIC_REPOSITORY is not initialized"
    log "initialize repository $RESTIC_REPOSITORY, now"
    if restic init 2>/dev/null; then
      REPO_INIT="successfully intialized repository $RESTIC_REPOSITORY"
      log "$REPO_INIT"
      return 1
    else
      REPO_INIT="failed to intialize repository $RESTIC_REPOSITORY on ${HETZNER_SERVER}:${HETZNER_PORT}"
      error "$REPO_INIT"
      return 2
    fi
  fi
}

execute_restic() {
  r=0
  set -o pipefail
  if ! output=$(restic "$@" 2>&1 | tee /dev/tty); then
    r=1
  fi
  # shellcheck disable=SC2001
  OUTPUT=$(sed 's/^/> /' <<<"$output")
  set +o pipefail
  return $r
}

check_free_storage() {
  if [[ -z $MAX_STORAGE ]] || [[ -z $THRESHOLD ]]; then
    # We want this to output $MAX_STORAGE and $THRESHOLD without expansion
    # shellcheck disable=SC2016
    FREE_STORAGE='storage check disabled. set $MAX_STORAGE and $THRESHOLD to enable it'
  fi

  if STORAGE_INFO=$(ssh "$SERVER" du -s /home 2>&1); then
    USED_STORAGE=$(echo "$STORAGE_INFO" | cut -f1)
    USED_PERCENT=$(printf %.2f "$(echo "$USED_STORAGE / $MAX_STORAGE * 100" | bc -l)")
    if (($(echo "$USED_PERCENT > $THRESHOLD" | bc -l))); then
      FREE_STORAGE="$USED_PERCENT%. WARNING: this is more than the threshold of $THRESHOLD%"
    else
      FREE_STORAGE="$USED_PERCENT%"
    fi
  else
    echo "$USED_STORAGE"
    FREE_STORAGE="failed to determine free storage"
  fi
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
