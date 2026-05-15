#!/usr/bin/env bash
# compose-and-render.sh — render the Hyperframes composition to final.mp4.
#
# In the Claude-as-designer flow, Claude has already written
# hyperframes-build/index.html using the skill instructions. This script just
# handles the I/O: copy the scene MP4s into the assets dir, lint the
# composition, then render.
#
# Usage:
#   ./compose-and-render.sh <path-to-plan.json>
#
# Expects:
#   $OUTPUT_DIR/plan.json                 (for locating the output dir)
#   $OUTPUT_DIR/scenes/{intro,tour,run}.mp4   (from render-scenes.sh)
#   hyperframes-build/index.html          (already written by the agent)
#
# Writes:
#   $OUTPUT_DIR/final.mp4                 (the deliverable)
#   hyperframes-build/assets/*.mp4        (scene MP4s copied for the renderer)

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
  echo "  Or use the fallback: copy templates/composition.html.template + run scripts/compose.js" >&2
  exit 1
}
for s in intro tour run; do
  [[ -s "$SCENES_DIR/$s.mp4" ]] || { echo "missing scene MP4: $SCENES_DIR/$s.mp4 (run render-scenes.sh first)" >&2; exit 1; }
done

# --- Copy scene MP4s into hyperframes-build/assets/ ---
mkdir -p "$HF_DIR/assets"
cp -f "$SCENES_DIR/intro.mp4" "$HF_DIR/assets/intro.mp4"
cp -f "$SCENES_DIR/tour.mp4"  "$HF_DIR/assets/tour.mp4"
cp -f "$SCENES_DIR/run.mp4"   "$HF_DIR/assets/run.mp4"

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
echo "[render] starting Hyperframes render (~90s for a 60s composition)..."
(
  cd "$HF_DIR"
  npm run render -- -o "$OUTPUT_DIR/final.mp4" -q draft
)

echo ""
echo "[done] final video: $OUTPUT_DIR/final.mp4"
ls -la "$OUTPUT_DIR/final.mp4"
