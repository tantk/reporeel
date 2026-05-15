#!/usr/bin/env bash
# render-scenes.sh — render every scene in plan.json via HeyGen Avatar IV.
#
# Uses the official HeyGen CLI (https://github.com/heygen-com/heygen-cli)
# instead of raw curl, so we get: auth fallback (env var or saved credentials
# or MCP), structured error reporting, and built-in --wait polling.
#
# Usage:
#   ./render-scenes.sh <path-to-plan.json>
#
# Reads HEYGEN_API_KEY from ../.env. Caches by skipping renders whose MP4
# already exists on disk.

set -euo pipefail

PLAN="${1:?usage: render-scenes.sh <plan.json>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env so HEYGEN_API_KEY is in the environment for the CLI
if [[ -f "$REPO_ROOT/.env" ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$REPO_ROOT/.env" | xargs)
fi
: "${HEYGEN_API_KEY:?HEYGEN_API_KEY missing from .env}"

# Verify the heygen CLI is on PATH (the agent skill installs it; see INSTALL.md)
command -v heygen >/dev/null 2>&1 || {
  echo "[error] 'heygen' CLI not on PATH." >&2
  echo "  Install: curl -fsSL https://static.heygen.ai/cli/install.sh | bash" >&2
  echo "  Or download a Windows zip from https://github.com/heygen-com/heygen-cli/releases" >&2
  exit 1
}

# Avatar + voice from reference/default-avatar.json (Madison Photo Avatar / Ivy voice)
AVATAR_ID=$(jq -r '.avatar_id' "$REPO_ROOT/reference/default-avatar.json")
VOICE_ID=$(jq -r '.voice_id' "$REPO_ROOT/reference/default-avatar.json")

OUTPUT_DIR="$(dirname "$PLAN")"
SCENES_DIR="$OUTPUT_DIR/scenes"
mkdir -p "$SCENES_DIR"

SCENE_COUNT=$(jq '.scenes | length' "$PLAN")
echo "Rendering $SCENE_COUNT scenes from $PLAN (via heygen CLI $(heygen --version | awk '{print $NF}'))"

for i in $(seq 0 $((SCENE_COUNT - 1))); do
  SCENE_ID=$(jq -r ".scenes[$i].id" "$PLAN")
  NARRATION=$(jq -r ".scenes[$i].narration_text" "$PLAN")
  MP4="$SCENES_DIR/${SCENE_ID}.mp4"

  if [[ -f "$MP4" && -s "$MP4" ]]; then
    echo "  [cache hit] $SCENE_ID -> $MP4"
    continue
  fi

  echo "  [render] $SCENE_ID via heygen video create --wait ..."

  # Build the request payload (Avatar IV defaults — engine omitted = avatar_iv)
  PAYLOAD=$(jq -n \
    --arg avatar "$AVATAR_ID" \
    --arg voice "$VOICE_ID" \
    --arg script "$NARRATION" \
    '{type:"avatar", avatar_id:$avatar, voice_id:$voice, script:$script, aspect_ratio:"16:9", resolution:"720p", output_format:"mp4"}')

  # `heygen video create --wait` blocks until the video is ready.
  # On success, stdout is JSON: {"data":{"video_id":"...","status":"completed",...}}
  CREATE_OUT=$(heygen video create -d "$PAYLOAD" --wait)
  VIDEO_ID=$(echo "$CREATE_OUT" | jq -r '.data.video_id // empty')
  STATUS=$(echo "$CREATE_OUT" | jq -r '.data.status // empty')

  if [[ -z "$VIDEO_ID" ]]; then
    echo "  [error] no video_id in CLI response:" >&2
    echo "$CREATE_OUT" >&2
    exit 1
  fi

  if [[ "$STATUS" != "completed" && "$STATUS" != "succeeded" ]]; then
    echo "  [error] render did not complete (status=$STATUS):" >&2
    echo "$CREATE_OUT" >&2
    exit 1
  fi

  echo "    completed: video_id=$VIDEO_ID — downloading..."

  # Download into the scenes dir
  heygen video download "$VIDEO_ID" --output-path "$MP4" --force >/dev/null

  if [[ ! -s "$MP4" ]]; then
    echo "  [error] download produced empty/missing file at $MP4" >&2
    exit 1
  fi

  SIZE=$(stat -c%s "$MP4" 2>/dev/null || wc -c <"$MP4")
  echo "    saved $MP4 ($SIZE bytes)"
done

echo "All scenes rendered: $SCENES_DIR"
