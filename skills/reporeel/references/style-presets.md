# RepoReel Style Presets

> Inspired by [frontend-slides' STYLE_PRESETS.md](https://github.com/zarazhangrui/frontend-slides). The philosophy: avoid generic "AI slop" by committing to a real, distinctive aesthetic per repo.

## How to use this file

When designing a RepoReel composition for a repo:

1. **Audit the repo's character** — read the README, look at any embedded hero/logo image, follow the homepage link if present, scan the topics/tags. Form a single sentence in your head: *"This project feels like X."*
2. **Pick a preset name from the table below** whose vibe matches. Don't pick by language; pick by tone.
3. **Add `"style": "<preset-id>"` to `plan.json`** so the choice is recorded.
4. **Build the composition using that preset's fonts, palette, and signature elements.** Don't blend; commit.

The **avatar slot stays the same across all presets** (bottom-right, rounded square frame) — that's the RepoReel skill's host identity. Everything else changes per preset.

---

## The presets

| ID | Vibe | When it fits |
|---|---|---|
| `terminal-devtools` | Confident, hacker-y, no-bullshit | CLIs, dev infra, language tooling, command-line apps |
| `editorial-paper` | Calm, thoughtful, premium, written | Documentation projects, books-as-code, essay-driven libraries |
| `cyberpunk-neon` | Loud, energetic, brash, late-night | Games, demos, creative-coding, experimental art tools |
| `swiss-minimal` | Precise, expensive, design-aware | Design systems, typography libraries, UI primitives |
| `warm-handwritten` | Friendly, approachable, indie | Hobby projects, educational tools, kids/learning |
| `ide-dark` | Technical, code-first, "real engineer" | Compilers, runtimes, databases, low-level systems |
| `vintage-editorial` | Literary, serious, archival | Research code, classical algorithms, historical projects |
| `bold-brand-block` | Confident, branded, marketing-ready | Commercial OSS with strong identity, framework-level projects |

---

## 1. `terminal-devtools`

**Vibe:** Hacker-y, no-bullshit, command-line first. Looks like a terminal you respect.

**Layout:** Deep dark stage. Mono headlines. Terminal-style framing on Scene 3.

**Typography (Google Fonts):**
- Display: **JetBrains Mono** (weight 800) — monospace headlines
- Body: **Inter Tight** (weight 400/500) — short, condensed sans
- Code: **JetBrains Mono** (400)

**Colors:**
```css
:root {
  --bg-base: #0b0e14;          /* near-black, hint of blue */
  --bg-glow: rgba(122,196,255,0.10);
  --text: #e6e8ec;
  --text-dim: rgba(230,232,236,0.55);
  --accent: #7fff7c;            /* terminal green */
  --accent-2: #7ac4ff;          /* electric cyan */
  --warn: #ffb454;
}
```

**Signature elements:**
- Scene labels use `$` prefix and lowercase: `$ 01 · what is this`
- Section dividers use ASCII bars (`═══` or `──`)
- Slash command prominently shown
- Accent color is the terminal-green prompt, NOT purple

**Avoid:** purple, soft gradients, serif fonts.

---

## 2. `editorial-paper`

**Vibe:** A printed magazine. Quiet authority. Documentation that respects the reader.

**Layout:** Cream/off-white stage. Large serif headlines. Generous margins. Subtle horizontal rules.

**Typography (Google Fonts):**
- Display: **Bodoni Moda** (700) — classic editorial serif
- Body: **DM Sans** (400/500) — clean modern sans for body
- Eyebrow: **DM Sans** (500) uppercase, wide letter-spacing

**Colors:**
```css
:root {
  --bg-base: #f5f1e8;          /* warm cream paper */
  --bg-edge: #ebe6da;
  --text: #1a1a1a;
  --text-dim: rgba(26,26,26,0.55);
  --accent: #a8392b;            /* terracotta */
  --rule: rgba(26,26,26,0.12);
}
```

**Signature elements:**
- Thin horizontal rules separating sections
- Drop caps optional on Scene 1's first paragraph
- Section numbers in serif italics: *I.*, *II.*, *III.*
- The avatar frame chrome gets a thin sepia border to match the warmth

**Avoid:** neon, mono fonts for body, dark backgrounds.

---

## 3. `cyberpunk-neon`

**Vibe:** 3am hackathon. Tokyo at midnight. Maximum energy.

**Layout:** Pitch-black stage. Big neon callouts. Glitchy text-shadow accents. Halftone-style background dots.

**Typography (Google Fonts):**
- Display: **Syne** (800) — bold contemporary display
- Body: **Space Mono** (400/700)
- Accent: **VT323** (400) — retro terminal/CRT for small text

**Colors:**
```css
:root {
  --bg-base: #050008;          /* pitch black */
  --bg-glow: rgba(255,30,180,0.18);  /* magenta glow */
  --text: #ffffff;
  --text-dim: rgba(255,255,255,0.6);
  --accent: #ff2ad4;            /* hot magenta */
  --accent-2: #00f0ff;          /* electric cyan */
  --accent-3: #f9f871;          /* sulfur yellow */
}
```

**Signature elements:**
- Glow text-shadows: `text-shadow: 0 0 24px var(--accent)`
- Repeating dot pattern background via `background-image: radial-gradient(circle, rgba(255,255,255,0.05) 1px, transparent 1px); background-size: 24px 24px`
- Diagonal stripe accents (CSS `linear-gradient(45deg, transparent 49%, var(--accent) 49% 51%, transparent 51%)`)
- Scene labels in `[ 01 ]` brackets

**Avoid:** soft pastels, serifs, anything muted.

---

## 4. `swiss-minimal`

**Vibe:** Helvetica posters from 1962. Precise, expensive, no decoration.

**Layout:** White stage. Strict grid. Single accent color block per scene. Lots of whitespace.

**Typography (Google Fonts):**
- Display: **Inter Tight** (800) — tight, geometric
- Body: **Inter Tight** (400/500)
- Numbers: **Inter Tight** (700) tabular figures

**Colors:**
```css
:root {
  --bg-base: #ffffff;
  --text: #0a0a0a;
  --text-dim: rgba(10,10,10,0.55);
  --accent: #e63946;            /* signal red */
  --rule: #0a0a0a;
}
```

**Signature elements:**
- One single bold accent block per scene (a red rectangle behind a key word, or a red horizontal bar)
- Section numbers right-aligned, tabular
- 1px black rules between sections
- Avatar frame loses its purple glow; gets a 2px solid black border instead

**Avoid:** glow effects, gradients, rounded oversized chrome.

---

## 5. `warm-handwritten`

**Vibe:** Friend explaining their side project at a coffee shop. Approachable, indie, hand-made.

**Layout:** Off-white paper stage. Handwriting fonts for headlines. Sketched arrows/underlines as decoration.

**Typography (Google Fonts):**
- Display: **Caveat** (700) — rounded handwriting
- Body: **Patrick Hand** (400) or **Nunito** (400/600) — gentle, casual
- Accent: **Shadows Into Light** (400) for callouts

**Colors:**
```css
:root {
  --bg-base: #fdfbf7;          /* paper white */
  --text: #2a2520;             /* warm dark brown, not black */
  --text-dim: rgba(42,37,32,0.55);
  --accent: #d97757;            /* terracotta / clay */
  --accent-2: #6b9080;          /* sage */
  --underline: #d97757;
}
```

**Signature elements:**
- Hand-drawn underline under key words (`border-bottom: 4px solid var(--underline); border-radius: 2px; transform: rotate(-1deg)`)
- Slight rotation on quote blocks (`transform: rotate(-0.5deg)`)
- Pencil-y dividers (`border-top: 2px dashed`)
- Avatar frame gets a slightly imperfect border (rotate 0.5deg, paper texture)

**Avoid:** sharp neon, pixel-precise grids, monospace headlines.

---

## 6. `ide-dark`

**Vibe:** Real engineer's daily driver. JetBrains/VS Code Dracula theme. The font is what builds the brand.

**Layout:** Dark IDE-style background. Code-block forward. Syntax highlighting visible.

**Typography (Google Fonts):**
- Display: **JetBrains Mono** (700) — monospace headlines
- Body: **JetBrains Mono** (400)
- Optional accent: **Fira Code** (500)

**Colors (Dracula-inspired):**
```css
:root {
  --bg-base: #282a36;
  --bg-edge: #21222c;
  --text: #f8f8f2;
  --text-dim: #6272a4;
  --comment: #6272a4;            /* slate-blue, like comments */
  --keyword: #ff79c6;            /* pink */
  --string: #f1fa8c;             /* yellow */
  --func: #50fa7b;               /* green */
  --type: #8be9fd;               /* cyan */
  --accent: #bd93f9;             /* lavender (used sparingly) */
}
```

**Signature elements:**
- Scene 1 looks like a syntax-highlighted code excerpt introducing the project
- Scene 2's pipeline rendered as a stack trace or function-call chain
- Scene 3's terminal uses Dracula colors precisely
- Line numbers in `--text-dim` down the left edge

**Avoid:** light backgrounds, sans-serif fonts, generic purple gradients.

---

## 7. `vintage-editorial`

**Vibe:** Old library. Out-of-print computer science book. Classical, archival, deeply serious.

**Layout:** Sepia-toned paper stage. Classical serif headlines. Wide margins. Page numbers.

**Typography (Google Fonts):**
- Display: **Cormorant Garamond** (700) — elegant classical serif
- Body: **EB Garamond** (400/500) — book-text serif
- Caption: **EB Garamond** (400) italic

**Colors:**
```css
:root {
  --bg-base: #f2ead7;          /* aged paper */
  --bg-edge: #e8dec6;
  --text: #2c1810;             /* deep brown ink */
  --text-dim: rgba(44,24,16,0.55);
  --accent: #8b4513;           /* saddle brown */
  --rule: rgba(44,24,16,0.18);
}
```

**Signature elements:**
- Roman numerals for scene labels: *I.*, *II.*, *III.*
- Drop cap on Scene 1's opening word
- Ornamental flourish dividers (CSS `::after { content: "❦"; }`)
- Page-number-style decoration at the bottom of each scene
- Avatar frame gets a thin sepia border

**Avoid:** modern fonts, bright accents, hard rectangles.

---

## 8. `bold-brand-block`

**Vibe:** A commercial product launch. Confident. Branded. Designed to be screenshotted.

**Layout:** Color slab dominates one half of the stage. Big sans-serif text. One clear focal point per scene.

**Typography (Google Fonts):**
- Display: **Manrope** (800) — bold geometric sans
- Body: **Manrope** (400/500)

**Colors (slab is the dominant accent — pick one):**
```css
/* Default slab — adjust per repo brand if known */
:root {
  --bg-base: #0a0a0a;
  --slab: #ff5722;              /* hot orange */
  --text-on-slab: #0a0a0a;
  --text: #ffffff;
  --text-dim: rgba(255,255,255,0.6);
}
```

**Variations of the slab color** (pick the one closest to the repo's actual brand if it has one):
- `#ff5722` hot orange (default)
- `#0066ff` electric blue
- `#7c3aed` violet (only if NOT the RepoReel default purple)
- `#10b981` emerald
- `#fbbf24` amber
- `#ec4899` pink

**Signature elements:**
- One half of the stage is a solid color slab; content sits ON the slab
- Scene numbers as giant outlined digits in the slab corner
- 4px solid white horizontal accent bars
- Type set very tight (`letter-spacing: -0.04em`)

**Avoid:** rounded chrome everywhere, tepid colors, soft gradients.

---

## The fixed brand constants (don't change, regardless of preset)

These are RepoReel's host-show identity. They persist:

1. **Stage:** 1920 × 1080.
2. **Avatar slot:** bottom-right, 540 × 540, rounded square. *Border/glow color may match the preset's accent.*
3. **Three scenes:** intro / tour / run. Plus a 2s opening title and 1s outro.
4. **Scene labels:** bottom-left. *Style of the label may match the preset's typography.*
5. **A single `__timelines["main"]` GSAP timeline.**
6. **Asset paths:** `assets/intro.mp4`, `assets/tour.mp4`, `assets/run.mp4`.

Within those constants, **everything else changes per preset.** Stage colors, fonts, layout patterns, signature elements, label styling — all preset-specific.

---

## Anti-AI-slop checklist (run before you finalize)

- [ ] Did you pick a preset, or did you default to the previous render's look?
- [ ] Are you using Google Fonts (not system fonts)?
- [ ] Is the accent color matched to the repo's actual character, not a stereotype?
- [ ] Did you avoid the lazy fallback (dark navy + purple — that's RepoReel's "purple gradient on white" equivalent)?
- [ ] Does the layout reflect the preset's signature elements (Swiss has the bold accent block; cyberpunk has glow; editorial has rules; etc.)?
- [ ] If you used multiple presets' elements, did you actually want a blend, or did you wash out the design?

If any answer is "no" or "I don't know" — go back and pick a preset, commit to it.
