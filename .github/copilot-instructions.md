# Copilot instructions for this repo

These notes make AI agents productive immediately in this Hubot project (bot name: "batpoet"). Keep answers specific to this codebase.

## What this project is
- A Node.js Hubot bot that runs on Slack and Discord. Local development uses the shell adapter via hubot-dotenv.
- State is persisted with Redis (hubot-redis-brain). Docker Compose provides Redis; production can use any REDIS_URL.
- External capabilities are pulled in via `external-scripts.json` and configured by environment variables (see each script’s README).

## How it runs (quickref)
- Local CLI: `npm run local` (loads `.env` via hubot-dotenv; alias is `!`; name is `batpoet`).
- Slack: `npm run start:slack` (adapter slack; requires Slack credentials in env).
- Discord: `npm run start:discord` (adapter discord; requires Discord credentials in env).
- Docker: `docker compose up` uses the `Dockerfile` entrypoint `bin/start.sh` to launch Slack and Discord concurrently; both set `PORT=0` to avoid conflicts.
- Procfile: `web: npm run start` for PaaS that honor Procfiles.
- Tests: `npm test` only checks env configuration via hubot-dotenv’s `--config-check`.

## Key files and patterns
- `package.json`
  - Node pinned via Volta: `20.17.0`.
  - Scripts: `start:slack`, `start:discord`, `local`, `test`. Prefer these commands over hand-rolled node invocations.
- `bin/hubot` wraps hubot startup, prepends local binaries to PATH; used by start scripts.
- `bin/start.sh` spawns Slack and Discord in background and waits; this is the container entrypoint.
- `external-scripts.json` lists installed Hubot scripts loaded at startup.
- `scripts/` holds custom behaviors:
  - `ftfy.js` rewrites messages that start with `.` to the correct alias (`!`) using `TextMessage` and `robot.receive()`.
  - `deploy.js` triggers a Jenkins job; uses Slack thread replies (`thread_ts`) and attachment formatting. This is Slack-specific.

## Environment and integration notes
- Core env you’ll likely need:
  - Redis: `REDIS_URL=redis://...` for hubot-redis-brain. In Docker Compose, service DNS is `nashvillest-redis`. Note: Compose sets `REDIS_URL=redis://nashvillest-redis:16379` (non-default port); default Redis is 6379.
  - Adapters: Slack/Discord tokens and secrets per adapter docs (do not guess names; consult `hubot-slack` and `hubot-discord`).
  - hubot logging: set `HUBOT_LOG_LEVEL=debug` for verbose logs.
- Local config flows through `.env` (copy from `.env-dist` if present) and is loaded by `hubot-dotenv`.

## Conventions to follow
- New bot features live in `scripts/*.js` and export `(robot) => { ... }` using Hubot APIs: `robot.hear`, `robot.respond`, `robot.router`, etc.
- Favor Slack threads for long-running actions when interacting in Slack (see `deploy.js`’s use of `thread_ts`).
- If adding third-party scripts:
  1) add the package to `dependencies`,
  2) list it in `external-scripts.json`,
  3) document required env vars in `README.md` and `.env-dist`.

## Gotchas and tips
- The container starts both Slack and Discord; ensure credentials for both or disable one by overriding the entrypoint/command.
- `PORT=0` in start scripts is intentional to avoid binding conflicts. Don’t remove unless you know the adapter’s network needs.
- Some external scripts (weather, hockey, etc.) require API keys; missing keys can cause runtime warnings or disabled commands, not crashes.
- When using Redis in Compose, verify `REDIS_URL` host and port match the running service; Compose uses `nashvillest-redis:16379`.

## Example: add a simple command
- Create `scripts/hello.js` exporting a function that registers `robot.respond(/hello/i, (msg) => msg.reply('Hi!'))`.
- Run locally with `npm run local` and test with `! hello`.

If anything here is unclear (e.g., adapter env names, Redis setup, or deploy flow), tell me what you want to improve and I’ll refine these instructions.
