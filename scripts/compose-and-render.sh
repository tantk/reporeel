#!/usr/bin/env bash
# compose-and-render.sh — given plan.json + scene MP4s, build the Hyperframes
# composition (with per-repo dynamic content from plan.json) and render final.mp4.
#
# Usage: ./compose-and-render.sh <path-to-plan.json>
#
# Expects:
#   $OUTPUT_DIR/plan.json            (with scenes[].stats / .steps / .lines)
#   $OUTPUT_DIR/scenes/{intro,tour,run}.mp4
#
# Writes:
#   $OUTPUT_DIR/final.mp4            (the deliverable)
#   hyperframes-build/index.html     (substituted composition, in place)
#   hyperframes-build/assets/*.mp4   (scene MP4s copied for the renderer)

set -euo pipefail

PLAN="${1:?usage: compose-and-render.sh <plan.json>}"
[[ -f "$PLAN" ]] || { echo "plan.json not found at: $PLAN" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$(dirname "$PLAN")"
SCENES_DIR="$OUTPUT_DIR/scenes"
HF_DIR="$REPO_ROOT/hyperframes-build"
TEMPLATE="$REPO_ROOT/templates/composition.html.template"

[[ -d "$HF_DIR" ]] || { echo "hyperframes-build not found. Run 'npx hyperframes init hyperframes-build' first." >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "Template missing at $TEMPLATE" >&2; exit 1; }
for s in intro tour run; do
  [[ -s "$SCENES_DIR/$s.mp4" ]] || { echo "missing scene MP4: $SCENES_DIR/$s.mp4 (run render-scenes.sh first)" >&2; exit 1; }
done

# --- Copy scene MP4s into hyperframes-build/assets/ ---
mkdir -p "$HF_DIR/assets"
cp -f "$SCENES_DIR/intro.mp4" "$HF_DIR/assets/intro.mp4"
cp -f "$SCENES_DIR/tour.mp4"  "$HF_DIR/assets/tour.mp4"
cp -f "$SCENES_DIR/run.mp4"   "$HF_DIR/assets/run.mp4"

# --- Build the composition HTML via the Node templating script ---
# (compose.js writes the HTML to stdout, timing summary to stderr)
echo "[compose] generating composition for $(jq -r '.title' "$PLAN")..."
node "$REPO_ROOT/scripts/compose.js" "$PLAN" "$TEMPLATE" > "$HF_DIR/index.html"

# --- Render via Hyperframes ---
echo "[render] starting Hyperframes render (~90s for a 60s composition)..."
(
  cd "$HF_DIR"
  npm run render -- -o "$OUTPUT_DIR/final.mp4" -q draft
)

echo ""
echo "[done] final video: $OUTPUT_DIR/final.mp4"
ls -la "$OUTPUT_DIR/final.mp4"
