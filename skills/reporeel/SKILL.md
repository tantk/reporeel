---
name: reporeel
description: Use when the user types /reporeel <github-url> or asks to turn a GitHub repo into a narrated video walkthrough. Drives HeyGen Avatar IV for the presenter and Hyperframes for the slide-deck composition, ending in a single shareable MP4. Requires HEYGEN_API_KEY in C:\dev\heygen\.env.
---

# RepoReel — GitHub repo → narrated video walkthrough

You are turning a GitHub repository into a 3-scene narrated video. The presenter is rendered by **HeyGen Avatar IV**; the slide deck around the presenter is composed by **Hyperframes**; the final deliverable is a single MP4 at `outputs/<owner>--<repo>/final.mp4`.

The whole pipeline runs from this skill — no other agent or human in the loop.

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
  "avatar_id": "f20cdc89e0ec4b61bbe453d73019a997",
  "voice_id": "cef3bc4e0a84424cafcde6f2cf466c97",
  "scenes": [
    {"id": "intro", "title": "What is this?", "narration_text": "...", "cta_label": "Explore"},
    {"id": "tour",  "title": "Tour the code", "narration_text": "...", "cta_label": "Tour the code"},
    {"id": "run",   "title": "See it run",    "narration_text": "...", "cta_label": "See it run"}
  ]
}
```

The `avatar_id` and `voice_id` shown above are the defaults (Madison Photo Avatar / Ivy voice). They're also stored in `reference/default-avatar.json` for the render helper. Don't change them per repo — the goal is consistent presenter identity across all RepoReel videos.

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

Approve? Type 'y' to render (3 HeyGen credits + ~90s Hyperframes encode), 'edit <n> <new text>' to revise scene n, or 'no' to abort.
```

**Wait for the user's response. Do not call any render helpers until the user explicitly approves with 'y'.**

If user replies with `edit <n> <new text>`: update that scene's `narration_text` in `plan.json` via `Edit` tool, re-print the plan, ask again.

If user replies `no`: stop. Leave `plan.json` on disk for later.

### Step 5 — Render the avatar scenes (HeyGen Avatar IV)

Once approved, invoke the HeyGen render helper. **On Windows, you must call Git Bash explicitly** — the system `bash` on PATH may resolve to WSL, which lacks `jq`.

Run via the Bash tool:

```bash
"C:/Program Files/Git/bin/bash.exe" C:/dev/heygen/scripts/render-scenes.sh "<OUTPUT_DIR>/plan.json"
```

If that path doesn't exist, fall back to:

```bash
bash C:/dev/heygen/scripts/render-scenes.sh "<OUTPUT_DIR>/plan.json"
```

This call takes ~3 minutes (3 scene renders × ~60s each). Tell the user up front: "Rendering 3 scenes via HeyGen Avatar IV — about 3 minutes total."

The helper is idempotent — it skips any scene whose MP4 is already on disk. If it fails partway, you can re-run it and only missing scenes will hit HeyGen.

If the command fails for any other reason, report the error verbatim and stop. Do not retry blindly — HeyGen credits are real money.

### Step 6 — Compose and render the final video (Hyperframes)

Now invoke the Hyperframes composition + render helper. This step takes the scene MP4s from Step 5, substitutes repo-specific content into `templates/composition.html.template`, and renders the final MP4 via headless Chrome + FFmpeg.

```bash
"C:/Program Files/Git/bin/bash.exe" C:/dev/heygen/scripts/compose-and-render.sh "<OUTPUT_DIR>/plan.json"
```

This takes ~90s for a typical 60–80 second composition. The script:
1. Probes the duration of each scene MP4
2. Computes scene start/end times + buffers
3. Substitutes `__TITLE__`, `__TAGLINE__`, `__OWNER_REPO__`, `__GITHUB_URL__`, and all the timing placeholders into the template
4. Writes the substituted composition to `hyperframes-build/index.html`
5. Copies the scene MP4s into `hyperframes-build/assets/`
6. Runs `npm run render` (which invokes `hyperframes render`)
7. Moves the output to `<OUTPUT_DIR>/final.mp4`

Tell the user: "Composing the final video with Hyperframes — about 90 seconds."

If Hyperframes is missing (`npm: command not found` or template error), tell the user to run `npm install -g hyperframes` and retry.

### Step 7 — Deliver

Tell the user:

```
Done. Your RepoReel video:

  <OUTPUT_DIR>\final.mp4

Avatar (HeyGen Avatar IV) narrates the 3 scenes. Hyperframes composes the slide deck.
Single self-contained MP4 — drop it on YouTube, Twitter/X, a README badge, anywhere.
```

Offer to open it via PowerShell: `Start-Process "<OUTPUT_DIR>\final.mp4"`.

## Failure modes

- **GitHub 404** — repo private or doesn't exist. Stop and tell the user.
- **No README** — proceed with metadata only; mention the limitation in chat.
- **HeyGen render fails partway (Step 5)** — `render-scenes.sh` is idempotent. Re-run it and only missing scenes will hit the API.
- **`MOVIO_PAYMENT_INSUFFICIENT_CREDIT`** — `POST /v3/videos` returns this when the HeyGen account is out of API credits. Report it and stop. The user must top up at app.heygen.com → Billing.
- **`This video avatar does not support Avatar IV video generation`** — the avatar in `reference/default-avatar.json` was removed or isn't Avatar IV-compatible. Pick a new Photo Avatar from `GET /v3/avatars/looks?avatar_type=photo_avatar&ownership=public` and update the reference file.
- **WSL bash used instead of Git Bash (Step 5 or 6)** — script fails with `jq: command not found` or `ffprobe: command not found`. Re-invoke using the full Git Bash path: `"C:/Program Files/Git/bin/bash.exe"`.
- **Hyperframes render fails with `video first frame not decoded`** — usually a transient. Re-run `compose-and-render.sh`; it picks up the already-rendered scenes from cache and only re-runs the Hyperframes encode.
- **Hyperframes lint errors** — composition placeholders weren't all substituted. Check `hyperframes-build/index.html` for leftover `__SOMETHING__` strings and patch the template if needed.

## Out of scope

- Customizing avatars per repo (always uses Madison from `reference/default-avatar.json`)
- Multi-language output (single-language; could be added via HeyGen Video Translate)
- More than 3 scenes
- Authentication, accounts, persistence beyond local files

## Optional: the interactive HTML player

`templates/player.html` is an older deliverable — an interactive branching HTML page that plays the scene MP4s with click-through buttons (the "Hyperframe-as-Code" pattern from before we integrated real Hyperframes). It's still in the repo as a fallback / alternate output, but the canonical deliverable is now the single MP4 at `final.mp4`. If a user explicitly asks for the interactive HTML player, you can produce it by reading `templates/player.html`, substituting `__TITLE__` and `__PLAN_JSON__`, and writing the result to `<OUTPUT_DIR>/player.html`.
