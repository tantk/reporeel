#!/usr/bin/env bash
# compose-and-render.sh — given plan.json + scene MP4s, build the Hyperframes
# composition with dynamic per-repo content and timings, then render final.mp4.
#
# Usage: ./compose-and-render.sh <path-to-plan.json>
#
# Expects:
#   $OUTPUT_DIR/plan.json           (from /reporeel planning step)
#   $OUTPUT_DIR/scenes/{intro,tour,run}.mp4  (from render-scenes.sh)
#
# Writes:
#   $OUTPUT_DIR/final.mp4           (the deliverable)
#   hyperframes-build/index.html    (the substituted composition, in place)
#   hyperframes-build/assets/*.mp4  (scene MP4s copied for the renderer)

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

# --- Read repo metadata from plan.json ---
TITLE=$(jq -r '.title // "Repo"' "$PLAN")             # e.g. "owner/repo"
DESCRIPTION=$(jq -r '.description // ""' "$PLAN")
# Owner/repo split. If title isn't a slash-form, fall back to the whole title.
if [[ "$TITLE" == */* ]]; then
  OWNER_REPO="$TITLE"
  REPO_NAME="${TITLE##*/}"
else
  OWNER_REPO="$TITLE"
  REPO_NAME="$TITLE"
fi
OWNER_REPO_FLAT="$(echo "$OWNER_REPO" | sed 's|/|--|g')"

# Slash-command URL to show in the terminal scene
GITHUB_URL="https://github.com/$OWNER_REPO"

# Fall back to a short repo name if the full title is too long for the giant headline
if [[ ${#REPO_NAME} -gt 28 ]]; then REPO_NAME="${REPO_NAME:0:25}..."; fi

# --- Probe scene MP4 durations + compute slot timings ---
probe_duration() {
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" \
    | awk '{print int($1)+2}'   # ceil + 1s buffer
}

INTRO_DUR=$(probe_duration "$SCENES_DIR/intro.mp4")
TOUR_DUR=$(probe_duration "$SCENES_DIR/tour.mp4")
RUN_DUR=$(probe_duration "$SCENES_DIR/run.mp4")

# Title card: 2s. Then 3 scene slots. Then 1s outro.
INTRO_START=2
TOUR_START=$((INTRO_START + INTRO_DUR))
RUN_START=$((TOUR_START + TOUR_DUR))
OUTRO_START=$((RUN_START + RUN_DUR))
TOTAL=$((OUTRO_START + 1))
AVATAR_DUR=$((OUTRO_START - INTRO_START))  # avatar frame visible from 2 to outro

echo "[compose] title='$TITLE'  durations: intro=${INTRO_DUR}s tour=${TOUR_DUR}s run=${RUN_DUR}s  total=${TOTAL}s"

# --- Copy scene MP4s into hyperframes-build/assets/ ---
mkdir -p "$HF_DIR/assets"
cp -f "$SCENES_DIR/intro.mp4" "$HF_DIR/assets/intro.mp4"
cp -f "$SCENES_DIR/tour.mp4"  "$HF_DIR/assets/tour.mp4"
cp -f "$SCENES_DIR/run.mp4"   "$HF_DIR/assets/run.mp4"

# --- Substitute placeholders into the composition ---
# sed escape for description / tagline (may contain & and special chars)
sed_escape() { printf '%s' "$1" | sed -e 's/[&\\/|]/\\&/g'; }

DESC_ESC=$(sed_escape "$DESCRIPTION")
TITLE_ESC=$(sed_escape "$TITLE")
OWNER_REPO_ESC=$(sed_escape "$OWNER_REPO")
REPO_NAME_ESC=$(sed_escape "$REPO_NAME")
GITHUB_URL_ESC=$(sed_escape "$GITHUB_URL")

sed \
  -e "s|__TITLE__|$TITLE_ESC|g" \
  -e "s|__TAGLINE__|$DESC_ESC|g" \
  -e "s|__OWNER_REPO__|$OWNER_REPO_ESC|g" \
  -e "s|__OWNER_REPO_FLAT__|$OWNER_REPO_FLAT|g" \
  -e "s|__REPO_NAME__|$REPO_NAME_ESC|g" \
  -e "s|__GITHUB_URL__|$GITHUB_URL_ESC|g" \
  -e "s|__INTRO_START__|$INTRO_START|g" \
  -e "s|__INTRO_DUR__|$INTRO_DUR|g" \
  -e "s|__TOUR_START__|$TOUR_START|g" \
  -e "s|__TOUR_DUR__|$TOUR_DUR|g" \
  -e "s|__RUN_START__|$RUN_START|g" \
  -e "s|__RUN_DUR__|$RUN_DUR|g" \
  -e "s|__OUTRO_START__|$OUTRO_START|g" \
  -e "s|__TOTAL__|$TOTAL|g" \
  -e "s|__AVATAR_DUR__|$AVATAR_DUR|g" \
  "$TEMPLATE" > "$HF_DIR/index.html"

echo "[compose] composition written: $HF_DIR/index.html"

# --- Render via Hyperframes ---
echo "[render] starting Hyperframes render (~90s for a 60s composition)..."
(
  cd "$HF_DIR"
  npm run render -- -o "$OUTPUT_DIR/final.mp4" -q draft
)

echo ""
echo "[done] final video: $OUTPUT_DIR/final.mp4"
ls -la "$OUTPUT_DIR/final.mp4"
