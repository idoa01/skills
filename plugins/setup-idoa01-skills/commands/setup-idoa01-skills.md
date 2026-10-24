---
name: setup-idoa01-skills
description: "Configure this repo for the engineering skills: set up its issue tracker (Beads, GitHub, GitLab, or local markdown), triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills, or when they seem to lack tracker, label, or domain-doc context."
disable-model-invocation: true
---

# Setup idoa01 Skills

Scaffold the per-repo configuration that the engineering skills assume:

- **Issue tracker**: where issues live (beads by default; local markdown, GitHub and GitLab are also supported out of the box)
- **Triage labels**: the strings used for the five canonical triage roles
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the consumer rules for reading them

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config`: is this a GitHub or GitLab repo? Which one?
- `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md` at the repo root: does any of those exist? Is there already an `## Agent skills` section in one of them?
- `GLOSSARY.md` and `GLOSSARY-MAP.md` at the repo root. If the old `CONTEXT.md` / `CONTEXT-MAP.md` exist instead, offer to `git mv` them to the new names; never rename silently.
- `docs/adr/` and any `src/*/docs/adr/` directories
- `.claude/docs/agents/`: does this skill's prior output already exist?
- `.claude/scratch/`: a sign that a local-markdown issue tracker convention is already in use
- `.beads/`: a sign that the beads issue tracker is installed in the repo.
- Is the `triage` skill installed? (a `triage` skill folder alongside this one, or `triage` in your available skills.) This decides whether Section B runs at all.
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. These are present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order. One section, one answer, then the next.

Lead each section with the recommended answer so the user can accept it in a word. Give a one-line explainer only when the choice genuinely branches; skip the section entirely when exploration already settled it (Section B when `triage` isn't installed, Section C when there's no monorepo).

**Section A: Issue tracker.**

> Explainer: The "issue tracker" is where issues live for this repo. Skills like `to-tickets`, `triage`, `to-spec`, and `wayfinder` read from and write to it. They need to know whether to create a beads epic/task, call `gh issue create`, write a markdown file under `.claude/scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.

Default posture: propose Beads, even if this project lives inside git. Otherwise (or if the user prefers), offer:

- **Beads**: issues live in the local beads instance (uses the `bd` CLI)
- **GitHub**: issues live in the repo's GitHub Issues (uses the `gh` CLI)
- **GitLab**: issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **Local markdown**: issues live as files under `.claude/scratch/<feature>/` in this repo (good for solo projects or repos without a remote)
- **Other** (Jira, Linear, etc.): ask the user to describe the workflow in one paragraph; the skill will record it as freeform prose

If the user selected Beads and you didn't find a `.beads/` directory inside the repo root, suggest installing beads for the user using `bd init --non-interactive --quiet`. Ask the user whether to add `--stealth` to configure the beads repository as invisible to other team members.

Record the choice in `.claude/docs/agents/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off**. Leave it off and don't raise it: a user who wants external PRs in the triage queue can flip the flag in the file later.

**Section B: Triage label vocabulary.** Skip this section entirely if the `triage` skill isn't installed (exploration told you), since an uninstalled skill needs no labels.

If it is installed, ask exactly one question:

> Do you want to keep the default triage labels? (recommended: **yes**)

The defaults are the five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them as-is. Only if the user says no, usually because their tracker already uses other names (e.g. `bug:triage` for `needs-triage`), collect the overrides so `triage` applies existing labels instead of creating duplicates.

**Section C: Domain docs.** Default to **single-context** (one `GLOSSARY.md` + `docs/adr/` at the repo root). This fits almost every repo; write it without asking.

Offer **multi-context** (a root `GLOSSARY-MAP.md` pointing to per-context `GLOSSARY.md` files) only when exploration found monorepo signals. Then confirm which layout they want.

> Explainer: Some skills (`improve-codebase-architecture`, `diagnosing-bugs`, `py-tdd`) read a `GLOSSARY.md` file to learn the project's domain language, and `docs/adr/` for past architectural decisions. A monorepo with separate frontend/backend contexts needs one glossary per context so they look in the right place.

