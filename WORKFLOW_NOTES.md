# Visadelab Workflow Notes

## Core Workflow

- MBA local repos are the source of truth.
- MBP `192.168.1.11` is the deploy/server machine.
- Development and git updates happen on the MBA first.
- Deployment then syncs code from MBA to MBP.
- Do not treat MBP deploy copies as the primary source unless explicitly doing emergency hotfix recovery.

## Safety Rules

- Never commit secrets to git.
- Keep `.env`, `.env.local`, cloudflared credentials, app passwords, tokens, and private keys out of GitHub.
- If there is any version ambiguity, compare MBA source repo vs MBP deploy copy before editing.

## Current Server Setup

- MBP host: `gary@192.168.1.11`
- Mac mini old host: `garytan@192.168.1.10`
- MBP is the active server now.
- Cloudflared tunnel has been cut over from Mac mini to MBP.
- PM2 services are running on MBP.

## Project Map

- `portal`
- `tunanote`
- `tunatrade`
- `tunatcm`
- `tunaspend`
- `buddhist-footprints`
- `telegram-bot`

## Cross-Project Conventions

- Application naming and branding:
  - App names such as `TunaTCM`, `TunaSpend`, and related Tuna apps use a two-tone visual treatment.
  - Preserve that shared design language when updating headers, logos, or app titles.

- Shared login / password flow:
  - Login, password handling, and credential storage should move toward one shared cross-project pattern.
  - This convention can be referred to as `TunaLogin`.
  - Some earlier work may already exist in a plugin-like or reusable form, but full cross-project unification is not complete yet.
  - When touching auth in any project, prefer moving it toward the `TunaLogin` pattern instead of inventing a one-off flow.

- Versioning:
  - `visadelab portal` shows project version numbers and already has a simple maintenance mechanism for this.
  - That version-display mechanism has now been confirmed:
    - portal does not store versions itself
    - portal fetches each app's `data-health` endpoint
    - the app card shows `v{version}` when `/api/health` returns JSON with a `version` field
  - Portal is only the display layer; each app is responsible for returning its own correct current version.
  - Some projects are still missing displayed version numbers in the portal, or the displayed version is not the true latest version.
  - When working on those projects later, update the portal listing so it reflects the correct current version.
  - Project version numbers are usually displayed at the top-left of the app UI.
  - Global convention: each build can increment the version by `0.1`.
  - Preferred cross-project pattern:
    - keep one clear app version source in the project
    - expose `/api/health`
    - return `{ status, app, version }`
    - let portal read and display that value
  - Current known status:
    - `TunaTrade` returns version via `/api/health`
    - `TunaNote` returns version via `/api/health`
    - `Buddhist Footprints` returns version via `/api/health`
    - `TunaTCM` returns version via `/api/health`
    - `TunaSpend` still needs a proper `/api/health` version response
    - `Telegram Bot` is not yet represented correctly in portal version display

- Shared UI utilities:
  - A reusable small-tool pattern called `TunaPullMenu` exists.
  - It is already used in `tunatcm`.
  - This utility is intended to be reused across projects when the same dropdown/pull-down interaction pattern is needed.

## Repo / Deploy Principle

- Use MBA `~/Documents/...` repos as the main development repos.
- MBP contains deploy/runtime copies, including some `-dist` folders.
- Review deploy behavior project by project when making changes.
- Many projects already have a `deploy.sh`; prefer using the project's existing deploy flow.

## Known Notes

- `tunanote` has been synced back to MBA and MBA is now the latest mainline copy.
- `tunatcm` uses local SQLite on MBP.
- `tunatrade` uses Neon.
- `tunaspend` uses Supabase.
- `buddhist-footprints` uses Supabase.
- Supabase keep-alive script has been moved to MBP.

## Reminder

- After future reboot-related work, verify MBP auto-recovery for:
  - PM2 apps
  - cloudflared
  - login vs no-login startup behavior
