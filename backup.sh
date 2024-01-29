#!/bin/bash

CMD=NULL
WARNING=NULL
ERROR=NULL

main () {
  START_TIME=`date +%s`

  # read configuration
  . .env

  CMD=$(echo `getCmd "$@"` | awk '{print toupper($0)}')
  check_free_storage

  END_TIME=`date +%s`
  DURATION=$((($END_TIME - $START_TIME) / 60))

  if [ -z $ERROR ]; then
    MSG="error - $CMD unsuccessful. $ERROR"
  elif [ -z $WARNING ]; then
    MSG="warning - $CMD successful. $WARNING"
  else
    MSG="info - $CMD successful"
  fi
  echo "$MSG"
  echo "time: $DURATION minutes"

  # log "$MSG"
  # TMP=$(sed 's/^/> /' <<< "$OUTPUT")
  # TMP=$(echo -e "$MSG\n\n$TMP")
  # mail "INFO" "$TMP"
}

getCmd () {
  for arg in "$@"; do
    if [[ $arg != -* ]]; then
      echo $arg
      break
    fi
  done
}

check_free_storage () {
  if [[ -z $MAX_STORAGE ]] || [[ -z $THRESHOLD ]]; then
    return
  fi

  # if result=$(ssh $SERVER du -s /home 2>&1); then
  #   echo $?
  #   stdout=$result
  #   echo $stdout
  # else
  #     echo $?
  #     stderr=$result
  #     echo $stderr
  # fi
  STORAGE_INFO=$(ssh $SERVER du -s /home 2>&1)
  if [ ! -z "$STORAGE_INFO" ]; then
    USED_STORAGE=$(echo "$STORAGE_INFO" | cut -f1)
  fi
  # if [ $? -ne 0 ]; then
  #   echo "failed"
  # fi

  # USED_PERCENT=$(echo "$USED_STORAGE / $MAX_STORAGE * 100" | bc -l)
  # echo $USED_PERCENT
  # if (( $(echo "$USED_PERCENT > $THRESHOLD" | bc -l) )); then
  #   echo "oh no"
  # fi
}

# # log () { echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"; }
# # info () { log "info - $1"; }
# # warning () { log "warning - $1"; }
# # error () { log "error - $1"; }
# # mail () {
# #   if [ "$MAIL_DISABLED" = true ]; then return; fi

# #   {
# #     echo "From: $MAIL_FROM"; echo "Subject: Backup $HOSTNAME - $1"; echo "$2";
# #   } | sendmail -v $MAIL_TO > /dev/null 2>&1

# #   if [ "$?" -ne 0 ]; then error "failed to send mail"; fi
# # }
# # info_mail () { info "$1"; mail "INFO" "info - $1"; }
# # warning_mail () { warning "$1"; mail "WARNING" "warning - $1"; }
# # error_mail () { error "$1"; mail "ERROR" "error - $1"; exit 1; }

# # if [[ -z $MAIL_TO ]] || [[ -z $MAIL_FROM  ]] || [[ -z $(command -v sendmail) ]]; then
# #   info 'disabled mails as either $MAIL_TO and $MAIL_FROM are not set or sendmail is not installed'
# #   MAIL_DISABLED=true
# # fi
# # if ! command -v restic &> /dev/null; then error_mail "restic is not installed"; fi
# # if ! nc -z $HETZNER_SERVER $HETZNER_PORT 2>/dev/null; then error_mail "${HETZNER_SERVER}:${HETZNER_PORT} not reachable"; fi
# # if pgrep -x "restic" > /dev/null; then info_mail "backup job is already running. skip backup"; exit 0; fi

# # export RESTIC_PASSWORD=$RESTIC_PASSWORD
# # export RESTIC_REPOSITORY=$RESTIC_REPOSITORY
# # echo "$RESTIC_REPOSITORY"
# # if restic cat config > /dev/null 2>&1 ; then
# #   log "repository $RESTIC_REPOSITORY already initialized"
# # else
# #   log "repository $RESTIC_REPOSITORY is not initialized"
# #   log "initialize repository $RESTIC_REPOSITORY, now"
# #   if restic init 2>/dev/null; then
# #     log "successfully intialized repository $RESTIC_REPOSITORY"
# #   else
# #     error "failed to intialize repository $RESTIC_REPOSITORY on ${HETZNER_SERVER}:${HETZNER_PORT}"
# #   fi
# # fi

# # # TODO refactor
# # set -o pipefail
# # OUTPUT=$(restic "$@" | tee /dev/tty)
# # if [ $? -ne 0 ]; then
# #   END_TIME=`date +%s`
# #   MSG="error - backup failed. it took $((($END_TIME - $START_TIME) / 60)) minutes."
# #   log "$MSG"
# #   TMP=$(sed 's/^/> /' <<< "$OUTPUT")
# #   TMP=$(echo -e "$MSG\n\n$TMP")
# #   # TODO enable
# #   mail "ERROR" "$TMP"
# #   exit 1
# # fi
# # set +o pipefail

main "${@:1}"
