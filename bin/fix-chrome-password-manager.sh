#!/bin/sh

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
CURRENT_USER="${USER:-$(/usr/bin/id -un)}"
STARTUP_DELAY="${STARTUP_DELAY:-45}"
RETRY_COUNT="${RETRY_COUNT:-4}"
RETRY_DELAY="${RETRY_DELAY:-15}"
SYSTEM_POLICY_FILE="/Library/Managed Preferences/com.google.Chrome.plist"
USER_POLICY_FILE="/Library/Managed Preferences/${CURRENT_USER}/com.google.Chrome.plist"

log() {
  /usr/bin/printf '%s fix-chrome-password-manager: %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*"
}

sudo_n() {
  /usr/bin/sudo -n "$@"
}

if ! sudo_n /usr/bin/true 2>/dev/null; then
  log 'passwordless sudo is required when launchd runs this script.' >&2
  exit 1
fi

log "starting after ${STARTUP_DELAY}s delay for user ${CURRENT_USER}"
/bin/sleep "${STARTUP_DELAY}"

attempt=1
while [ "${attempt}" -le "${RETRY_COUNT}" ]; do
  log "cleanup attempt ${attempt}/${RETRY_COUNT}"
  sudo_n /bin/rm -rf "${SYSTEM_POLICY_FILE}"
  sudo_n /bin/rm -rf "${USER_POLICY_FILE}"
  /usr/bin/killall cfprefsd 2>/dev/null || true

  if [ ! -e "${SYSTEM_POLICY_FILE}" ] && [ ! -e "${USER_POLICY_FILE}" ]; then
    log 'managed preference files are absent'
    break
  fi

  if [ "${attempt}" -lt "${RETRY_COUNT}" ]; then
    log "managed preference files still exist; retrying in ${RETRY_DELAY}s"
    /bin/sleep "${RETRY_DELAY}"
  fi

  attempt=$((attempt + 1))
done

if [ -e "${SYSTEM_POLICY_FILE}" ] || [ -e "${USER_POLICY_FILE}" ]; then
  log 'managed preference files still exist after retries'
  exit 1
fi

/usr/bin/killall "Google Chrome Helper" 2>/dev/null || true
/usr/bin/killall "Google Chrome" 2>/dev/null || true
/bin/sleep 5
/usr/bin/open -a "Google Chrome"
log 'chrome reopen requested'
