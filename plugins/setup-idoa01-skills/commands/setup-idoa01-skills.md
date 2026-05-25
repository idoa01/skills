---
name: setup-idoa01-skills
description: Sets up an `## Agent skills` block in AGENTS.md/CLAUDE.md/CLAUDE.local.md and `.claude/docs/agents/` so the engineering skills know this repo's issue tracker (GitHub or local markdown), triage label vocabulary, and domain doc layout. Run before first use of `to-issues`, `to-prd`, `triage`, `diagnose`, `tdd`, `improve-codebase-architecture`, or `zoom-out` — or if those skills appear to be missing context about the issue tracker, triage labels, or domain docs.
disable-model-invocation: true
---

# Setup Matt Pocock's Skills

Scaffold the per-repo configuration that the engineering skills assume:

- **Issue tracker** — where issues live (beads by default; local markdown and github is also supported out of the box)
- **Triage labels** — the strings used for the five canonical triage roles
- **Domain docs** — where `CONTEXT.md` and ADRs live, and the consumer rules for reading them

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config` — is this a GitHub repo? Which one?
- `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md` at the repo root — does any of those exist? Is there already an `## Agent skills` section in one of them?
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `docs/adr/` and any `src/*/docs/adr/` directories
- `.claude/docs/agents/` — does this skill's prior output already exist?
- `.claude/scratch/` — sign that a local-markdown issue tracker convention is already in use
- `.beads/` - sign that the beads issue tracker is installed in the repo.

### 2. Present findings and ask

Summarise what's present and what's missing. Then walk the user through the three decisions **one at a time** — present a section, get the user's answer, then move to the next. Don't dump all three at once.

Assume the user does not know what these terms mean. Each section starts with a short explainer (what it is, why these skills need it, what changes if they pick differently). Then show the choices and the default.

**Section A — Issue tracker.**

> Explainer: The "issue tracker" is where issues live for this repo. Skills like `to-issues`, `triage`, `to-prd`, and `qa` read from and write to it — they need to know whether to create a beads epic/task, call `gh issue create`, write a markdown file under `.scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.

Default posture: propose Beads by default, even if you find that this project lives inside git. Otherwise (or if the user prefers), offer:

- **Beads** - issues live in the local beads instance (uses the `bd` CLI)
- **GitHub** — issues live in the repo's GitHub Issues (uses the `gh` CLI)
- **GitLab** — issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **Local markdown** — issues live as files under `.claude/scratch/<feature>/` in this repo (good for solo projects or repos without a remote)
- **Other** (Jira, Linear, etc.) — ask the user to describe the workflow in one paragraph; the skill will record it as freeform prose

If the user selected Beads and you didn't find a `.beads/` directory inside the repo root, suggest installing beads for the user using `bd init ---non-interactive --quiet` - ask the user whether to add `--stealth` to configure the beads repository as invisible to other team members.

**Section B — Triage label vocabulary.**

> Explainer: When the `triage` skill processes an incoming issue, it moves it through a state machine — needs evaluation, waiting on reporter, ready for an AFK agent to pick up, ready for a human, or won't fix. To do that, it needs to apply labels (or the equivalent in your issue tracker) that match strings *you've actually configured*. If your repo already uses different label names (e.g. `bug:triage` instead of `needs-triage`), map them here so the skill applies the right ones instead of creating duplicates.

The five canonical roles:

- `needs-triage` — maintainer needs to evaluate
- `needs-info` — waiting on reporter
- `ready-for-agent` — fully specified, AFK-ready (an agent can pick it up with no human context)
- `ready-for-human` — needs human implementation
- `wontfix` — will not be actioned

Default: each role's string equals its name. Ask the user if they want to override any. If their issue tracker has no existing labels, the defaults are fine.

**Section C — Domain docs.**

> Explainer: Some skills (`improve-codebase-architecture`, `diagnose`, `py-tdd`) read a `CONTEXT.md` file to learn the project's domain language, and `docs/adr/` for past architectural decisions. They need to know whether the repo has one global context or multiple (e.g. a monorepo with separate frontend/backend contexts) so they look in the right place.

Confirm the layout:

- **Single-context** — one `CONTEXT.md` + `docs/adr/` at the repo root. Most repos are this.
- **Multi-context** — `CONTEXT-MAP.md` at the root pointing to per-context `CONTEXT.md` files (typically a monorepo).

### 3. Confirm and edit

Show the user a draft of:

- The `## Agent skills` block to add to whichever of `CLAUDE.local.md` / `CLAUDE.md` / `AGENTS.md` is being edited (see step 4 for selection rules)
- The contents of `.claude/docs/agents/issue-tracker.md`, `.claude/docs/agents/triage-labels.md`, `.claude/docs/agents/domain.md`

Let them edit before writing.

### 4. Write

**Pick the file to edit:**

- If `CLAUDE.local.md` exists, edit it.
- Else if `CLAUDE.md` exists, edit it.
- Else if `AGENTS.md` exists, edit it.
- If none exists, ask the user which one to create — don't pick for them.
- If more than one exists, ask the user which one to edit - don't pick for them.
- If `AGENTS.md` or `CLAUDE.md` exists but `CLAUDE.local.md` doesn't - ask the user if they want to use the existing file or `CLAUDE.local.md`

If an `## Agent skills` block already exists in the chosen file, update its contents in-place rather than appending a duplicate. Don't overwrite user edits to the surrounding sections.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `.claude/docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `.claude/docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout — "single-context" or "multi-context"]. See `.claude/docs/agents/domain.md`.
```

If the issue tracker is **Beads**, expand the `### Issue tracker` section to include mandatory rules immediately after the one-liner, before `### Triage labels`:

```markdown
### Issue tracker

Issues live in Beads; use the `bd` CLI. See `.claude/docs/agents/issue-tracker.md`.

**Mandatory rules — apply in every session, regardless of which skill is running:**

1. **Session start**: Run `bd prime` before doing any issue tracker work. Do not skip this even if the session feels like a continuation.
2. **Before working on an issue**: Claim it in the tracker before writing any code or making any changes.
3. **After completing an issue**: Close it in the tracker immediately. Do not batch closures to the end of a session.
4. **PRD-level issues are epics**: Every PRD-level issue must be created as an epic. Sub-issues must reference their parent epic.
5. **Closing an epic**: Close the parent epic only after every issue under it is closed. Before closing, verify that no child issue is in any non-closed state (ready, in-progress, blocked, or otherwise open). If the state of any child is unclear, display the current child issue states and ask the user for directions before proceeding.
```

Then write the three docs files using the seed templates in this skill folder as a starting point:

- [issue-tracker-github.md](../docs/issue-tracker-github.md) — GitHub issue tracker
- [issue-tracker-gitlab.md](../docs/issue-tracker-gitlab.md) — GitLab issue tracker
- [issue-tracker-local.md](../docs/issue-tracker-local.md) — local-markdown issue tracker
- [triage-labels.md](../docs/triage-labels.md) — label mapping
- [domain.md](../docs/domain.md) — domain doc consumer rules + layout

For "other" issue trackers, write `docs/agents/issue-tracker.md` from scratch using the user's description.

### 5. Done

Tell the user the setup is complete and which engineering skills will now read from these files. Mention they can edit `.claude/docs/agents/*.md` directly later — re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.
