#!/usr/bin/env bash
# compose-and-render.sh — render the Hyperframes composition to final.mp4.
#
# In the Claude-as-designer flow, Claude has already written
# hyperframes-build/index.html using the skill instructions. This script just
# handles the I/O: copy ALL scene MP4s into the assets dir (one per scene
# listed in plan.json — count is flexible), lint the composition, then render.
#
# Usage:
#   ./compose-and-render.sh <path-to-plan.json>
#
# Expects:
#   $OUTPUT_DIR/plan.json                    (plan.scenes[] drives scene iteration)
#   $OUTPUT_DIR/scenes/<scene-id>.mp4        (one per scene in plan.scenes[])
#   hyperframes-build/index.html             (already written by the agent)
#
# Writes:
#   $OUTPUT_DIR/final.mp4                    (the deliverable)
#   hyperframes-build/assets/<scene-id>.mp4  (scene MP4s copied for the renderer)

set -euo pipefail

PLAN="${1:?usage: compose-and-render.sh <plan.json>}"
[[ -f "$PLAN" ]] || { echo "plan.json not found at: $PLAN" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$(dirname "$PLAN")"
SCENES_DIR="$OUTPUT_DIR/scenes"
HF_DIR="$REPO_ROOT/hyperframes-build"

[[ -d "$HF_DIR" ]] || { echo "hyperframes-build not found. Run 'npx hyperframes init hyperframes-build' first." >&2; exit 1; }
[[ -f "$HF_DIR/index.html" ]] || {
  echo "[error] hyperframes-build/index.html not found." >&2
  echo "  The agent should write this file before calling compose-and-render.sh." >&2
  echo "  See skills/reporeel/references/hyperframes-patterns.md for the format." >&2
  exit 1
}

# --- Read scene IDs from plan.json (count is flexible, typically 3-6) ---
SCENE_COUNT=$(jq '.scenes | length' "$PLAN")
[[ "$SCENE_COUNT" -ge 1 ]] || { echo "[error] plan.json has no scenes." >&2; exit 1; }

echo "[compose] $SCENE_COUNT scenes from $(jq -r '.title' "$PLAN")"

# Verify every scene's MP4 exists on disk
for i in $(seq 0 $((SCENE_COUNT - 1))); do
  SCENE_ID=$(jq -r ".scenes[$i].id" "$PLAN")
  [[ -s "$SCENES_DIR/$SCENE_ID.mp4" ]] || {
    echo "[error] missing scene MP4: $SCENES_DIR/$SCENE_ID.mp4 (run render-scenes.sh first)" >&2
    exit 1
  }
done

# --- Copy all scene MP4s into hyperframes-build/assets/ ---
mkdir -p "$HF_DIR/assets"
for i in $(seq 0 $((SCENE_COUNT - 1))); do
  SCENE_ID=$(jq -r ".scenes[$i].id" "$PLAN")
  cp -f "$SCENES_DIR/$SCENE_ID.mp4" "$HF_DIR/assets/$SCENE_ID.mp4"
done
echo "[compose] copied $SCENE_COUNT scene MP4s into $HF_DIR/assets/"

# --- Lint the composition (must pass with 0 errors) ---
echo "[check] validating hyperframes-build/index.html..."
(
  cd "$HF_DIR"
  if ! npm run check 2>&1 | tail -15; then
    echo "" >&2
    echo "[error] composition lint failed. Fix the errors above and re-run." >&2
    echo "  See skills/reporeel/references/hyperframes-patterns.md for the lint rules." >&2
    exit 1
  fi
)

# --- Render via Hyperframes ---
echo "[render] starting Hyperframes render..."
(
  cd "$HF_DIR"
  npm run render -- -o "$OUTPUT_DIR/final.mp4" -q draft
)

echo ""
echo "[done] final video: $OUTPUT_DIR/final.mp4"
ls -la "$OUTPUT_DIR/final.mp4"
