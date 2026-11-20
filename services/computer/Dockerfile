# The agents' computer for agentes.chat on Railway: a Debian 13 machine with what the agentes runner
# uses there (Google Chrome, Bun, Claude Code, Codex), run as one unprivileged user. The runner
# itself is downloaded from the agentes.chat service at every start, so it always matches the server's version.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

ARG PIN_BUN=1.4.4
ARG PIN_BUN_SHA256=bf8ccbfb2b0b80159e0f9a6d15c55317add8077534dbc6130a3edb52fccb395c
ARG PIN_NODE=22.23.5
ARG PIN_NODE_SHA256=cdeb8670a0c81f51b4dc4ac61919f9b1ad917b304bf8221eb939570663d240f8
ARG PIN_CLAUDE_CODE=2.1.311
ARG PIN_CLAUDE_CODE_SHA256=86dc1fcc69498159eaf15f446613e847010f9036bfbbdffd4c49350be8489ada
ARG PIN_CODEX=0.171.0

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# Base tools for the agents' commands, and fonts for the pages their browser renders (CJK included).
# No XFCE/TigerVNC screens: the runner offers desktop use only in system mode (each agent its own
# user, which needs root and systemd), and a Railway service runs it in single-user mode.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip xz-utils git openssh-client procps iproute2 less nano jq file \
      python3 python3-venv fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji \
 && rm -rf /var/lib/apt/lists/*

# Google Chrome stable, where the runner looks for it (/opt/google/chrome/chrome). Google keeps only the
# current build downloadable, so it is not pinned (STANDARD 8.27). Railway containers can't create the
# user namespaces Chrome's sandbox needs, so a wrapper starts it with --no-sandbox.
RUN curl -fsSL --retry 5 --retry-all-errors -o /tmp/chrome.deb \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends /tmp/chrome.deb \
 && rm -rf /var/lib/apt/lists/* /tmp/chrome.deb /etc/apt/sources.list.d/google-chrome.list* \
 && mv /opt/google/chrome/chrome /opt/google/chrome/chrome.real \
 && printf '%s\n' '#!/bin/sh' \
      '# Railway: no user namespaces for the sandbox; /dev/shm is small.' \
      'exec /opt/google/chrome/chrome.real --no-sandbox --disable-dev-shm-usage "$@"' \
      > /opt/google/chrome/chrome \
 && chmod 0755 /opt/google/chrome/chrome \
 && /opt/google/chrome/chrome --version

# Bun (the runner's runtime, the version its installer pins), Node.js LTS (for Codex), Claude Code and
# Codex, from release downloads that stay available, checksum-verified.
RUN curl -fsSL --retry 5 --retry-all-errors -o /tmp/bun.zip \
      "https://github.com/oven-sh/bun/releases/download/bun-v${PIN_BUN}/bun-linux-x64.zip" \
 && echo "${PIN_BUN_SHA256}  /tmp/bun.zip" | sha256sum -c - \
 && unzip -q /tmp/bun.zip -d /tmp \
 && install -m 0755 /tmp/bun-linux-x64/bun /usr/local/bin/bun \
 && rm -rf /tmp/bun.zip /tmp/bun-linux-x64 \
 && curl -fsSL --retry 5 --retry-all-errors -o /tmp/node.tar.xz \
      "https://nodejs.org/dist/v${PIN_NODE}/node-v${PIN_NODE}-linux-x64.tar.xz" \
 && echo "${PIN_NODE_SHA256}  /tmp/node.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
      --exclude CHANGELOG.md --exclude README.md --exclude LICENSE \
 && rm -f /tmp/node.tar.xz \
 && curl -fsSL --retry 5 --retry-all-errors -o /usr/local/bin/claude \
      "https://downloads.claude.ai/claude-code-releases/${PIN_CLAUDE_CODE}/linux-x64/claude" \
 && echo "${PIN_CLAUDE_CODE_SHA256}  /usr/local/bin/claude" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/claude \
 && npm install -g --no-fund --no-audit "@openai/codex@${PIN_CODEX}" \
 && npm cache clean --force \
 && bun --version && node --version && claude --version && codex --version

# The user the agents work as. Its home is the service's volume.
RUN useradd --uid 1000 --create-home --home-dir /home/agent --shell /bin/bash agent

COPY --chmod=0755 computer-start.sh /usr/local/bin/computer-start
COPY --chmod=0755 computer-run.sh /usr/local/bin/computer-run
CMD ["/usr/local/bin/computer-start"]
