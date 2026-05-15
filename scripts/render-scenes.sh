#!/usr/bin/env bash
# render-scenes.sh — render every scene in plan.json via HeyGen Avatar IV.
# Usage:  ./render-scenes.sh <path-to-plan.json>
# Reads HEYGEN_API_KEY from ../.env. Caches by skipping renders whose MP4 already exists.

set -euo pipefail

PLAN="${1:?usage: render-scenes.sh <plan.json>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env
if [[ -f "$REPO_ROOT/.env" ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$REPO_ROOT/.env" | xargs)
fi
: "${HEYGEN_API_KEY:?HEYGEN_API_KEY missing from .env}"

# Defaults
AVATAR_ID=$(jq -r '.avatar_id' "$REPO_ROOT/reference/default-avatar.json")
VOICE_ID=$(jq -r '.voice_id' "$REPO_ROOT/reference/default-avatar.json")

OUTPUT_DIR="$(dirname "$PLAN")"
SCENES_DIR="$OUTPUT_DIR/scenes"
mkdir -p "$SCENES_DIR"

SCENE_COUNT=$(jq '.scenes | length' "$PLAN")
echo "Rendering $SCENE_COUNT scenes from $PLAN"

for i in $(seq 0 $((SCENE_COUNT - 1))); do
  SCENE_ID=$(jq -r ".scenes[$i].id" "$PLAN")
  NARRATION=$(jq -r ".scenes[$i].narration_text" "$PLAN")
  MP4="$SCENES_DIR/${SCENE_ID}.mp4"

  if [[ -f "$MP4" && -s "$MP4" ]]; then
    echo "  [cache hit] $SCENE_ID -> $MP4"
    continue
  fi

  echo "  [render] $SCENE_ID ..."
  PAYLOAD=$(jq -n \
    --arg avatar "$AVATAR_ID" \
    --arg voice "$VOICE_ID" \
    --arg script "$NARRATION" \
    '{type:"avatar", avatar_id:$avatar, voice_id:$voice, script:$script, aspect_ratio:"16:9", resolution:"720p", output_format:"mp4"}')

  CREATE_RESP=$(curl -s -X POST "https://api.heygen.com/v3/videos" \
    -H "X-Api-Key: $HEYGEN_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

  VIDEO_ID=$(echo "$CREATE_RESP" | jq -r '.data.video_id // empty')
  if [[ -z "$VIDEO_ID" ]]; then
    echo "  [error] create failed: $CREATE_RESP" >&2
    exit 1
  fi
  echo "    video_id=$VIDEO_ID, polling..."

  # Poll up to 5 minutes
  for _ in $(seq 1 60); do
    sleep 5
    STATUS_RESP=$(curl -s "https://api.heygen.com/v3/videos/$VIDEO_ID" -H "X-Api-Key: $HEYGEN_API_KEY")
    STATUS=$(echo "$STATUS_RESP" | jq -r '.data.status // .status // empty')
    echo "    status=$STATUS"
    if [[ "$STATUS" == "completed" || "$STATUS" == "succeeded" ]]; then
      VIDEO_URL=$(echo "$STATUS_RESP" | jq -r '.data.video_url // .data.output_url // empty')
      [[ -n "$VIDEO_URL" ]] || { echo "  [error] no video_url in: $STATUS_RESP" >&2; exit 1; }
      curl -s -L "$VIDEO_URL" -o "$MP4"
      echo "    saved $MP4 ($(stat -c%s "$MP4" 2>/dev/null || wc -c <"$MP4") bytes)"
      break
    elif [[ "$STATUS" == "failed" || "$STATUS" == "error" ]]; then
      echo "  [error] render failed: $STATUS_RESP" >&2
      exit 1
    fi
  done

  if [[ ! -s "$MP4" ]]; then
    echo "  [error] timed out waiting for $SCENE_ID" >&2
    exit 1
  fi
done

echo "All scenes rendered: $SCENES_DIR"
