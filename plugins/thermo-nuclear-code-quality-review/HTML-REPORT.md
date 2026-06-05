# HTML Report Format

When a thermo-nuclear review should be delivered as a standalone visual artifact (the
user asks for "an HTML report", "a nice page", "something I can open in the browser"),
produce a single self-contained HTML file following this spec.

This document is the **single source of truth** for that format. There is intentionally
no committed example `.html` to drift against — rebuild the page from the scaffold below
each time, swapping only the adaptive content.

---

## 1. What kind of report this is

A self-contained, **dark-themed, single-file HTML page** that presents the review as a
scannable narrative, not a wall of text. Its job is to let a reader grasp the verdict in
five seconds and drill into any finding in one click.

Defining characteristics:

- **Severity-first.** Findings are organized by how urgently they block merge, not by
  rule category. Severity drives the verdict and maps directly onto the skill's
  Approval Bar.
- **Concrete and anchored.** Every finding names `file:line`, shows the actual code, and
  proposes a **behavior-preserving** fix as a current-vs-recommended diff. No generic
  advice.
- **Honest about strengths.** The skill is harsh; acknowledging what the change gets
  right (when it genuinely does) is what keeps the harshness credible.
- **Ambitious.** Surfaces the highest-leverage structural move prominently — the "code
  judo" the skill exists to find — rather than burying it among nits.

It is **review output only**. Generating the report never modifies the code under review.

### The review target

The subject is a **review target**, most commonly a PR but also a local branch diff or
uncommitted working-tree changes. The metadata chrome adapts to what's available — fill
the fields that exist, omit the rest:

| Field | PR | Local branch | Working tree |
| --- | --- | --- | --- |
| target | `PR #238` | `branch: feature/x` | `working tree` |
| base | `base: master` | `base: master` | _(omit)_ |
| diffstat | `+928 / −21` | `+928 / −21` | `+928 / −21` |
| ticket | `EV-116230` | _(if known)_ | _(omit)_ |

Never invent a PR number or a diffstat. If `gh`/`git` can't supply a value, drop the chip.

---

## 2. Output mechanics

- **Location.** Default to the OS temp directory (`$TMPDIR`, falling back to `/tmp`).
  Honor an explicit destination if the user gives one.
- **Filename.** `<target-slug>-thermo-nuclear-review.html` — e.g.
  `pr-238-thermo-nuclear-review.html`, `working-tree-thermo-nuclear-review.html`.
- **After writing.** Open it in the browser (`open` on macOS, `xdg-open` on Linux) and
  **always print the absolute path** so the user can find it regardless of whether the
  open succeeds.
- **CDN trade-off — state it once.** Tailwind, Mermaid, and the web fonts load from CDNs.
  This keeps the file to a single artifact with zero build step, but it means the report
  **needs network access to render** and is not a durable/offline archive. Call this out
  to the user when delivering the file; if they need an offline copy, that's a different
  request (inline the assets).

---

## 3. The scaffold (copy verbatim)

This is the **fixed chrome**: identical on every report. Paste it as-is, then fill the
body sections per §4–§6. The theme tokens, font stack, and Mermaid init must not drift —
that consistency is the whole point of having one documented format.

```html
<!doctype html>
<html lang="en" class="dark">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Thermo-Nuclear Code Quality Review — {{TARGET}}</title>
<script src="https://cdn.tailwindcss.com"></script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
<script>
  tailwind.config = {
    darkMode: 'class',
    theme: {
      extend: {
        fontFamily: {
          sans: ['Inter', 'ui-sans-serif', 'system-ui'],
          mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
        },
      },
    },
  };
</script>
<style>
  html { scroll-behavior: smooth; }
  body { font-feature-settings: "cv02","cv03","cv04","cv11"; }
  .prose-code { font-family: 'JetBrains Mono', monospace; }
  pre code { font-family: 'JetBrains Mono', monospace; font-size: 0.82rem; line-height: 1.55; }
  .anchor-pad { scroll-margin-top: 5.5rem; }
  ::selection { background: #6366f1; color: #fff; }
  .mermaid { background: transparent; }
  pre::-webkit-scrollbar { height: 8px; }
  pre::-webkit-scrollbar-thumb { background: #334155; border-radius: 8px; }
</style>
</head>
<body class="bg-slate-950 text-slate-200 font-sans antialiased">

<!-- ░░ Sticky top bar — always present ░░ -->
<header class="sticky top-0 z-30 backdrop-blur bg-slate-950/80 border-b border-slate-800">
  <div class="max-w-6xl mx-auto px-5 py-3 flex items-center justify-between gap-4">
    <div class="flex items-center gap-3 min-w-0">
      <span class="text-2xl leading-none">☢️</span>
      <div class="min-w-0">
        <div class="text-sm font-semibold text-slate-100 truncate">Thermo-Nuclear Code Quality Review</div>
        <div class="text-xs text-slate-400 truncate">{{TARGET}} · {{ONE_LINE_SUBJECT}}</div>
      </div>
    </div>
    <nav class="hidden md:flex items-center gap-1 text-xs">
      <!-- one anchor per section actually rendered -->
      <a href="#verdict" class="px-3 py-1.5 rounded-md hover:bg-slate-800 text-slate-300">Verdict</a>
      <a href="#findings" class="px-3 py-1.5 rounded-md hover:bg-slate-800 text-slate-300">Findings</a>
      <a href="#good" class="px-3 py-1.5 rounded-md hover:bg-slate-800 text-slate-300">What's good</a>
      <a href="#appendix" class="px-3 py-1.5 rounded-md hover:bg-slate-800 text-slate-300">Appendix</a>
    </nav>
  </div>
</header>

<main class="max-w-6xl mx-auto px-5 py-10">
  <!-- ░░ BODY SECTIONS GO HERE — see §4 ░░ -->
</main>

<!-- ░░ Mermaid init — keep even if no diagram is rendered; it's a no-op when absent ░░ -->
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  mermaid.initialize({
    startOnLoad: true,
    theme: 'dark',
    themeVariables: {
      fontFamily: 'Inter, ui-sans-serif, system-ui',
      primaryColor: '#1e293b',
      primaryTextColor: '#e2e8f0',
      primaryBorderColor: '#475569',
      lineColor: '#64748b',
      tertiaryColor: '#0f172a',
    },
    flowchart: { useMaxWidth: true, htmlLabels: true, curve: 'basis' },
  });
</script>
</body>
</html>
```

