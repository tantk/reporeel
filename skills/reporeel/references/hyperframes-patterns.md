# Hyperframes Patterns for RepoReel

A compact reference for writing valid Hyperframes compositions per repo. Read this before writing `hyperframes-build/index.html`.

## The fixed brand constraints (don't break these)

These define what makes a "RepoReel video" — they stay the same across all repos:

1. **Stage:** 1920 × 1080. Dark background.
2. **The avatar presenter lives in the bottom-right corner.** 540 × 540 frame at `right: 90px; bottom: 120px`. Rounded corners (36px), soft purple-tinted shadow. Always visible during scenes 1–3, fades out before outro.
3. **There are exactly 3 spoken scenes** corresponding to the 3 narration MP4s: intro / tour / run. Plus a 2s opening title and 1s outro.
4. **Scene labels** appear bottom-left (`01 · What is this?`, `02 · How it works`, `03 · Try it`) — fade in/out briefly when each scene starts.
5. **Asset paths are `assets/intro.mp4`, `assets/tour.mp4`, `assets/run.mp4`.** They get copied there by the build script.
6. **One `__timelines["main"]` GSAP timeline.** Paused. Hyperframes drives it.

Everything else — the "slide" content beside the avatar, colors, typography accents, animations of the slide content — **you design per repo.**

## Required structure

Every composition needs this skeleton. Don't omit any part.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=1920, height=1080" />
    <title>{{repo_name}} — Hyperframes composition</title>
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js"></script>
    <style> /* see CSS conventions */ </style>
  </head>
  <body>
    <div id="root"
         data-composition-id="main"
         data-start="0"
         data-duration="{{TOTAL_SECONDS}}"
         data-width="1920"
         data-height="1080">
      <!-- avatar frame, avatar videos, scene content, labels, outro -->
    </div>
    <script>
      window.__timelines = window.__timelines || {};
      const tl = gsap.timeline({ paused: true });
      /* timeline operations */
      window.__timelines["main"] = tl;
    </script>
  </body>
</html>
```

## Timing math (works for any N scenes)

You have N scenes (typically 3, up to 6). For each scene `i` (0-indexed), probe its MP4 duration with `ffprobe`, round up, add 1–2s buffer. Then walk a running cursor:

```
title_dur   = 2                                 # opening title card
outro_dur   = 1                                 # closing card

cursor = title_dur                              # = 2 (where scene 0 starts)
for each scene i in 0..N-1:
    scene_i.start = cursor
    scene_i.duration = ceil(mp4_duration) + 1   # buffer
    cursor += scene_i.duration

outro_start = cursor
total       = outro_start + outro_dur
avatar_dur  = outro_start - title_dur           # avatar frame visible 2s..outro
```

Always give the slot a duration ≥ the video duration. The avatar slot persists across ALL scenes, not just three — the frame is visible from `title_dur` to `outro_start`.

## Hyperframes data attributes (this is the API)

Every timed element must carry these three attributes and `class="clip"`:

```html
<div class="clip ..."
     data-start="2"        <!-- in seconds, from t=0 -->
     data-duration="19"
     data-track-index="3"  <!-- integer; controls z-ordering -->
></div>
```

Video elements additionally need:

```html
<video class="clip avatar-video"
       src="assets/intro.mp4"
       data-start="2" data-duration="19" data-track-index="5"
       data-has-audio="true"             <!-- this video has audio -->
       data-volume="1"
       preload="auto"
       playsinline></video>
```

## Hard lint rules — break any of these and `npm run check` fails

1. **A `<video>` with `data-start` must NOT be nested inside another element with `data-start`.** Videos are direct children of `#root`. (You can have a non-timed wrapper div for visual chrome, but it must NOT have `data-start`.)
2. **Don't combine `muted` with `data-has-audio="true"` on a `<video>`.** Either it has audio (omit `muted`) or it doesn't (omit `data-has-audio`).
3. **Clips on the same `data-track-index` must not overlap in time.** Use different tracks for overlapping content. We use:
   - Track 0 — background
   - Track 2 — avatar frame chrome
   - Track 3 — title card / scene stages / outro (all are full-stage exclusive moments)
   - Track 4 — scene labels (bottom-left bars)
   - Track 5 — avatar videos
