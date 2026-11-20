#!/bin/sh
# The agents' computer: downloads the runner from the agentes.chat service (always the server's own
# version) and runs it as this server's computer (`agentes-runner host`, HOST_COMPUTER_TOKEN). It joins
# every organization the installation's owner creates, within a minute.
set -u
log() { echo "computer: $*" >&2; }
idle() {
  log "$1"
  log "Idling; fix the variable on the computer service and redeploy it."
  exec sleep infinity
}

server=${AGENTES_SERVER_URL:-}
server=${server%/}
case "$server" in
  http://?* | https://?*) ;;
  *) idle "AGENTES_SERVER_URL '${server}' is not an http(s) address of the agentes.chat service." ;;
esac

token=${HOST_COMPUTER_TOKEN:-}
[ -n "$token" ] || idle "HOST_COMPUTER_TOKEN is empty: it must equal the one on the agentes.chat service."
if [ "${#token}" -lt 32 ]; then
  # Same derivation as the agentes.chat service's start script, so both sides keep matching.
  token=$(printf '%s' "agentes-host:${token}" | sha256sum | cut -d' ' -f1)
fi
export HOST_COMPUTER_TOKEN="$token"

name=${AGENTES_COMPUTER_NAME:-}
case "$name" in
  '' | *[!A-Za-z0-9\ ._-]*) name="Railway computer" ;;
esac

runner_home="$HOME/.agentes-runner"
bundle="$runner_home/agentes-runner.mjs"
mkdir -p "$runner_home" "$HOME/agentes"

# The server may still be starting (it migrates its database first): wait for it.
waited=0
until curl -fsS --max-time 60 -o "$bundle.download" "$server/runner/agentes-runner.mjs"; do
  if [ "$waited" -eq 0 ]; then log "waiting for $server to serve the runner"; fi
  waited=$((waited + 10))
  if [ $((waited % 300)) -eq 0 ]; then log "still waiting for $server after ${waited}s"; fi
  sleep 10
done
mv "$bundle.download" "$bundle"
log "runner downloaded from $server; connecting as \"$name\""

cd "$HOME"
exec bun "$bundle" host --server "$server" --token-env HOST_COMPUTER_TOKEN --name "$name"