### Design tokens (don't reinvent)

| Role | Tailwind classes |
| --- | --- |
| Page background / body text | `bg-slate-950` / `text-slate-200` |
| Cards / panels | `bg-slate-900 ring-1 ring-slate-800` |
| Accent (section markers, selection) | `indigo-400` / `#6366f1` |
| Section heading marker | `<span class="text-indigo-400">§</span>` |
| Body font | Inter (`font-sans`) |
| Code font | JetBrains Mono (`prose-code`, `pre code`) |

**Severity palette** — the same hue means the same severity on every report:

| Severity | Hue | Badge classes |
| --- | --- | --- |
| 🔴 Blocker | rose | `bg-rose-500/15 text-rose-300 ring-1 ring-rose-500/40` |
| 🟠 High | amber | `bg-amber-500/15 text-amber-300 ring-1 ring-amber-500/40` |
| 🔵 Medium | sky | `bg-sky-500/15 text-sky-300 ring-1 ring-sky-500/40` |
| ⚪ Low / Nit | slate | `bg-slate-600/30 text-slate-300 ring-1 ring-slate-600` |
| ✅ Strength (in "What's good") | emerald | `bg-emerald-500/5 ring-1 ring-emerald-500/25` |

Code-diff line coloring inside `<pre>`: removed/problem lines `text-rose-400`, the
recommended/fixed lines `text-emerald-400`, comments `text-slate-500`.

---

## 4. Body sections

Render these inside `<main>`. Give each an `id` and `class="anchor-pad"` so the sticky-nav
anchors land correctly. **Only add a nav link for sections you actually render.**

### Always present

| # | Section | `id` | Purpose |
| --- | --- | --- | --- |
| 1 | **Hero** | `hero` | Status pill (Approve / Request changes / Comment) + metadata chips + title + a 2–4 sentence framing of the change: what it does well and what the review will push on. |
| 2 | **Verdict scoreboard** | `verdict` | Four count tiles (Blocker / High / Medium / Low). Honest counts — zeros are fine. |
| 3 | **Findings** | `findings` | The severity-prioritized cards. See §5. This is the body of the report. |
| 4 | **Appendix** | `appendix` | File-size check table (the 1k-line rule), the capability/architecture-as-designed note if relevant, and the **Approval-bar checklist** (§6) with ✅/⚠️/❌ against each bar item. |

### Conditional — render only when the trigger is met

| Section | `id` | Render when… | If not met |
| --- | --- | --- | --- |
| **"The one move that fixes the most"** callout | inside `verdict` | One fix has clearly outsized leverage (resolves a blocker and/or makes several other findings disappear). | Omit. Don't manufacture leverage that isn't there. |
| **Mermaid diagram** | `flow` | A finding is fundamentally about **control flow, ordering, state transitions, or architecture** that a picture clarifies faster than prose (e.g. "the raise escapes the timed block"). | Omit. A diagram of nothing is filler — never add one just to have one. |
| **"What this gets right"** | `good` | The change has **genuine** strengths worth naming (sound design, good tests, strong docs). | Omit. Forced praise erodes the skill's credibility. |

The "one move" callout is the report's signature. When present, style it as a
gradient-ringed panel and state the fix in one sentence plus *why it's high-leverage*
(e.g. "this single relocation makes four separate edits in the PR correct at once").

---

## 5. The finding card

Findings are organized by **severity** (the spine). Each card also carries a **category
tag** drawn from the skill's seven output categories, and `file:line` chips. Within a
severity tier, order cards by the SKILL.md category priority (structural regressions →
missed code-judo → spaghetti/branching → boundary/type → file-size → modularity →
legibility).