### 3. Confirm and edit

Show the user a draft of:

- The `## Agent skills` block to add to whichever of `CLAUDE.local.md` / `CLAUDE.md` / `AGENTS.md` is being edited (see step 4 for selection rules)
- The contents of `.claude/docs/agents/issue-tracker.md`, `.claude/docs/agents/domain.md`, and `.claude/docs/agents/triage-labels.md` (the last only when `triage` is installed)

Let them edit before writing.

### 4. Write

**Pick the file to edit:**

- If `CLAUDE.local.md` exists, edit it.
- Else if `CLAUDE.md` exists, edit it.
- Else if `AGENTS.md` exists, edit it.
- If none exists, ask the user which one to create. Don't pick for them.
- If more than one exists, ask the user which one to edit. Don't pick for them.
- If `AGENTS.md` or `CLAUDE.md` exists but `CLAUDE.local.md` doesn't, ask the user if they want to use the existing file or `CLAUDE.local.md`.

If an `## Agent skills` block already exists in the chosen file, update its contents in-place rather than appending a duplicate. Don't overwrite user edits to the surrounding sections.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `.claude/docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `.claude/docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `.claude/docs/agents/domain.md`.
```

Include the `### Triage labels` sub-block, and write `.claude/docs/agents/triage-labels.md`, only when `triage` is installed and Section B ran. When it isn't, both are omitted.

If the issue tracker is **Beads**, expand the `### Issue tracker` section to include mandatory rules immediately after the one-liner, before `### Triage labels`:

```markdown
### Issue tracker

Issues live in Beads; use the `bd` CLI. See `.claude/docs/agents/issue-tracker.md`.

**Mandatory rules, apply in every session, regardless of which skill is running:**

1. **Session start**: Run `bd prime` before doing any issue tracker work. Do not skip this even if the session feels like a continuation.
2. **Read the spec before claiming**: If the issue has a parent epic, run `bd show <parent-id> --json` to read the spec (you may know this as a PRD). Use it as background context only: understand the broader goal, but do not act on work described there that falls outside the specific issue you are about to claim.
3. **Before working on an issue**: Claim it in the tracker before writing any code or making any changes.
4. **After completing an issue**: Close it in the tracker immediately. Do not batch closures to the end of a session.
5. **Spec-level issues are epics**: Every spec-level issue must be created as an epic. Sub-issues must reference their parent epic.
6. **Closing an epic**: Close the parent epic only after every issue under it is closed. Before closing, verify that no child issue is in any non-closed state (ready, in-progress, blocked, or otherwise open). If the state of any child is unclear, display the current child issue states and ask the user for directions before proceeding.
7. **One issue per session**: Pick up exactly one issue per session. Once closed, stop: report what was done and any non-obvious decisions or complications, then go silent. See `.claude/docs/agents/issue-tracker.md` for the full stop-and-report format.
```

When Section B ran on GitHub or GitLab, create each configured label the tracker lacks (`gh label create` / `glab label create`). Beads and local markdown need no such step: labels come into existence when first applied.

Then write the docs files by copying the seed templates in this skill folder verbatim. Do not paraphrase, summarise, or simplify them. The only permitted edits are repo-specific substitutions (e.g. replacing placeholder paths or label names with values the user confirmed):

- [issue-tracker-github.md](../docs/issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-gitlab.md](../docs/issue-tracker-gitlab.md): GitLab issue tracker
- [issue-tracker-local.md](../docs/issue-tracker-local.md): local-markdown issue tracker
- [issue-tracker-beads.md](../docs/issue-tracker-beads.md): Beads issue tracker
- [triage-labels.md](../docs/triage-labels.md): label mapping (only if `triage` is installed)
- [domain.md](../docs/domain.md): domain doc consumer rules + layout

For "other" issue trackers, write `.claude/docs/agents/issue-tracker.md` from scratch using the user's description.

### 5. Done

Tell the user the setup is complete and which engineering skills will now read from these files. Mention they can edit `.claude/docs/agents/*.md` directly later; re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.
