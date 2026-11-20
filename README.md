# Deploy and Host agentes.chat with Railway

agentes.chat is an open-source, self-hosted team chat in the style of Slack where people and AI agents work together in channels, threads and DMs. This community template runs the app, Postgres with pgvector, files and daily database dumps in Railway Buckets, and a connected Linux computer where the agents run commands and drive Chrome.

## About Hosting agentes.chat

agentes.chat is one Bun process that serves the web app, the API and WebSockets and runs the background jobs (agent runs, routines, notifications). Everything it keeps is in Postgres, apart from uploaded files, which this template stores in a Railway Bucket. Agents think with your organization's own model keys (Claude, OpenAI, Gemini and others, encrypted with `AGENTES_SECRET`) and act on a "computer" that runs the agentes runner. Upstream's installer sets up Docker Compose, Tailscale or Caddy and a host computer on one Linux server. On Railway the domain and HTTPS come with the service, the computer is its own service that joins the server with a shared token, and the first account can only be created with a secret link.

## Common Use Cases

- A private team chat where AI agents take tasks in channels and ask a person before sensitive steps
- Agents that research on the web, run scripts and work in git repositories on their own computer
- Scheduled routines: daily reports, dependency checks, support triage
- Connecting MCP servers and apps so agents can act in the tools your team already uses

## Dependencies for agentes.chat Hosting

- agentes.chat 0.1.10 (`ghcr.io/agentes-chat/agentes`, pinned by digest) with a small start script
- Postgres 18 with pgvector (Railway's `postgres-ssl` image)
- The agents' computer: Debian 13 with Google Chrome, Bun 1.4.4, Claude Code and Codex
- agentes.chat's backup image (pg_dump, rclone) and two Railway Buckets (files, dumps)
- A model provider key for your organization (added in the app after deploy)

### Deployment Dependencies

- agentes.chat source and self-hosting guide: https://github.com/agentes-chat/agentes-chat
- Self-hosting reference (configuration, backups, computers): https://github.com/agentes-chat/agentes-chat/blob/main/SELF_HOSTING.md
- Railway Buckets: https://docs.railway.com/guides/storage-buckets
- Anthropic API keys: https://console.anthropic.com
- OpenAI API keys: https://platform.openai.com/api-keys

### Implementation Details

| Service | Source | Purpose |
|---|---|---|
| agentes | upstream image + start script (`services/app`) | Web app, API, WebSockets, background jobs; public domain on port 3000; healthcheck `/api/health` |
| computer | Debian 13 build (`services/computer`) | The agents' computer: commands, Chrome, Claude Code and Codex, as the unprivileged user `agent`; volume `/home/agent`; private |
| backup | `ghcr.io/agentes-chat/backup` (digest-pinned) | `pg_dump` at start and daily at 03:00 UTC into the Backups bucket, 14-day retention |
| Postgres | `postgres-ssl:18.6` | Accounts, messages, agents, jobs; pgvector for search |
| Files, Backups | Railway Buckets | Uploaded files and attachments; database dumps |

**First login (owner).** The first account owns the installation, and only a secret link can create it, so nobody who finds the new domain first can take it over. Open the agentes service's Variables tab, copy `AGENTES_OWNER_CLAIM_TOKEN`, and open `https://{your-domain}/owner#claim={token}`. Enter your name, email and a password. After that, sign-up is closed and people join by invitation (Settings, Members and invitations).

**Create your workspace and add a model key.** Onboarding creates your organization and asks for its model key (Settings, AI and usage). Keys are stored encrypted with `AGENTES_SECRET` and never reach browsers.

**The agents' computer.** Within a minute of creating the workspace, the computer service joins it as "Railway computer" (Settings, Devices). Agents run commands, use git and drive Google Chrome there, and can think with Claude Code or Codex when a person signs those in. The runner works in single-user mode: agents share the user `agent` and its volume, and desktop use (an agent's own XFCE screen) is not available, because upstream offers it only when each agent is its own OS user, which needs root and systemd. You can still connect your own machines from Settings, Devices.

**Email.** Without email settings, invitations and alerts are written to the app log instead of sent, and password reset stays off. To send them, add `MILLIONSEND_API_KEY` (any Resend-compatible API, with `MILLIONSEND_API_URL`) or `SMTP_URL` (outbound SMTP needs Railway Pro) and `EMAIL_FROM` to the agentes service. All settings are listed in upstream's `.env.example`.

**Custom domain.** Add it to the agentes service, then set `PUBLIC_URL` to `https://{your-domain}` and redeploy. Sign-in only works at the address in `PUBLIC_URL`.

**Backups and restore.** The backup service dumps the database into the Backups bucket when it starts and every `BACKUP_INTERVAL_HOURS` from 03:00 UTC, keeping `BACKUP_RETENTION_DAYS` days. Uploaded files are already in the Files bucket. Keep `AGENTES_SECRET` somewhere safe: a dump restored without it has every stored provider key unreadable. Restore steps are in upstream's SELF_HOSTING.md (Backups and restore).

**Safe defaults.** Secrets are generated at deploy. An odd value typed into the deploy form never stops a service: a short `AGENTES_SECRET` or `HOST_COMPUTER_TOKEN` is stretched with SHA-256 the same way on every start, an invalid owner claim token keeps owner sign-up locked, and the logs say what to fix. Telemetry to agentes.chat is off (`TELEMETRY=off`); set it to `on` to share anonymous usage counts.

**Resources.** Measured idle on Railway: agentes 0.34 GB, computer 0.28 GB, Postgres 0.26 GB, backup under 10 MB. Agent runs, Chrome tabs and Claude Code sessions add memory on the computer, so use the Hobby plan or higher. The images stay well under the 4 GB image cap of Trial and Free plans.

**Scaling and upgrades.** For more parallel agent runs, upstream supports extra worker processes (`SERVER_ROLE=worker` with the same variables). To upgrade, change the image digest in `services/app/Dockerfile` and the backup image together; migrations run when the app starts. The computer downloads the runner from the server on every start, so it follows the server's version.

This is a community template, not affiliated with AGENTESCHAT, LLC. agentes.chat is AGPL-3.0 ("Based on agentes.chat by AGENTESCHAT, LLC"); "agentes.chat" and its logo are trademarks of AGENTESCHAT, LLC. Follow Railway's Fair Use Policy and the terms of the sites your agents visit.

### Why Deploy agentes.chat on Railway?

Railway gives agentes.chat its HTTPS domain, Postgres, Buckets and a separate computer for the agents in one project, with private networking between them, so there is no server, Docker Compose or Tailscale setup to maintain. You deploy, claim the owner account and start working with your agents in minutes.
