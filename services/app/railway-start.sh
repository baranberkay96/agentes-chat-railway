#!/bin/sh
# Start agentes.chat on Railway. Never exits on a variable's value: an odd value falls back to a
# safe default with a warning, so a typo in the deploy form can't put the service in a restart loop.
set -u

log() { echo "railway-start: $*" >&2; }
hash() { printf '%s' "$1" | sha256sum | cut -d' ' -f1; }

# Public address: sign-in cookies, the allowed browser origin and every link come from it.
case "${PUBLIC_URL:-}" in
  http://?* | https://?*) PUBLIC_URL=${PUBLIC_URL%/} ;;
  *)
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
      log "PUBLIC_URL '${PUBLIC_URL:-}' is not an http(s) address; using https://${RAILWAY_PUBLIC_DOMAIN}"
      PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
    else
      log "PUBLIC_URL is not set and the service has no public domain; using http://localhost:${PORT:-3000}"
      PUBLIC_URL="http://localhost:${PORT:-3000}"
    fi
    ;;
esac
export PUBLIC_URL

# AGENTES_SECRET encrypts stored provider keys. The server refuses one under 32 characters; a shorter
# value typed into the deploy form is stretched the same way at every start, so stored keys stay readable.
AGENTES_SECRET=${AGENTES_SECRET:-}
if [ "${#AGENTES_SECRET}" -lt 32 ]; then
  if [ -z "$AGENTES_SECRET" ]; then
    log "AGENTES_SECRET is empty: the server can't start without it. Set a random value of 32+ characters on this service and redeploy."
    log "Starting with a throwaway secret meanwhile: provider keys saved now become unreadable once you set the real one."
    AGENTES_SECRET=$(head -c 48 /dev/urandom | sha256sum | cut -d' ' -f1)
  else
    log "AGENTES_SECRET is shorter than 32 characters; using its SHA-256. Set a longer random value when you can (stored keys must then be entered again)."
    AGENTES_SECRET=$(hash "agentes-secret:${AGENTES_SECRET}")
  fi
fi
export AGENTES_SECRET

# The agents' computer service connects with HOST_COMPUTER_TOKEN. The computer service derives a short
# token the same way, so both sides keep matching. The server refuses it together with open sign-up.
if [ -n "${HOST_COMPUTER_TOKEN:-}" ]; then
  if [ "${#HOST_COMPUTER_TOKEN}" -lt 32 ]; then
    log "HOST_COMPUTER_TOKEN is shorter than 32 characters; using its SHA-256 (the computer service does the same)."
    HOST_COMPUTER_TOKEN=$(hash "agentes-host:${HOST_COMPUTER_TOKEN}")
  fi
  case "$(printf '%s' "${ALLOW_SIGNUP:-false}" | tr 'A-Z' 'a-z')" in
    true | 1 | yes | on)
      log "ALLOW_SIGNUP is on, which the server doesn't allow together with HOST_COMPUTER_TOKEN: the computer service stays disconnected."
      unset HOST_COMPUTER_TOKEN
      ;;
    *) export HOST_COMPUTER_TOKEN ;;
  esac
fi

# The first account owns the installation. Only the link {PUBLIC_URL}/owner#claim={AGENTES_OWNER_CLAIM_TOKEN}
# may create it, so a stranger who finds the new domain first can't take it over.
if [ -z "${OWNER_CLAIM_SHA256:-}" ]; then
  claim=${AGENTES_OWNER_CLAIM_TOKEN:-}
  if printf '%s' "$claim" | grep -Eq '^[A-Za-z0-9_-]{20,200}$'; then
    OWNER_CLAIM_SHA256=$(hash "$claim")
  else
    log "AGENTES_OWNER_CLAIM_TOKEN must be 20-200 characters of A-Z a-z 0-9 _ -. Creating the owner account stays locked until it is; accounts made before stay as they are."
    OWNER_CLAIM_SHA256=$(head -c 48 /dev/urandom | sha256sum | cut -d' ' -f1)
  fi
  export OWNER_CLAIM_SHA256
fi
unset AGENTES_OWNER_CLAIM_TOKEN

case "${PORT:-}" in
  '' | *[!0-9]*) log "PORT '${PORT:-}' is not a number; using 3000"; export PORT=3000 ;;
esac

exec bun /app/apps/server/src/main.ts "$@"
