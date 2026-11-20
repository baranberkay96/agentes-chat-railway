# agentes.chat AI Team Chat: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **agentes.chat AI Team Chat** (no version label: upstream is at 0.1.10) |
| Description | Self-hosted team chat where AI agents work in channels, with a computer (71 chars) |
| Category | AI/ML |
| Tags | agentes, team-chat, slack-alternative, ai-agents, claude, codex, mcp, self-hosted |
| Icon | upstream `apps/web/public/favicon.svg` at v0.1.10 via jsDelivr (200, image/svg+xml) |
| Repo | `baranberkay96/agentes-chat-railway`, service roots `/services/app`, `/services/computer` |

## Feasibility (checked 2026-11-20)

- **License.** AGPL-3.0-only with upstream NOTICE terms. COMMERCIAL.md allows running it for others and charging for the work; TRADEMARKS.md allows self-hosting with its branding and saying "we host agentes.chat for clients", and asks for permission to use the name in a product or hosted-service name. The listing names the app it deploys and says "community template" (open question below).
- **Stack.** One Bun process (web, API, WebSockets, jobs) and Postgres 15+ with pgvector. Files go to a folder, S3, or Postgres. Upstream's optional services (speech, embeddings) are profiles that are off by default and are left out.
- **Agents' computer without Docker.** Agents act through a "computer" that runs the agentes runner. `agentes-runner host` with `HOST_COMPUTER_TOKEN` joins the server as "this server's computer". As a non-root user it runs in single-user mode (no systemd needed); system mode (an OS user per agent, desktops) needs root and systemd and is not possible in a Railway service. Commands, Google Chrome (agent-browser), Claude Code and Codex work in single-user mode; desktop use reports `desktop_use_own_user` (measured).
- **No nested containers** are involved (STANDARD 8.32 not triggered). Chrome needs `--no-sandbox` (no user namespaces), added by a wrapper at the path the runner uses.

## Market templates

`agentes-chat` (1 active, 3 total): app on `:latest`, Postgres 18 without pgvector pin, a `node:22-bookworm` computer that installs Chrome, XFCE and Bun at every boot (`curl | sh` from the server and bun.sh), files on a volume, first-signup-wins owner.

Improvements here: images pinned by digest; the computer is a prebuilt Debian 13 image (Chrome, Bun 1.4.4, Node 22, Claude Code, Codex with checksums), nothing installed at boot except the version-matched runner from the server itself; the owner account can only be created with a secret claim link (`OWNER_CLAIM_SHA256`); files in a Railway Bucket; daily `pg_dump` to a second Bucket with upstream's backup image; odd deploy-form values never stop a service; telemetry off by default; unusable XFCE/TigerVNC packages left out.

## Pinned versions

| Component | Reference | Checked |
|---|---|---|
| agentes.chat | `ghcr.io/agentes-chat/agentes:0.1.10@sha256:934922e7…cae6` (879 MB compressed, amd64) | 2026-11-20 |
| backup | `ghcr.io/agentes-chat/backup:0.1.10@sha256:e659b8a2…821a` | 2026-11-20 |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl:18.6@sha256:4fc833b4…c863` (pgvector 0.8 included) | 2026-11-20 |
| Debian | `debian:trixie-slim@sha256:a72b4433…b6b2` | 2026-11-20 |
| Bun | 1.4.4 (the runner installer's pin), SHA-256 | 2026-11-20 |
| Node.js | 22.23.5, SHA-256 | 2026-11-20 |
| Claude Code | 2.1.311, SHA-256 | 2026-11-20 |
| Codex | `@openai/codex@0.171.0` | 2026-11-20 |
| Google Chrome | stable at build time (158.0.8127.36 on the test build), not pinnable (STANDARD 8.27) | 2026-11-20 |

## Architecture

```
Browser / phone / desktop app ──https──► agentes :3000 (Bun: web, API, WS, jobs) ──► Postgres (pgvector)
                                              │  └─► Files bucket (S3: uploads, artifacts, presigned downloads)
