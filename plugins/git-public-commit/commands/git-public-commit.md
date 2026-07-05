---
name: git-public-commit
description: Create git commit messages for this repo using plain Conventional Commits format (type(scope): description) — no JIRA ticket lookup, no server-hook regex validation. Use whenever the user wants to commit staged or unstaged work in this repo, asks to "commit this", "make a commit", "stage and commit", write a commit message, or split changes into commits.
alwaysApply: false
allowed-tools: Bash, Read
---

# Git Commit (plain Conventional Commits)

Compose commits for this repo, which is a personal public GitHub repo with no
JIRA-issue push hook. Message format is plain Conventional Commits — no ticket
prefix, no regex to satisfy.

## The format contract

```
<type>[(<scope>)]: <description>
```

- **type** — exactly one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`,
  `test`, `build`, `ci`, `chore`, `revert`.
- **scope** — optional, in parentheses. Free text: whatever module/area name
  best fits the diff (e.g. `sidebar`, `tui`, `pricing`). Omit the parens
  entirely when no scope fits cleanly.
- **description** — imperative, lowercase after the prefix, no trailing
  period.

**Subject line ≤ 72 characters total.**

**Example:**

```
feat(sidebar): add filter input above session list

Narrows visible rows by matching the query against aiTitle,
projectLabel, and session UUID fields.
```

## Workflow

Steps 1–4 are read-only and produce a plan; nothing is staged or committed
until the user approves at step 5.

### 1. Inspect the working tree

```bash
git status --porcelain      # staged, unstaged, and untracked, machine-readable
git diff                    # unstaged changes
git diff --staged           # already-staged changes
```

Read the **actual diffs**, not just filenames — the content drives the type,
scope, and description. Note which files are already staged; respect the
user's existing staging intent rather than blindly restaging everything.

### 2. Guard against secrets — before staging anything

Treat these filenames as **do-not-commit** unless the user explicitly
overrides a specific file:

- `.env`, `.env.*` (any environment file)
- `credentials.json`, `*credentials*`, `secrets.*`, `service-account*.json`
- Private keys: `*.pem`, `*.key`, `id_rsa`, `id_ed25519`, `*.p12`, `*.pfx`, `*.keystore`
- `.npmrc` / `.pypirc` containing tokens, `*.tfvars` with secrets

This is a filename-level check only — there is no content-based secret scan
in this skill. When in doubt, exclude and ask.

### 3. Group changes into atomic commits

Default behavior: split the change set into the smallest set of **atomic**
commits, where each commit is one coherent, self-contained change. Group
files by **structural relationship**, not by directory alone:

- A source change and its tests/docs belong together.
- A new module and the wiring that registers it belong together.
- Unrelated changes that happen to be in the tree at the same time belong in
  separate commits (or no commit — see below).

**Unrelated stray files:** if an unstaged or untracked file doesn't fit the
change set (a scratch file, an unrelated edit, a leftover artifact), do
**not** commit it. If you're unsure whether it belongs, **ask** — don't
silently sweep it in or silently drop it.

### 4. Compose each commit message

For each planned commit, derive the segments from its diff:

- **type** — from the dominant nature of the change (table above).
- **scope** — the component or area touched, if one fits cleanly. Inspect
  `git log` to match the scope vocabulary already in use in this repo.
- **description** — imperative summary of *what* changed, lowercase, ≤72-char
  subject budget after the prefix.
- **body** — only if the *why* isn't obvious; wrapped at 72, blank line
  above it.

### 5. Present the plan, then stage and commit

Show the user the full plan before touching anything:

- the commit grouping (which files → which commit),
- the exact message for each commit,
- any files you're deliberately **excluding** and why (secrets, stray/unrelated).

After the user approves, for each commit: stage exactly its files
(`git add <paths>` — never blanket `git add -A` if it would sweep in excluded
files), then commit. Use a multi-line message safely via `-F`:

```bash
git add path/to/file1 path/to/file2

git commit -F - <<'EOF'
feat(scope): description

Optional body wrapped at 72 characters explaining the why.
EOF
```

(Or repeated `-m` flags for subject-only commits.) After committing, run
`git log --oneline -n <count>` and confirm the result back to the user.

## Quick checklist

- [ ] Diffs read, not just filenames
- [ ] Do-not-commit filenames excluded unless explicitly overridden
- [ ] Changes grouped into atomic commits; stray files excluded or queried
- [ ] Each subject ≤72 chars, valid type, blank 2nd line, body wrapped at 72
- [ ] Plan shown and approved before staging
