# RepoReel — Demo Day Script

**Total runtime:** ~3 minutes

---

## 0:00 – 0:30 — The problem

**On screen:** HeyGen's Hyperframe editor (web UI)

**Say:**
> "This is HeyGen Hyperframes. Powerful — but slow to author by hand. Every scene, every branch, every CTA gets clicked together manually. And the API doesn't expose Hyperframe creation yet."

---

## 0:30 – 0:45 — The pitch

**On screen:** Claude Code window, blank prompt

**Say:**
> "So we built RepoReel — a Claude Code skill. One slash command. Paste any GitHub URL. The skill does the rest."

---

## 0:45 – 1:30 — Live demo (planning step)

**Action:**
```
/reporeel https://github.com/tj/commander.js
```

**What happens:**
- Claude WebFetches `api.github.com/repos/tj/commander.js` and the raw README
- Claude reasons over the repo and prints a 3-scene plan in chat
- Approval gate: I type `y` to confirm

**Say while it runs:**
> "Claude reads the repo, plans three scenes — intro, code tour, usage demo. Every narration is 35 to 45 words, tuned for spoken cadence. Notice the approval gate — that's deliberate. Renders aren't free, so the agent always shows you the plan first."

---

## 1:30 – 2:30 — Pre-baked output

**Say:**
> "Rendering takes about a minute per scene via HeyGen's Avatar IV. Here's one I prepared earlier."

**Action:** Open `outputs/tj--commander.js/player.html` in browser.

**Demo:**
1. Intro video autoplays — Madison (Photo Avatar) narrates the commander.js elevator pitch
2. At end, 2 branch buttons appear: **Tour the code** and **See it run**
3. Click **Tour the code** — plays the code tour scene
4. Click **← Back to start** — returns to intro
5. Click **See it run** — plays the usage demo scene
6. Click **Copy link** in header — shows the shareable URL

**Say while clicking:**
> "This is a static HTML file. No backend, no auth, no database. Drop the folder on Vercel, Netlify, GitHub Pages, S3 — done. This is what every OSS maintainer, every YC founder, every dev influencer should have for their repo, and now they can have it in five minutes."

---

## 2:30 – 3:00 — The wedge

**Say (rapid-fire, hit each beat):**

> "**Distribution:** Anthropic Skills marketplace. The product is a single markdown file. Zero infrastructure cost on our side. Any Claude Code user installs it tomorrow.
>
> **Both tracks:** It's a Product — users get a video walkthrough in minutes. It's an Agent — Claude orchestrates GitHub, HeyGen, and the assembly layer in a visible pipeline.
>
> **Monetization:** Free tier uses HeyGen's stock Photo Avatars. Enterprise tier: bring-your-own-avatar — companies upload their CEO or their brand mascot, every release gets a branded video. $99 a month, unlimited.
>
> **The bigger wedge:** Today the API doesn't expose Hyperframes — so we built Hyperframe-as-Code, assembling the interactive layer in static HTML. The day HeyGen ships a Hyperframe API, our adapter changes ten lines. Until then, we *are* the Hyperframe API."

---

## Fallback if live demo fails

If `/reporeel` doesn't trigger correctly in front of judges:

1. Say: "I'll skip ahead — Claude planning is just a normal Claude conversation, you've seen that. Let me show you the output instead."
2. Open `outputs/tj--commander.js/player.html` directly
3. Continue from the 1:30 mark

If the pre-baked player fails to load:
- Have `intro.mp4`, `tour.mp4`, `run.mp4` opened in separate browser tabs as a last resort
- Talk through the branching layer verbally

---

## Submission package

- **Repo:** push `C:\dev\heygen` to GitHub (public)
- **Key files to point judges at:**
  - `skills/reporeel/SKILL.md` — the actual product
  - `scripts/render-scenes.sh` — the HeyGen integration
  - `templates/player.html` — the Hyperframe-as-Code player
  - `outputs/tj--commander.js/player.html` — live demo artifact (will need to commit the MP4s for the marketplace link to work, or host them on S3/Vercel)
- **Demo video:** consider screen-recording this whole sequence as a 3-minute Loom and attaching to the submission

---

## Submission writeup (paste into HeyGen's form)

**Project name:** RepoReel — Hyperframe-as-Code

**One-liner:** A Claude Code skill that turns any GitHub URL into an interactive branching video walkthrough, rendered by HeyGen Avatar IV.

**What HeyGen features used:** Avatar IV (`POST /v3/videos`), Photo Avatars (Madison via `GET /v3/avatars/looks?avatar_type=photo_avatar`). The interactive branching layer (a Hyperframe in everything but name) is assembled client-side because Hyperframes lacks a public API.

**Track:** Product Track primary, Agent Track eligible.

**Why both tracks:**
- **Product:** Ships as a single markdown skill on Anthropic's marketplace. Zero infra. Anyone with Claude Code installs and uses it. Path to monetization through enterprise BYO-avatar tier.
- **Agent:** The skill IS a visible orchestration pipeline — Claude wires together WebFetch → reasoning → Bash → HeyGen API → file assembly. The "agent stack" is auditable in the SKILL.md.

**The wedge:** HeyGen's Hyperframe UI doesn't have a public API. We built the same interactive pattern using Avatar IV + a 70-line vanilla HTML player. The day HeyGen ships a Hyperframe API, our adapter is a 10-line swap. Until then, RepoReel *is* the Hyperframe-as-Code layer.
