---
name: reporeel
description: Use when the user types /reporeel <github-url> or asks to turn a GitHub repo into an interactive video walkthrough. Generates a 3-scene branching HeyGen Avatar IV video deck — "Hyperframe-as-Code." Requires HEYGEN_API_KEY in C:\dev\heygen\.env.
---

# RepoReel — GitHub repo → interactive video walkthrough

You are turning a GitHub repository into a 3-scene interactive video deck rendered by HeyGen Avatar IV and assembled into a static HTML player.

## Inputs

A GitHub URL. Accept any of: `https://github.com/owner/repo`, `github.com/owner/repo`, `owner/repo`.

## Workflow

### Step 1 — Parse and validate the URL

Extract `owner` and `repo` from the input. If you can't, ask the user for clarification.

Set `OUTPUT_DIR = C:\dev\heygen\outputs\<owner>--<repo>`.

### Step 2 — Fetch repo metadata

Use the `WebFetch` tool with the GitHub REST API:

- `https://api.github.com/repos/<owner>/<repo>` — extract: `description`, `language`, `stargazers_count`, `topics`, `default_branch`.
- `https://raw.githubusercontent.com/<owner>/<repo>/<default_branch>/README.md` — full README text. If 404 (no README), proceed with metadata only.

### Step 3 — Plan the 3 scenes

Using the metadata + README you just fetched, produce **exactly 3 scenes** as your own reasoning output (no external LLM call):

1. **`intro`** — "What is this?" — 35–45 words of natural spoken narration covering: what the repo does, who it's for, the standout feature. CTA label: `"Explore"`.
2. **`tour`** — "Tour the code" — 35–45 words covering: top-level structure, the most interesting file or module, what a contributor reads first. CTA label: `"Tour the code"`.
3. **`run`** — "See it run" — 35–45 words covering: install command, one realistic usage example, what success looks like. CTA label: `"See it run"`.

Rules for narration:
- Spoken cadence: short sentences, no jargon dumps, no bullet points, no code syntax read aloud.
- Each ~40 words ≈ 15 seconds of speech.
- Never invent features. If the README is thin, say so naturally ("the repo's still early — here's what's there").

Write the plan to `<OUTPUT_DIR>/plan.json`:

```json
{
  "title": "<owner>/<repo>",
  "description": "<one-line from GitHub>",
  "avatar_id": "Abigail_expressive_2024112501",
  "voice_id": "cef3bc4e0a84424cafcde6f2cf466c97",
  "scenes": [
    {"id": "intro", "title": "What is this?", "narration_text": "...", "cta_label": "Explore"},
    {"id": "tour",  "title": "Tour the code", "narration_text": "...", "cta_label": "Tour the code"},
    {"id": "run",   "title": "See it run",    "narration_text": "...", "cta_label": "See it run"}
  ]
}
```

Use the `Write` tool. Create the directory first if needed (PowerShell: `New-Item -ItemType Directory -Force -Path "<OUTPUT_DIR>"`).

### Step 4 — Approval gate (CRITICAL — saves render credits)

Print the plan in chat using this exact format:

```
RepoReel plan for <owner>/<repo>:

[1] Intro (Explore)
    "<narration_text>"

[2] Tour the code (Tour the code)
    "<narration_text>"

[3] See it run (See it run)
    "<narration_text>"

Approve? Type 'y' to render (3 HeyGen credits), 'edit <n> <new text>' to revise scene n, or 'no' to abort.
```

**Wait for the user's response. Do not call the render helper until the user explicitly approves with 'y'.**

If user replies with `edit <n> <new text>`: update that scene's `narration_text` in `plan.json` via `Edit` tool, re-print the plan, ask again.

If user replies `no`: stop. Leave `plan.json` on disk for later.

### Step 5 — Render the scenes

Once approved, invoke the Bash helper. **On Windows, you must call Git Bash explicitly** — the system `bash` on PATH may resolve to WSL, which lacks `jq`.

Run via the Bash tool:

```bash
"C:/Program Files/Git/bin/bash.exe" C:/dev/heygen/scripts/render-scenes.sh "<OUTPUT_DIR>/plan.json"
```

If that path doesn't exist, fall back to:

```bash
bash C:/dev/heygen/scripts/render-scenes.sh "<OUTPUT_DIR>/plan.json"
```

This call may take ~3 minutes. Tell the user up front: "Rendering 3 scenes via HeyGen Avatar IV — about 3 minutes total. I'll show progress as it streams."

If the command fails, report the error verbatim and stop. Do not retry blindly — credits are finite.

### Step 6 — Generate the player HTML

Read `C:\dev\heygen\templates\player.html` as a string (use the `Read` tool, then capture the entire content). Replace:
- `__TITLE__` → `<owner>/<repo>` (exact substring, no surrounding quotes)
- `__PLAN_JSON__` → the literal JSON contents of `plan.json` (the value, not a string-wrapped version — it must parse as a JS object literal when the browser runs it)

Write the result to `<OUTPUT_DIR>/player.html` via the `Write` tool.

### Step 7 — Deliver

Tell the user:

```
Done. Your interactive video walkthrough:

  <OUTPUT_DIR>\player.html

Scenes rendered: 3 (intro, tour, run)
Open the file in a browser, or drop the entire <OUTPUT_DIR> folder onto Vercel/Netlify/GitHub Pages to share.
```

Offer to open it via PowerShell: `Start-Process "<OUTPUT_DIR>\player.html"`.

## Failure modes

- **GitHub 404** — repo private or doesn't exist. Stop and tell the user.
- **No README** — proceed with metadata only; mention the limitation in chat.
- **Render fails partway** — some MP4s are on disk, some aren't. The script is idempotent — re-run `render-scenes.sh` to retry only the missing ones. Don't replan.
- **Quota exhausted** — `POST /v3/videos` returns an error about credits. Report it and stop. The user must top up or wait for monthly reset.
- **WSL bash used instead of Git Bash** — render script fails with `jq: command not found`. Re-invoke using the full Git Bash path (Step 5).

## Out of scope

- Customizing avatars per repo (always uses the default from `reference/default-avatar.json`)
- Multi-language output
- More than 3 scenes
- Authentication, accounts, persistence beyond local files