4. **`data-composition-id` is required on the root.** Use `"main"`.
5. **Every fade-out near a clip boundary needs a `tl.set(..., { opacity: 0 }, t)` hard-kill** after the tween, otherwise non-linear seeking may leave stale visibility state.
6. **No `Date.now()`, `Math.random()`, or network fetches** in the JS — must be deterministic.
7. **Use stable `id`s on every animated element** — `#scene-1`, `#title-open`, etc. Studio uses them.

## GSAP timeline conventions

```js
window.__timelines = window.__timelines || {};
const tl = gsap.timeline({ paused: true });

// Always: fade something in, fade out, then a `set` hard-kill at the boundary
tl.from("#scene-1 h2", { opacity: 0, y: 30, duration: 0.6, ease: "power2.out" }, 2.5);
tl.to("#scene-1",       { opacity: 0, duration: 0.4, ease: "power2.in"  }, 20.4);
tl.set("#scene-1",      { opacity: 0 }, 21.0);

window.__timelines["main"] = tl;
```

Stagger handful of children:
```js
tl.from("#scene-2 .step", { opacity: 0, x: -50, stagger: 0.15, duration: 0.5 }, 22.0);
```

## The avatar slot (paste this — don't redesign it)

The avatar frame is one untimed-styled div; the avatar videos are one per scene (so for N=4, write 4 video elements):

```html
<!-- frame chrome -->
<div id="avatar-frame" class="clip avatar-frame"
     data-start="2" data-duration="{{AVATAR_DUR}}" data-track-index="2"></div>

<!-- one <video> per scene; src points to assets/<scene-id>.mp4 -->
<video id="vid-<scene-id-1>" class="clip avatar-video" src="assets/<scene-id-1>.mp4"
       data-start="{{S1_START}}" data-duration="{{S1_DUR}}" data-track-index="5"
       data-has-audio="true" data-volume="1" preload="auto" playsinline></video>
<video id="vid-<scene-id-2>" class="clip avatar-video" src="assets/<scene-id-2>.mp4"
       data-start="{{S2_START}}" data-duration="{{S2_DUR}}" data-track-index="5"
       data-has-audio="true" data-volume="1" preload="auto" playsinline></video>
<!-- ... repeat for each scene in plan.scenes[] ... -->
```

Use the scene IDs from `plan.json` — not hardcoded `intro/tour/run`. Asset paths follow `assets/<scene-id>.mp4`.

And the matching CSS:

```css
.avatar-frame {
  position: absolute;
  right: 90px; bottom: 120px;
  width: 540px; height: 540px;
  border-radius: 36px;
  background: linear-gradient(135deg, #14142a 0%, #0a0a18 100%);  /* fill so empty slot doesn't show through */
  box-shadow:
    0 30px 80px rgba(0,0,0,0.55),
    0 0 0 3px rgba(111,111,255,0.35),
    0 0 60px rgba(111,111,255,0.25);
  inset: auto 90px 120px auto;
  z-index: 4;
  pointer-events: none;
}
.avatar-video {
  position: absolute;
  right: 90px; bottom: 120px;
  width: 540px; height: 540px;
  border-radius: 36px;
  object-fit: cover;
  inset: auto 90px 120px auto;
  z-index: 5;
  overflow: hidden;
}
```

Plus the avatar-frame fade-out at the end:

```js
tl.to("#avatar-frame", { opacity: 0, duration: 0.6, ease: "power2.in" }, {{OUTRO_START}} - 0.8);
```

## The "stage" — where you DO design freely

The stage is the left/upper region where slide content goes (the rest of the canvas after the avatar takes its corner). Suggested positioning:

```css
.stage {
  position: absolute;
  top: 100px; left: 90px;
  right: 700px;            /* leaves room for the 540px avatar + 160px margin */
  bottom: 200px;           /* leaves room for the scene-label bar */
  z-index: 3;
}
```

**Inside the stage, design freely per repo:**
- Scene 1 (intro): a "repo card" introducing the project. Could be a hero headline, an icon/logo, key stats, a tagline, a code-snippet preview, a screenshot mockup, etc.
- Scene 2 (tour): the repo's mental model. Could be a numbered pipeline, an architecture diagram, a file-tree visualization, an API surface, a before/after comparison.
- Scene 3 (run): how a user actually uses the repo. Could be a terminal mock, a code block with syntax highlighting, an animated install graphic, a side-by-side "input vs output."

