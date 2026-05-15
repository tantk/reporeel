#!/usr/bin/env node
// compose.js — render the Hyperframes composition from plan.json + scene MP4s.
//
// Usage:
//   node compose.js <path-to-plan.json> <path-to-template> > index.html
//
// Reads scene MP4 durations from <plan.json>/../scenes/*.mp4 via ffprobe,
// computes timing slots, and substitutes per-repo content into the template.
//
// Per-scene visual content (optional — falls back to sensible defaults):
//   plan.scenes[0].stats        ⇒ Scene 1 stats panel
//   plan.scenes[1].label        ⇒ Scene 2 eyebrow label
//   plan.scenes[1].steps        ⇒ Scene 2 numbered steps
//   plan.scenes[2].terminal_title ⇒ Scene 3 terminal title bar
//   plan.scenes[2].lines        ⇒ Scene 3 terminal body lines

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const [planPath, templatePath] = process.argv.slice(2);
if (!planPath || !templatePath) {
  console.error('usage: compose.js <plan.json> <template.html>');
  process.exit(1);
}

const plan = JSON.parse(fs.readFileSync(planPath, 'utf8'));
let template = fs.readFileSync(templatePath, 'utf8');
const scenesDir = path.join(path.dirname(planPath), 'scenes');

// --- Probe scene MP4 durations ---
function probeDuration(mp4) {
  const out = execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${mp4}"`, { encoding: 'utf8' });
  return Math.ceil(parseFloat(out.trim())) + 1; // +1s buffer
}
const introDur = probeDuration(path.join(scenesDir, 'intro.mp4'));
const tourDur  = probeDuration(path.join(scenesDir, 'tour.mp4'));
const runDur   = probeDuration(path.join(scenesDir, 'run.mp4'));

const introStart = 2;
const tourStart  = introStart + introDur;
const runStart   = tourStart + tourDur;
const outroStart = runStart + runDur;
const total      = outroStart + 1;
const avatarDur  = outroStart - introStart;

const intro = plan.scenes.find(s => s.id === 'intro') || {};
const tour  = plan.scenes.find(s => s.id === 'tour')  || {};
const run   = plan.scenes.find(s => s.id === 'run')   || {};

// --- Defaults (used when plan.json doesn't provide visual content) ---
const defaultStats = [
  { num: '3',       lbl: 'scenes' },
  { num: '~3 min',  lbl: 'render time' },
  { num: '/reporeel', lbl: 'claude code skill' }
];
const defaultSteps = [
  { name: 'Fetch repo',     desc: 'Claude WebFetches README + GitHub metadata' },
  { name: 'Plan scenes',    desc: 'Claude writes 3 narration scripts in-session' },
  { name: 'Render avatars', desc: 'HeyGen Avatar IV via REST API' },
  { name: 'Assemble',       desc: 'Hyperframes composes the final MP4' }
];
const defaultLines = [
  { prompt: '$', cmd: 'claude' },
  { out: 'Claude Code · ready' },
  { spacer: true },
  { prompt: '>', cmd: '/reporeel ', accent: '__GITHUB_URL_PLACEHOLDER__' },
  { spacer: true },
  { out: '→ Fetching repo metadata...' },
  { out: '→ Planning 3 scenes...' },
  { out: '→ Rendering via HeyGen Avatar IV...' },
  { out: '→ Assembling Hyperframes composition...' },
  { spacer: true },
  { out: '✓ Done. outputs/__OWNER_REPO_FLAT_PLACEHOLDER__/final.mp4', success: true }
];

const stats = (intro.stats && intro.stats.length) ? intro.stats : defaultStats;
const tourLabel = tour.label || 'PIPELINE';
const steps = (tour.steps && tour.steps.length) ? tour.steps : defaultSteps;
const terminalTitle = run.terminal_title || 'claude code · ~/projects';
const lines = (run.lines && run.lines.length) ? run.lines : defaultLines;

