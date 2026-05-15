# RepoReel — Design Spec

**Date:** 2026-05-15
**Hackathon:** HeyGen Hackathon, Demo Day
**Tracks targeted:** Product (primary), Agent (eligible)

## One-liner

A Claude Code skill. Type `/reporeel <github-url>` → get a shareable, interactive branching video walkthrough — an AI avatar narrator that lets viewers click between "what is this", "tour the code", and "see it run."

## Why this idea

- Turns the slow, manual Hyperframe authoring flow (the user's own pain point) into a one-command pipeline.
- The result IS a Hyperframe in everything but name: chaptered video with click-through branches.
- Solves a real problem: every OSS maintainer, dev influencer, and YC founder needs a 60-second video pitch of their repo. Nobody has time to script and record one.

## Why a skill, not a hosted SaaS

- **No backend, no infra cost** — the skill file *is* the product.
- **Distribution = Anthropic Skills marketplace** — one-click install for any Claude Code user.
- **No Anthropic API key needed** — planning happens inside the user's own Claude session, billed via their existing subscription.
- **Portable** — skill format is consumed by Cursor, Cline, Codex too. We write once, ship everywhere.
- **Demo punch line:** *"This is a 200-line skill. Install it from the marketplace tomorrow."*

## Reality check: Hyperframe API

HeyGen does **not** expose a Hyperframe API. All `/v{1,2,3}/hyperframes`, `/scenes`, `/storyboards`, `/templates` endpoints return 404. The `llms.txt` docs index has zero mention.

**Implication:** we render scenes via Avatar IV (`POST /v3/videos`) and assemble the interactive layer client-side in a lightweight HTML player. We pitch this honestly as "Hyperframe-as-Code" — the pattern, built around HeyGen's actual API surface.

## Credit budget (free tier)

| Resource | Free credits | Use |
|----------|--------------|-----|
| Avatar IV renders | 3 | Intro scene + 2 branch scenes |
| Video Agent v2 | 3 | Backup if Avatar IV fails on a scene |
| Image gen | 3 | Branch thumbnails (optional polish) |

**Discipline:** scripts must be locked and human-reviewed before any render call. No iteration on rendered output — too expensive.

## Architecture

```
  USER TYPES: /reporeel github.com/foo/bar
       │
       ▼
  ┌──────────────────────────────────────────────┐
  │  Claude Code session (orchestrator)          │
  │                                              │
  │   Step 1: WebFetch repo README + metadata    │
  │   Step 2: Claude plans 3 scenes → plan.json  │
  │   Step 3: Show plan, ask user "approve?"     │
  │   Step 4: Bash → render-scenes.sh (HeyGen)   │ ──▶ POST /v3/videos × 3
  │   Step 5: Wait for completion notification   │ ◀── poll + download MP4s
  │   Step 6: Write player.html with plan + MP4s │
  │   Step 7: Open player.html in browser        │
  └──────────────────────────────────────────────┘
       │
       ▼
  outputs/<repo>/player.html  (shareable, static)
```

The skill drives everything via Claude's existing tools. The only external dependency is HeyGen's API (via `curl` in a Bash helper).

## Components

### 1. The skill (`skills/reporeel/SKILL.md`)
- Markdown file with YAML frontmatter (`name`, `description`, trigger conditions)
- Body contains the workflow: step-by-step instructions Claude follows during the session
- References the Bash helper scripts and the HTML template
- This is the *only* user-facing distribution artifact — what ships to the marketplace

### 2. Repo fetcher (inline in skill, uses `WebFetch`)
- Fetches `https://api.github.com/repos/{owner}/{repo}` for metadata
- Fetches raw README from `https://raw.githubusercontent.com/{owner}/{repo}/HEAD/README.md`
- Optionally `gh repo view` if `gh` is authenticated (skipped if not — public repos work unauth)
- No separate Node file — Claude does this directly

### 3. Scene planner (inline in skill, uses Claude's own reasoning)
- Claude reads repo metadata + README in-session
- Generates `plan.json`: `{scenes: [{id, title, narration_text (~40 words), cta_label}], avatar_id, voice_id}`
- Writes to `outputs/<repo>/plan.json`
- **Gate:** Claude presents the plan in chat, asks `"Approve? (y / edit / no)"` — saves all 3 render credits if user wants to revise

### 4. HeyGen renderer (`scripts/render-scenes.sh`)
- Bash script invoked once per skill run, takes `plan.json` path as arg
- For each scene:
  - `curl POST https://api.heygen.com/v3/videos` with the scene script
  - Capture `video_id`
  - Poll `GET /v3/videos/{video_id}` every 5s
  - On `status: "completed"`, `curl` the video URL to `outputs/<repo>/scenes/<scene_id>.mp4`
- Caches by checking if MP4 already exists (skip render if present) — critical for not burning credits on re-runs
- Reads `HEYGEN_API_KEY` from `.env` via dotenv-style sourcing
- Avatar: `Abigail_expressive_2024112501` (free tier, professional, neutral)

### 5. Hyperframe player template (`templates/player.html.template`)
- Single static HTML file, vanilla JS, no framework, no build step
- Has placeholders (`{{PLAN_JSON}}`, `{{SCENE_MP4S}}`) the skill fills in via `Write` tool
- Plays intro MP4 on load; at end, shows 3 branch buttons styled like Hyperframe CTAs
- Click branch → fades into that scene MP4 → at end, "← back to start" button
- "Share" button copies permalink to clipboard
- Mobile-responsive

## Demo flow (Demo Day script)

1. **30s setup:** show HeyGen UI's Hyperframe editor — point out it's manual, slow, no API. *"That's the problem."*
2. **15s context:** *"I built it as a Claude Code skill. Watch — I just type a slash command."*
3. **30s live demo:** in a Claude Code session, run `/reporeel https://github.com/anthropics/claude-code`. Show:
   - Claude fetches the repo (5s)
   - Claude prints the 3-scene plan in chat
   - User types `y` to approve
4. **Cut to pre-baked:** *"Renders take ~3 minutes total. Here's one I prepared earlier."* Open the resulting Hyperframe player. Click through all 3 branches.
5. **45s pitch:**
   - *"This is Hyperframe-as-Code."*
   - *"Distribution: Anthropic Skills marketplace. Zero infra cost."*
   - *"Eligible for both tracks — it's a Product (any Claude Code user can install it) and it's an Agent (the skill is a visible orchestration pipeline)."*
   - *"Path to monetization: enterprise tier — bring-your-own HeyGen key + custom avatars/voices for company-branded videos."*

**Pre-baked safety net:** before demo, render 2 example repos (one popular OSS, one fictional SaaS) to guarantee a great showcase even if live render fails.

## Out of scope (YAGNI)

- Authentication / user accounts
- Multi-language output (could be a v2 with Video Translate)
- Custom avatar upload (use pre-built HeyGen avatars)
- Persistent storage / database (everything is files on disk)
- Deployment beyond a `vercel deploy` or Cloudflare Pages drop
- More than 3 branches per Hyperframe
- Video Agent integration (kept as render-backup only)

## Tech stack

- **Orchestration:** Claude Code skill (markdown + frontmatter), invoked via `/reporeel <url>`
- **Repo analysis:** `WebFetch` tool inside the skill — direct, no Node code
- **Scene planning:** Claude's own reasoning during skill execution, no external LLM call
- **HeyGen render:** single Bash helper `scripts/render-scenes.sh` using `curl`
- **Player:** vanilla HTML/JS template, no build step, no framework
- **Storage:** local `outputs/` dir, gitignored
- **Secrets:** `.env` with only `HEYGEN_API_KEY`; `.env.example` checked in
- **No Node server, no npm dependencies, no Anthropic API key**

## Risk register

| Risk | Mitigation |
|------|-----------|
| Avatar IV render fails mid-demo | Pre-bake 2 demo repos; fallback to Video Agent endpoint (3 free) |
| Render takes >60s | Show plan-approval step live, cut to pre-baked for render step |
| GitHub rate limit | Use `gh` CLI (authenticated) if available; cap analysis at one repo per demo |
| Skill doesn't trigger correctly | Test `/reporeel` invocation thoroughly; have a manual fallback (run the workflow step-by-step in chat) |
| Hyperframe API appears suddenly | Pivot trivial: swap player.html for a Hyperframe POST call |
| Judges don't know what a Claude Code skill is | First 15s of demo explains it; emphasize "ships on Anthropic Skills marketplace tomorrow" |

## Success criteria

- [ ] `/reporeel <github-url>` works in a fresh Claude Code session
- [ ] Repo metadata + scene plan generated in <15s
- [ ] User-approved plan triggers Avatar IV render via Bash helper (~3 min for 3 scenes)
- [ ] Output: `outputs/<repo>/player.html` is a self-contained interactive video page
- [ ] Demo runs cleanly with pre-baked fallback
- [ ] Submission emphasizes: skill-as-product + Hyperframe-as-Code framing
