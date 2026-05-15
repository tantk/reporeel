# Installing RepoReel

A 5-minute setup. Paste the commands for your OS.

## Prerequisites

You need:

1. **Claude Code** (CLI or VS Code extension) — https://claude.com/claude-code
2. **HeyGen API key** — https://app.heygen.com → Settings → API → create key. You'll need at least a few credits ($5 top-up is plenty for a couple of test renders).
3. **Node.js ≥ 22** + **FFmpeg** + **jq** + **Git Bash (Windows) or bash (mac/linux)**
4. **HeyGen CLI** ([heygen-com/heygen-cli](https://github.com/heygen-com/heygen-cli)) — the official Go binary that the skill calls for Avatar IV renders

Check you have everything:

```bash
node --version    # >= v22
npm --version
ffmpeg -version | head -1
jq --version
bash --version | head -1
heygen --version  # >= v0.0.10
```

If you're missing any:

- **Windows:** `winget install OpenJS.NodeJS jqlang.jq Gyan.FFmpeg Git.Git`
- **macOS:** `brew install node jq ffmpeg`
- **Linux:** `apt install nodejs npm jq ffmpeg git` (or your distro's equivalent)

### HeyGen CLI install

The skill drives renders through the official HeyGen CLI rather than raw curl. Install it:

- **macOS / Linux / WSL:**
  ```bash
  curl -fsSL https://static.heygen.ai/cli/install.sh | bash
  ```
- **Windows (native):**
  1. Download `heygen_<latest>_windows_amd64.zip` from https://github.com/heygen-com/heygen-cli/releases
  2. Extract `heygen.exe` to `%USERPROFILE%\.local\bin\` (or anywhere on PATH)
  3. Verify: `heygen --version`

## Step 1 — Clone

```bash
git clone https://github.com/tantk/reporeel C:\dev\reporeel
cd C:\dev\reporeel
```

> **Why `C:\dev\reporeel`?** The skill currently expects this path. If you want it elsewhere, also update the path references inside `skills/reporeel/SKILL.md` (search-and-replace `C:\dev\heygen` / `C:/dev/heygen`).

## Step 2 — Configure your HeyGen key

```bash
cp .env.example .env
```

Open `.env` in any editor and replace `sk_V2_replace_me` with your actual HeyGen API key.

```
HEYGEN_API_KEY=sk_V2_yourActualKeyHere
```

## Step 3 — Install Hyperframes (for the final video composition)

```bash
npm install -g hyperframes
```

Or you can use `npx hyperframes` without installing globally — the skill works either way.

## Step 4 — Link the skill into Claude Code

Claude Code loads user skills from `~/.claude/skills/`. Symlink the `reporeel` folder there:

### Windows (PowerShell, as Administrator)

```powershell
New-Item -ItemType SymbolicLink `
  -Path  "$env:USERPROFILE\.claude\skills\reporeel" `
  -Target "C:\dev\reporeel\skills\reporeel"
```

> ℹ️ If you're not Administrator, use a plain copy instead:
> `Copy-Item -Recurse "C:\dev\reporeel\skills\reporeel" "$env:USERPROFILE\.claude\skills\reporeel"`

### macOS / Linux

```bash
mkdir -p ~/.claude/skills
ln -s /path/to/reporeel/skills/reporeel ~/.claude/skills/reporeel
```

## Step 5 — Restart Claude Code

Close and reopen Claude Code (or your terminal session). The skill loader picks up new skills at session start.

## Step 6 — Try it

In a Claude Code session:

```
/reporeel https://github.com/anthropics/claude-code
```

Claude will:
1. Fetch the repo's README + GitHub metadata (~5s)
2. Print a 3-scene narration plan in chat
3. Ask "Approve? (y / edit / no)"

Type `y` and wait ~3 minutes for the renders + composition. The final video lands at `outputs/anthropics--claude-code/final.mp4`.

## Troubleshooting

**`/reporeel` doesn't appear in skill suggestions**
→ Make sure the symlink/copy is at `~/.claude/skills/reporeel/SKILL.md` (not nested deeper). Restart Claude Code.

**`render-scenes.sh: jq: command not found`**
→ You're on Windows and Claude is using WSL `bash` instead of Git Bash. SKILL.md tries Git Bash first (`C:/Program Files/Git/bin/bash.exe`); make sure Git for Windows is installed at the default location.

**`MOVIO_PAYMENT_INSUFFICIENT_CREDIT`**
→ Your HeyGen account has no API credits. Top up at https://app.heygen.com → Billing. Even a $5 top-up gives ~30 scene renders.

**`Avatar not found` or `does not support Avatar IV`**
→ The default Photo Avatar (`f20cdc89e0ec4b61bbe453d73019a997`, "Madison") was retired or your account region doesn't have it. Edit `reference/default-avatar.json` and pick a different ID from:
```bash
curl -H "X-Api-Key: $HEYGEN_API_KEY" \
  "https://api.heygen.com/v3/avatars/looks?avatar_type=photo_avatar&ownership=public&limit=20" \
  | jq '.data[] | {id, name, supported_api_engines}'
```
Any avatar whose `supported_api_engines` includes `"avatar_iv"` will work.

**Hyperframes `render` fails with "video first frame not decoded"**
→ The scene MP4s couldn't be decoded by headless Chrome. Try `npm run check` in `hyperframes-build/` first to validate the composition; re-render the scene MP4s with `render-scenes.sh` (delete the old ones so they re-render fresh).

## Roadmap (post-hackathon)

- [ ] Publish to a skill registry so install becomes `npx skills add tantk/reporeel`
- [ ] Make paths repo-relative (drop the `C:\dev\heygen` hard-codes)
- [ ] Add bring-your-own-avatar config
- [ ] Web hosting helper so the final MP4 + a static landing page deploy to Vercel in one command
