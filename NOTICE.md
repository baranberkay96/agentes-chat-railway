# Notice

This package is a Railway template that runs the open-source agentes-chat software (AGPL-3.0); community template, not affiliated with AGENTESCHAT, LLC.

## agentes-chat

- Source: https://github.com/agentes-chat/agentes-chat, release v0.1.10 (commit 2f3ccf0, 2026-11-20)
- License: GNU AGPL-3.0-only, with the additional terms in upstream's NOTICE file. Attribution: "Based on agentes.chat by AGENTESCHAT, LLC".
- Used here, unmodified, as published container images:
  - `ghcr.io/agentes-chat/agentes:0.1.10@sha256:934922e7e48e2922bf77ab5ee0a5f32c82035dc7632ec7ec3c78fe8b1b14cae6`
  - `ghcr.io/agentes-chat/backup:0.1.10@sha256:e659b8a2b78fe464d90a9a27ffd4a3e6d72a637e3511b518f3079669a3eb821a`
- The computer service downloads the agentes runner (`/runner/agentes-runner.mjs`) from the deployed server at start; it is part of the same AGPL-3.0 code.
- The source of the version you run is linked from the About screen of every app (`SOURCE_URL`, default the upstream repository). This template does not modify the agentes-chat code; it only adds start scripts around the images.
- Trademarks: the listing name and icon do not use the upstream name or logo (upstream TRADEMARKS.md reserves them for product and hosted-service names). The upstream name appears only to state factually which software is run.
- Upstream files checked for this template: `docker-compose.yml`, `SELF_HOSTING.md`, `.env.example`, `packages/config/src/schema.ts`, `deploy/backup/*`, `deploy/coolify/docker-compose.yaml`, `apps/server/runner/{host,install-script,browser,desktop-session}.ts`, `apps/server/src/owner-claim.ts` at v0.1.10.

## Files written for this template (MIT, this repository)

- `services/app/Dockerfile`, `services/app/railway-start.sh`
- `services/computer/Dockerfile`, `services/computer/computer-start.sh`, `services/computer/computer-run.sh`
- `template.json`, `TEMPLATE.md`, `README.md`

The market template `agentes-chat` (a `node:22` computer service installing packages at every boot) was read for ideas; no files or text were copied from it.

## Third-party software in the computer image

| Component | Version | Source | License |
|---|---|---|---|
| Debian | 13 (trixie-slim, digest-pinned) | Docker Hub `debian` | Various free licenses |
| Google Chrome | stable at build time | dl.google.com | Google Chrome Terms of Service |
| Bun | 1.4.4 (SHA-256 checked) | github.com/oven-sh/bun | MIT |
| Node.js | 22.23.5 (SHA-256 checked) | nodejs.org | MIT |
| Claude Code | 2.1.311 (SHA-256 checked) | downloads.claude.ai | Anthropic Commercial Terms |
| Codex CLI | 0.171.0 | npm `@openai/codex` | Apache-2.0 |

## Other images

- Postgres: `ghcr.io/railwayapp-templates/postgres-ssl:18.6` (Railway, includes pgvector), PostgreSQL License.