Group low-value items into a single **"Low / nits"** card as a bulleted list — never spend
a full card on a rename. Prefer a small number of high-conviction cards over a long list
of cosmetic notes.

Each substantive card contains, in order:

1. **Header bar** — severity badge + a one-line title (may include inline `<code>`).
2. **Anchor chips** — `file:line` references as monospace pills.
3. **The problem** — what's wrong and *why it matters* structurally (not just "it's ugly").
   Cross-reference other findings it interacts with.
4. **Current code** — a `<pre>` block, problem lines in `text-rose-400`.
5. **Recommended code** — a `<pre>` block in an emerald-ringed panel, fix lines in
   `text-emerald-400`, with a one-line note on what the fix deletes/simplifies.
6. **Uncertainty note** (when applicable) — if the fix depends on intent you couldn't
   verify, say so and suggest confirming with the author. Never present a guess as fact.

### Reusable component snippets

**Severity badge** (swap hue per §3 palette):

```html
<span class="inline-flex items-center rounded-md bg-rose-500/15 text-rose-300 ring-1 ring-rose-500/40 px-2.5 py-1 text-xs font-bold tracking-wide">BLOCKER</span>
```

**Scoreboard tile:**

```html
<div class="rounded-xl bg-slate-900 ring-1 ring-slate-800 p-4">
  <div class="text-3xl font-extrabold text-rose-400">{{N}}</div>
  <div class="text-xs text-slate-400 mt-1">{{one-line description}}</div>
</div>
```

**Finding card skeleton:**

```html
<article class="anchor-pad mb-8 rounded-2xl bg-slate-900 ring-1 ring-slate-800 overflow-hidden">
  <div class="px-5 py-4 border-b border-slate-800 flex flex-wrap items-center gap-3">
    <span class="inline-flex items-center rounded-md bg-rose-500/15 text-rose-300 ring-1 ring-rose-500/40 px-2.5 py-1 text-xs font-bold tracking-wide">BLOCKER</span>
    <h3 class="font-semibold text-white">{{N}} · {{title}}</h3>
  </div>
  <div class="px-5 py-5 space-y-4 text-sm leading-relaxed text-slate-300">
    <div class="flex flex-wrap gap-2 text-xs">
      <span class="font-mono bg-slate-800 rounded px-2 py-1 text-slate-300">{{file:line}}</span>
    </div>
    <p>{{the problem and why it matters}}</p>
    <div class="rounded-lg bg-slate-950 ring-1 ring-slate-800 p-4">
      <div class="text-xs uppercase tracking-wider text-slate-500 mb-2">Current</div>
      <pre class="overflow-x-auto"><code>{{current code, problems in text-rose-400}}</code></pre>
    </div>
    <div class="rounded-lg bg-slate-950 ring-1 ring-emerald-800/40 p-4">
      <div class="text-xs uppercase tracking-wider text-emerald-500/80 mb-2">Recommended</div>
      <pre class="overflow-x-auto"><code>{{fixed code, fixes in text-emerald-400}}</code></pre>
      <p class="text-xs text-slate-400 mt-3">{{what this deletes / simplifies}}</p>
    </div>
  </div>
</article>
```

**Mermaid block** (conditional section):

```html
<div class="rounded-2xl bg-slate-900 ring-1 ring-slate-800 p-4 sm:p-6 overflow-x-auto">
  <pre class="mermaid">
flowchart TD
    A([start]) --> B[...]
    classDef bad fill:#4c0519,stroke:#fb7185,color:#fecdd3;
    classDef good fill:#052e16,stroke:#34d399,color:#d1fae5;
  </pre>
</div>
```

Use `classDef bad` (rose) / `good` (emerald) to keep diagram semantics aligned with the
severity palette. Escape HTML entities in code blocks (`&lt;` `&gt;` `&amp;`).

---

## 6. Verdict and the Approval-bar checklist

The hero status pill is one of: **Approve**, **Comment**, **Request changes**. Derive it
from severity, consistent with the SKILL.md Approval Bar:

- Any **Blocker** or unresolved **High** → **Request changes**.
- Only **Medium/Low** → **Comment** (or Approve-with-nits if trivial).
- Clean → **Approve**.

The appendix ends with the Approval-bar checklist — render each SKILL.md bar item with a
status glyph and a one-line justification tied to a finding:

- ✅ met · ⚠️ partially / with caveats · ❌ failed
- Bar items: no structural regression · no missed dramatic simplification · no
  unjustified file-size explosion · no spaghetti-growth branching · no hacky/magical
  abstraction · no unnecessary wrapper/cast/optionality churn · no boundary leak or
  canonical-helper duplication · no missed obvious decomposition.

---

## 7. Tone (inherits SKILL.md)

Direct, serious, demanding — never rude. The HTML's visual polish does not soften the
content: name structural problems plainly, push hard for the simpler reframing, and don't
rubber-stamp working-but-messy code. The format exists to make a rigorous review *legible*,
not to make a lenient one *look* rigorous.
