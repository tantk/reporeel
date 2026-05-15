---
name: reporeel
description: Use when the user types /reporeel <github-url> or asks to turn a GitHub repo into a narrated video walkthrough. Drives HeyGen Avatar IV (via the official heygen CLI) for the presenter and Hyperframes for the slide-deck composition, ending in a single shareable MP4. Requires the heygen CLI and HEYGEN_API_KEY in C:\dev\heygen\.env.
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

### Step 3 — Plan the 3 scenes (narration + visual content)

Using the metadata + README, produce **exactly 3 scenes**. Each scene has two parts:

- **`narration_text`** — what the avatar SAYS (35–45 words, ~15s spoken)
- **`stats` / `steps` / `lines`** — what the SLIDE shows alongside the avatar

The narration and the slide must reinforce each other. The narration is *about the repo*. The slides should be too — not about RepoReel.

#### Scene specs

1. **`intro` — "What is this?" (slide: repo card with stats panel)**
   - Narration covers: what the repo does, who it's for, the standout feature.
   - Slide gets 1–3 `stats` to display in a row. **Pick meaningful stats, skip junk.**

2. **`tour` — "How it works" (slide: 4 numbered steps showing the repo's architecture or concepts)**
   - Narration covers: the top-level mental model of the repo.
   - Slide gets a `label` (eyebrow text like "ARCHITECTURE", "HOW IT RENDERS", "CORE CONCEPTS") and an array of 3–4 `steps`, each with a `name` and short `desc`.
   - These should be **about the repo's concepts** (e.g., for commander.js: Options → Commands → Action handlers → Help generation), not RepoReel's pipeline.

3. **`run` — "Try it" (slide: terminal showing the repo's install + usage)**
   - Narration covers: install command, one realistic usage example, what success looks like.
   - Slide gets a `terminal_title` (e.g. `~/projects · commander`) and an array of `lines`. Each line is either `{prompt, cmd, accent?}` (a typed command) or `{out}` (output text) or `{spacer: true}` (visual gap).
   - Use commands from the repo's README — `npm install`, `pip install`, `cargo add`, whatever's idiomatic.

#### Stat picking — be smart

For Scene 1's `stats` panel, pick from this menu, **prioritizing values that say something interesting**:

| Stat | Use when… | Skip when… |
|---|---|---|
| `★ stars` | repo has > 100 stars | < 50 stars (looks like a graveyard) |
| `language` | always meaningful | — |
| `license` | non-empty, non-`NOASSERTION` | empty or proprietary |
| `contributors` | > 5 | personal project |
| `latest release` | has tagged releases | no releases |
| `topics` | has GitHub topics | none set |
| `last commit` | very recent (< 30 days) | always |
| `size` | huge (> 10MB) or notably tiny | typical mid-size |

**Hard rule:** never display `0 stars`, `no license`, `0 contributors`, or any other zero/empty value. Drop the stat entirely. Show 1 or 2 instead of padding with garbage. New hackathon repos often have 0 of everything — for those, prefer stats like `language`, `last commit: today`, or even just `created: today`.

#### plan.json shape

Write to `<OUTPUT_DIR>/plan.json`:

```json
{
  "title": "<owner>/<repo>",
  "description": "<one-line from GitHub repo description>",
  "avatar_id": "f20cdc89e0ec4b61bbe453d73019a997",
  "voice_id": "cef3bc4e0a84424cafcde6f2cf466c97",
  "scenes": [
    {
      "id": "intro",
      "title": "What is this?",
      "narration_text": "<35-45 words>",
      "cta_label": "Explore",
      "stats": [
        { "num": "18.4k", "lbl": "★ stars" },
        { "num": "Apache 2.0", "lbl": "license" },
        { "num": "TypeScript", "lbl": "language" }
      ]
    },
    {
      "id": "tour",
      "title": "How it works",
      "narration_text": "<35-45 words>",
      "cta_label": "Tour the code",
      "label": "HOW IT RENDERS",
      "steps": [
        { "name": "HTML composition", "desc": "Plain HTML + data attributes" },
        { "name": "Headless Chrome",  "desc": "Plays the composition deterministically" },
        { "name": "Frame capture",    "desc": "Every frame written via Puppeteer" },
        { "name": "FFmpeg encode",    "desc": "Frames stitched into a final MP4" }
      ]
    },
    {
      "id": "run",
      "title": "Try it",
      "narration_text": "<35-45 words>",
      "cta_label": "See it run",
      "terminal_title": "~/projects",
      "lines": [
        { "prompt": "$", "cmd": "npx hyperframes init my-video" },
        { "out": "Created my-video/" },
        { "spacer": true },
        { "prompt": "$", "cmd": "npm run render" },
        { "out": "→ Compiling composition..." },
        { "out": "→ Capturing frames in headless Chrome..." },
        { "out": "→ Encoding via FFmpeg..." },
        { "spacer": true },
        { "out": "✓ Render complete. renders/my-video.mp4", "success": true }
      ]
    }
  ]
}
```

#### Narration rules
- Spoken cadence: short sentences, no jargon dumps, no bullet points, no code syntax read aloud.
- Each ~40 words ≈ 15 seconds of speech.
- **Never invent features.** If the README is thin, say so naturally ("the repo's still early — here's what's there").

#### Defaults if you can't fill in visual content
- If the README is too thin to pick `stats`, `steps`, or `lines`, leave those fields **out entirely** (don't pass empty arrays). The build script will substitute generic fallback content rather than render junk.

The `avatar_id` and `voice_id` shown above are the defaults (Madison Photo Avatar / Ivy voice). Don't change them per repo — consistent presenter identity is part of the brand.

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

### Step 5 — Render the avatar scenes (HeyGen Avatar IV via the official CLI)

Once approved, invoke the render helper. It calls the official **HeyGen CLI** (`heygen video create --wait` then `heygen video download`) — not raw curl — so we get HeyGen's structured error reporting, auth fallback, and built-in polling.

**On Windows, you must call Git Bash explicitly** — the system `bash` on PATH may resolve to WSL, which lacks `jq`.

```bash
"C:/Program Files/Git/bin/bash.exe" C:/dev/heygen/scripts/render-scenes.sh "<OUTPUT_DIR>/plan.json"
```

If Git Bash isn't installed there, fall back to:

```bash
bash C:/dev/heygen/scripts/render-scenes.sh "<OUTPUT_DIR>/plan.json"
```

This call takes ~3 minutes (3 scene renders × ~60s each). Tell the user up front: "Rendering 3 scenes via HeyGen Avatar IV — about 3 minutes total."

The helper is idempotent — it skips any scene whose MP4 is already on disk. If it fails partway, you can re-run it and only missing scenes will hit HeyGen.

**Prerequisite:** the `heygen` CLI must be on PATH. The script errors with installation instructions if it's missing. Install commands:
- macOS / Linux: `curl -fsSL https://static.heygen.ai/cli/install.sh | bash`
- Windows: download `heygen_<version>_windows_amd64.zip` from https://github.com/heygen-com/heygen-cli/releases and extract `heygen.exe` somewhere on PATH (e.g. `~/.local/bin`).

If the render command fails for any other reason, report the error verbatim and stop. Do not retry blindly — HeyGen credits are real money.

### Step 6 — Design the Hyperframes composition (you write the HTML)

**You are the designer.** Don't fill in a fixed template — author the Hyperframes composition fresh for this repo's content. Different repos should look different. A graph database deserves a node diagram; a CLI deserves a terminal mock; a web framework deserves a code block + browser preview.

**Required reading before you start:** open `C:\dev\heygen\skills\reporeel\references\hyperframes-patterns.md`. It has the fixed brand constraints (avatar in corner, stage dimensions, lint rules), the required structure, timing math, and several patterns you can adapt.

**The fixed parts** (don't redesign these — copy them straight from the patterns doc):
1. Stage size 1920 × 1080, dark background.
2. The avatar frame + 3 narration `<video>` elements in the bottom-right corner.
3. A 2s opening title card, 1s outro card.
4. Scene labels at bottom-left.
5. GSAP timeline registered on `window.__timelines["main"]`.

**The free parts** (design these per repo):
- Scene 1 content (introduces the repo) — headline + stats + tagline, or hero card with logo, or screenshot mockup, etc.
- Scene 2 content (the mental model) — numbered pipeline, API surface, file tree, architecture diagram, before/after, side-by-side, whatever fits the repo.
- Scene 3 content (how to use it) — terminal mock, code snippet, install graphic, animated example, etc.
- Color accents — default purple is fine, but you can theme per-language (JS yellow, Python blue, Rust orange — see patterns doc).
- Typography, spacing, animation style — your call within the brand constraints.

**Workflow inside this step:**

1. Probe the 3 scene MP4 durations (you need them for the timing math):
   ```bash
   for s in intro tour run; do
     ffprobe -v error -show_entries format=duration -of csv=p=0 "<OUTPUT_DIR>/scenes/$s.mp4"
   done
   ```
   Round up each one, add a 1–2s buffer. Then compute `intro_start=2`, `tour_start=2+intro_dur`, `run_start=tour_start+tour_dur`, `outro_start=run_start+run_dur`, `total=outro_start+1`.

2. Read `references/hyperframes-patterns.md` if you haven't.

3. Write a custom composition to `C:\dev\heygen\hyperframes-build\index.html` using the `Write` tool. Use the patterns doc's "Required structure" as the skeleton. Paste the avatar slot block verbatim. Design the 3 scene stages around the repo.

4. Run the lint loop:
   ```bash
   cd C:/dev/heygen/hyperframes-build && npm run check
   ```
   - **0 errors** → proceed to render.
   - **Lint errors** → fix them (most common: video nested in timed element, overlapping clips on same track, missing hard-kill set after fade-out). Re-run check. Loop until clean.

5. Trigger the render via the build script (it copies the scene MP4s into `hyperframes-build/assets/` and runs `npm run render`):
   ```bash
   "C:/Program Files/Git/bin/bash.exe" C:/dev/heygen/scripts/compose-and-render.sh "<OUTPUT_DIR>/plan.json"
   ```

Tell the user up front: "Designing a custom composition for this repo, then rendering — about 2 minutes."

**Fallback:** if you can't confidently design from scratch (very thin README, exotic repo type), copy `templates/composition.html.template` into `hyperframes-build/index.html` and run `scripts/compose.js` to substitute placeholders from `plan.json`. That gives you the previous "fixed-brand" output. Note in the deliver step that you used the fallback template.

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
- **`heygen: command not found`** — the HeyGen CLI isn't installed or isn't on PATH. See Step 5 prerequisites for the install link, then re-run.
- **Hyperframes render fails with `video first frame not decoded`** — usually a transient. Re-run `compose-and-render.sh`; it picks up the already-rendered scenes from cache and only re-runs the Hyperframes encode.
- **Hyperframes lint errors** — composition placeholders weren't all substituted. Check `hyperframes-build/index.html` for leftover `__SOMETHING__` strings and patch the template if needed.

## Out of scope

- Customizing avatars per repo (always uses Madison from `reference/default-avatar.json`)
- Multi-language output (single-language; could be added via HeyGen Video Translate)
- More than 3 scenes
- Redesigning the avatar slot (fixed brand)
- Authentication, accounts, persistence beyond local files

## Alternate outputs

Two legacy deliverables are still in the repo for fallback / alternate use cases:

- **`templates/composition.html.template`** + `scripts/compose.js` — the fixed-brand fallback template. Use it via the "Fallback" path in Step 6 if you can't confidently design from scratch.
- **`templates/player.html`** — an interactive branching HTML page that plays the scene MP4s with click-through buttons (the original "Hyperframe-as-Code" pattern). The canonical deliverable is `final.mp4`, but if a user explicitly asks for the interactive HTML player, you can produce it by reading `templates/player.html`, substituting `__TITLE__` and `__PLAN_JSON__`, and writing the result to `<OUTPUT_DIR>/player.html`.