Choose what *fits the repo*. A graph database doesn't deserve a terminal mock — give it a node graph. A web framework deserves a code block + browser preview. A CLI tool deserves a terminal.

## The style preset — pick one, commit to it

**Don't invent a palette from scratch and don't default to "dark navy + purple."** That's this skill's lazy fallback — the equivalent of frontend-slides' "purple gradient on white" anti-pattern.

Instead: **read [`style-presets.md`](./style-presets.md) and pick one of the 8 presets** based on the repo's character (NOT its language). Each preset specifies:

- Specific Google Fonts (load via `<link rel="stylesheet" href="https://fonts.googleapis.com/css2?...">` in the `<head>`)
- A specific palette as CSS variables
- Signature layout elements (e.g., bold accent block, hand-drawn underline, sepia rules)
- A clear vibe and "when it fits" criteria

Record your choice in `plan.json` as `"style": "<preset-id>"` so the decision is traceable.

### Anti-AI-slop rules (hard rules — break these and the result is generic)

❌ **No system fonts.** No `-apple-system`, no `BlinkMacSystemFont`, no Arial. Every preset uses Google Fonts. Load them.
❌ **No defaulting to dark navy + purple.** That's the most overused AI-design palette and it's our lazy fallback. The only preset that uses purple at all is `ide-dark` (Dracula's lavender, used sparingly).
❌ **No Inter / Roboto for display text.** They're allowed for body in some presets, but never as the headline font.
❌ **No "balanced" pastel palettes.** Pick a dominant color with a sharp accent. Timid, evenly-weighted color is bad design.
❌ **No language → color stereotypes.** PyTorch isn't "Python blue"; it's its own orange-flame brand. Match the project's actual identity (homepage, hero image, README badges), not the language tag.

### Positive direction

✅ **Commit to one preset.** Don't blend three "to be safe" — that washes out the design.
✅ **Use the preset's signature elements.** Swiss-minimal's bold red block; cyberpunk's neon glow; editorial-paper's thin rules. These ARE the design.
✅ **Match accent to the repo's own brand when you can find it.** README hero images, homepage screenshots, social preview cards all carry brand color information. Use it.
✅ **The avatar slot border can absorb the preset's accent color.** That ties the host (RepoReel) to the guest (the repo).

## Layout primitives (use INSIDE your chosen preset)

These are **structural patterns**, not visual styles. Pick the layout that fits the content; the chosen preset's fonts/colors/decorations style it. **Never copy these snippets as-is with their default purple/dark-navy look** — restyle them with the preset's tokens.

### Pattern: Headline + 3 stat tiles (Scene 1 default)

```html
<div id="scene-1" class="clip stage"
     data-start="{{INTRO_START}}" data-duration="{{INTRO_DUR}}" data-track-index="3">
  <div class="repo-card">
    <div class="eyebrow">{{OWNER}}/{{REPO}}</div>
    <h2>{{Display name}}</h2>
    <p class="tagline">{{one-line description}}</p>
    <div class="stats">
      <div class="stat"><span class="num">18.4k</span><span class="lbl">★ stars</span></div>
      <div class="stat"><span class="num">Apache 2.0</span><span class="lbl">license</span></div>
      <div class="stat"><span class="num">TypeScript</span><span class="lbl">language</span></div>
    </div>
  </div>
</div>
```

### Pattern: Numbered steps (Scene 2 for pipelines/architectures)

```html
<div id="scene-2" class="clip stage" data-start="..." data-duration="..." data-track-index="3">
  <div class="pipeline">
    <div class="eyebrow">HOW IT WORKS</div>
    <div class="step" id="s1"><span class="badge">1</span><div><div class="name">...</div><div class="desc">...</div></div></div>
    <div class="step" id="s2"><span class="badge">2</span><div>...</div></div>
    <div class="step" id="s3"><span class="badge">3</span><div>...</div></div>
    <div class="step" id="s4"><span class="badge">4</span><div>...</div></div>
  </div>
</div>
```

Stagger them in:
```js
["#s1","#s2","#s3","#s4"].forEach((id,i) =>
  tl.from(id, { opacity: 0, x: -50, duration: 0.5 }, tour_start + 0.6 + i*0.8)
);
```

### Pattern: Code block (Scene 2 or 3 for "show the API")

```html
<div id="scene-2" class="clip stage" data-start="..." data-duration="..." data-track-index="3">
  <div class="eyebrow">CORE API</div>
  <pre class="code"><span class="comment">// Define a CLI in 4 lines</span>
const { program } = require('commander');
program.option('-v, --verbose');
program.parse();
console.log(program.opts());</pre>
</div>
```

### Pattern: Terminal mock (Scene 3 for "install + run")

```html
<div id="scene-3" class="clip stage" data-start="..." data-duration="..." data-track-index="3">
  <div class="terminal">
    <div class="term-bar"><span class="dot r"></span><span class="dot y"></span><span class="dot g"></span><span class="title">~/projects</span></div>
    <div class="term-body">
      <div><span class="prompt">$</span> <span class="cmd">npm install commander</span></div>
      <div class="out">added 1 package</div>
      <div><span class="prompt">$</span> <span class="cmd">node split.js --first --separator=, "a,b,c"</span></div>
      <div class="out">[ 'a' ]</div>
    </div>
  </div>
</div>
```

### Pattern: Side-by-side comparison (Scene 2 for "before/after")

```html
<div id="scene-2" class="clip stage" data-start="..." data-duration="..." data-track-index="3">
  <div class="compare">
    <div class="col"><div class="eyebrow">Before</div><pre>...</pre></div>
    <div class="divider"></div>
    <div class="col"><div class="eyebrow">After</div><pre>...</pre></div>
  </div>
</div>
```

### Pattern: Annotated graphic (Scene 2 for "system diagram")

```html
<div id="scene-2" class="clip stage" data-start="..." data-duration="..." data-track-index="3">
  <div class="diagram">
    <div class="node" style="top:20%; left:10%">Client</div>
    <div class="arrow" style="top:30%; left:25%; width:30%"></div>
    <div class="node" style="top:20%; left:60%">API</div>
    <!-- etc — design the boxes/lines per repo -->
  </div>
</div>
```

## Render workflow checklist

After writing `hyperframes-build/index.html`:

1. Run `npm run check` (lint + validate + inspect) — `cd hyperframes-build && npm run check`.
   - If you see `video_nested_in_timed_element`: move the video out of the timed wrapper.
   - If you see `overlapping_clips_same_track`: shift one clip's `data-track-index`.
   - If you see `gsap_target_not_found`: an `id` in your timeline doesn't exist in the HTML.
   - If you see contrast warnings during fade-ins: usually false positives, can ignore.
2. Fix any errors. Re-run check.
3. When errors are 0, `npm run render -- -o <OUTPUT_DIR>/final.mp4 -q draft` (the compose-and-render.sh script does this for you).

## When in doubt — DON'T default to the previous render's look

The cardinal sin is defaulting to the same `terminal-devtools`-ish purple/navy look every time because it's safe. If the repo doesn't strongly suggest a visual treatment, **still pick a preset deliberately** based on a single tone signal:

- README written in dense bullets, lots of badges, monospace code → `terminal-devtools` or `ide-dark`
- README written like an essay, long prose paragraphs → `editorial-paper` or `vintage-editorial`
- Repo description has "minimal" / "elegant" / "design" → `swiss-minimal`
- Repo description has "fast" / "modern" / "framework" → `bold-brand-block`
- README has emoji, "fun" language, casual tone → `warm-handwritten`
- README has dark mode screenshots with neon → `cyberpunk-neon`

When you've picked one, **read [`style-presets.md`](./style-presets.md) for that preset's exact fonts and palette** and use them. The whole point is to not look like every other RepoReel video.

## Legacy "When in doubt" (deprecated)

The previous fallback was: *Scene 1 headline + tagline + 3 stat tiles*
- Scene 2: 4 numbered steps
- Scene 3: terminal mock

That's safe, lints clean, and matches the "RepoReel brand" videos already shipped.
