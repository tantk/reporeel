# RepoReel

A Claude Code skill that turns a GitHub repo into an interactive branching video walkthrough — powered by HeyGen Avatar IV.

## Usage

In a Claude Code session:
```
/reporeel https://github.com/owner/repo
```

Claude fetches the repo, drafts a 3-scene plan, asks you to approve, then renders the videos and writes a shareable HTML player.

## Setup

1. Copy `.env.example` to `.env` and add your HeyGen API key.
2. Symlink or copy `skills/reporeel/` into your Claude Code skills directory.

## Architecture

The skill (`skills/reporeel/SKILL.md`) drives everything inside the user's Claude Code session:

1. **WebFetch** repo metadata + README from GitHub
2. Claude plans 3 scenes (intro / tour / run), 35-45 spoken words each
3. **Approval gate** — user reviews narration before any HeyGen render is triggered
4. `scripts/render-scenes.sh` calls **HeyGen Avatar IV** (`POST /v3/videos`) per scene, polls, downloads the MP4. Idempotent: cached scenes are skipped on re-runs.
5. Substitutes scene paths into `templates/player.html` and writes the final interactive player

No backend. No Node. No Anthropic API key. Pure orchestration via Claude's existing tools + a single Bash helper.

## Hyperframe-as-Code

HeyGen's Hyperframes feature is UI-only — no public API. RepoReel renders scenes through Avatar IV and assembles the branching interactive layer client-side in `templates/player.html`. When HeyGen ships a Hyperframe API, we swap the assembly step in ~10 lines.

## Files

| Path | Role |
|------|------|
| `skills/reporeel/SKILL.md` | The product — slash-command workflow |
| `scripts/render-scenes.sh` | HeyGen Avatar IV renderer (cache-aware) |
| `templates/player.html` | Vanilla-JS interactive player |
| `reference/default-avatar.json` | Avatar + voice IDs (Madison Photo Avatar / Ivy voice) |
| `outputs/<owner>--<repo>/` | Per-run plan.json + scenes/ + player.html |
| `docs/superpowers/specs/` | Design spec |
| `docs/superpowers/plans/` | Implementation plan |
| `docs/DEMO.md` | Demo Day script |

Built for the HeyGen Hackathon, May 2026.