// --- Repo metadata ---
const ownerRepo = plan.title || 'repo';
const ownerRepoFlat = ownerRepo.replace(/\//g, '--');
const repoNameFull = ownerRepo.split('/').pop();
const repoName = repoNameFull.length > 28 ? repoNameFull.slice(0, 25) + '...' : repoNameFull;
const githubUrl = `https://github.com/${ownerRepo}`;

// --- HTML helpers ---
function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

// Build stats block (Scene 1)
const statsHtml = stats.map(s =>
  `<div class="stat"><span class="num">${esc(s.num)}</span><span class="lbl">${esc(s.lbl)}</span></div>`
).join('\n            ');

// Build steps block (Scene 2)
const stepsHtml = steps.slice(0, 4).map((s, i) =>
  `<div class="step" id="p${i+1}"><div class="badge">${i+1}</div><div class="body"><div class="name">${esc(s.name)}</div><div class="desc">${esc(s.desc)}</div></div></div>`
).join('\n          ');

// Build steps GSAP animations
const stepsGsap = steps.slice(0, 4).map((_, i) =>
  `      tl.from("#p${i+1}", { opacity: 0, x: -50, duration: 0.5, ease: "power2.out" }, ${tourStart + 0.6 + i * 0.8});`
).join('\n');

// Build terminal lines (Scene 3)
const linesHtml = lines.map(line => {
  if (line.spacer) return `<div style="margin-top: 14px;"></div>`;
  if (line.success) {
    const text = (line.out || '').replace('__OWNER_REPO_FLAT_PLACEHOLDER__', ownerRepoFlat);
    return `<div class="out" style="margin-top: 8px; color: #6fff8a;">${esc(text)}</div>`;
  }
  if (line.prompt) {
    const accentText = (line.accent || '').replace('__GITHUB_URL_PLACEHOLDER__', githubUrl);
    const accentHtml = accentText ? ` <span class="accent">${esc(accentText)}</span>` : '';
    const cmdText = line.cmd || '';
    return `<div><span class="prompt">${esc(line.prompt)}</span> <span class="cmd">${esc(cmdText)}</span>${accentHtml}</div>`;
  }
  if (line.out !== undefined) {
    return `<div class="out">${esc(line.out)}</div>`;
  }
  return '';
}).join('\n            ');

// --- Substitute into template ---
const substitutions = {
  '__TITLE__':            esc(plan.title || 'Repo'),
  '__TAGLINE__':          esc(plan.description || ''),
  '__OWNER_REPO__':       esc(ownerRepo),
  '__OWNER_REPO_FLAT__':  ownerRepoFlat,
  '__REPO_NAME__':        esc(repoName),
  '__GITHUB_URL__':       esc(githubUrl),
  '__TOUR_LABEL__':       esc(tourLabel),
  '__TERMINAL_TITLE__':   esc(terminalTitle),
  '__STATS_HTML__':       statsHtml,
  '__STEPS_HTML__':       stepsHtml,
  '__LINES_HTML__':       linesHtml,
  '__STEPS_GSAP__':       stepsGsap,
  '__INTRO_START__':      String(introStart),
  '__INTRO_DUR__':        String(introDur),
  '__TOUR_START__':       String(tourStart),
  '__TOUR_DUR__':         String(tourDur),
  '__RUN_START__':        String(runStart),
  '__RUN_DUR__':          String(runDur),
  '__OUTRO_START__':      String(outroStart),
  '__TOTAL__':            String(total),
  '__AVATAR_DUR__':       String(avatarDur)
};

for (const [key, val] of Object.entries(substitutions)) {
  template = template.split(key).join(val);
}

process.stdout.write(template);

// Log the timing summary to stderr (so > index.html captures only the HTML)
console.error(`[compose] title='${ownerRepo}' durations: intro=${introDur}s tour=${tourDur}s run=${runDur}s total=${total}s`);
console.error(`[compose] scene content: stats=${stats.length} steps=${steps.length} terminal_lines=${lines.length}`);