computer (runner host, user agent) ──private http──┘  (downloads /runner/agentes-runner.mjs, machine protocol)
backup ──► Postgres (pg_dump) ──► Backups bucket (rclone)
```

## Services and variables

| Service | Source | Health | Domain | Volume |
|---|---|---|---|---|
| agentes | repo `/services/app` (`FROM` digest + start script) | `/api/health`, 600 s | public, 3000 | – (files in Bucket) |
| computer | repo `/services/computer` | – (no HTTP) | private | `/home/agent` |
| backup | image (digest) | – | private | – |
| Postgres | `postgres-ssl:18.6` | – | private | `/var/lib/postgresql/data` |
| Files, Backups | Railway Buckets | | | |

agentes: `PORT=3000`, `HOST=::`, `PUBLIC_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}`, `DATABASE_URL`, `AGENTES_SECRET` (`secret(64)`), `AGENTES_OWNER_CLAIM_TOKEN` (`secret(40)`; the start script exports its SHA-256 as `OWNER_CLAIM_SHA256`), `HOST_COMPUTER_TOKEN` (`secret(48)`), `S3_*` from the Files bucket with `S3_PATH_STYLE=false`, `TELEMETRY=off`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS=40`.
computer: `AGENTES_SERVER_URL=http://${{agentes.RAILWAY_PRIVATE_DOMAIN}}:${{agentes.PORT}}`, `HOST_COMPUTER_TOKEN` (reference), `AGENTES_COMPUTER_NAME`.
backup: `DATABASE_URL`, `S3_PROVIDER=Other`, `S3_*` and `S3_BACKUP_BUCKET` from the Backups bucket, `RCLONE_S3_FORCE_PATH_STYLE=false`, `BACKUP_INTERVAL_HOURS=24`, `BACKUP_RETENTION_DAYS=14`.

Start-script fallbacks (STANDARD 8.29): invalid `PUBLIC_URL` → `https://$RAILWAY_PUBLIC_DOMAIN`; `AGENTES_SECRET` under 32 chars → its SHA-256 (stable across restarts), empty → throwaway with a warning; `HOST_COMPUTER_TOKEN` under 32 chars → SHA-256 on both sides; `ALLOW_SIGNUP=true` → computer token dropped (the server refuses both); invalid claim token → owner sign-up locked with a random hash; invalid `PORT` → 3000. Computer: invalid server URL or empty token → idles with a log line instead of exiting.

## Resource profile (measured on Railway, 2026-11-20)

| Service | Idle RAM | CPU |
|---|---|---|
| agentes | 0.34 GB | ~0.04 vCPU |
| computer | 0.28 GB (runner connected, no agent running) | ~0 |
| Postgres | 0.26 GB | ~0.02 vCPU |
| backup | < 0.01 GB | ~0 |

About 0.9 GB idle: roughly $9–10/month at Railway prices before agent work, plus Bucket storage. Chrome tabs, Claude Code or Codex sessions and builds add memory on the computer (1–2 GB while busy is realistic). Minimum plan: Hobby (fits Trial's 1 GB per service at idle, but the computer has no headroom there).

## Test results (Railway, pre-publish, 2026-11-20)

- All four services SUCCESS on the first deploy; `/api/health` 200 with `{"status":"ok","version":"0.1.10","database":"ok"}`. Migrations created the vector extension on `postgres-ssl:18.6`.
- backup: dumped at start and uploaded to the Backups bucket (`agentes-20261120-144313.dump uploaded`).
- Owner gate: owner-claim with a wrong token 401; plain email sign-up 403; claim with the generated token 201; a second claim 409.
- Signed in, created a workspace (201). Within 60 s the computer logged `[Railway Test] runner started … connected as Railway computer`; the machines API showed it online, `mode: single`, Chrome 158 available, commands on, desktop use unavailable (`desktop_use_own_user`).
- Posted a message to #general (201) and read it back.
- Uploaded a file (201, storage `platform.kind=bucket`), fetched it back through the presigned Bucket URL with the same bytes.

## Verification checklist

1. Four services SUCCESS; `https://{domain}/api/health` is 200.
2. Open `/owner#claim={AGENTES_OWNER_CLAIM_TOKEN}`, create the owner, finish onboarding with a model key.
3. Settings › Devices shows "Railway computer" online within a minute.
4. Ask an agent to open a website and summarize it (browser), and to run `python3 --version` (commands).
5. backup log shows `uploaded`; redeploy agentes and Postgres: messages and files remain.

## Open questions

- Trademark: TRADEMARKS.md reserves "agentes.chat" in names of products and hosted services. The listing uses it only to name what the template deploys, with "community template" in the README; the user may want written permission or a different listing name.
- Agent runs with a real model key were not tested (no provider keys for tests).
- Desktop use is unavailable on Railway (upstream requires system mode). Upstream may add it to single-user mode later; then XFCE/TigerVNC can be added back to the computer image.
