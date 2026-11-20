#!/bin/sh
# Root part of the agents' computer: prepares the volume (/home/agent) and hands over to the
# unprivileged user `agent`, which runs the agentes runner. Never exits on a variable's value.
set -u
log() { echo "computer: $*" >&2; }

home=/home/agent
mkdir -p "$home"
# A fresh Railway volume belongs to root; the home and the runner's state belong to agent.
[ "$(stat -c %u "$home")" = 1000 ] || chown 1000:1000 "$home"
chmod 0750 "$home"
for f in .bashrc .profile; do
  [ -e "$home/$f" ] || install -o 1000 -g 1000 -m 0644 "/etc/skel/$f" "$home/$f" 2>/dev/null || true
done
if [ -d "$home/.agentes-runner" ] && [ "$(stat -c %u "$home/.agentes-runner")" != 1000 ]; then
  chown -R 1000:1000 "$home/.agentes-runner"
fi

exec setpriv --reuid=1000 --regid=1000 --init-groups --inh-caps=-all \
  env HOME="$home" USER=agent LOGNAME=agent SHELL=/bin/bash \
  PATH="$home/.local/bin:/usr/local/bin:/usr/bin:/bin" \
  /usr/local/bin/computer-run
