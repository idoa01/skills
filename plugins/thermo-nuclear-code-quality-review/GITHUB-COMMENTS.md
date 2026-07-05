# GitHub Inline Comments Format

When a thermo-nuclear review should be posted directly onto a GitHub pull request (the
user asks to "post this to the PR", "comment on github", "add inline comments", "leave
review comments on the PR", or similar explicit GitHub/PR phrasing), post it as a single
GitHub PR review via `gh api`, following this spec.

This document is the **single source of truth** for that mode. It is independent of
[HTML-REPORT.md](./HTML-REPORT.md) — the two output modes can be requested together, and
if an HTML report was just generated in this same conversation, reuse its findings (see
§7) rather than re-reviewing from scratch.

Posting a review is **visible to the whole team and not trivially undoable**. Every step
in this document exists to make sure only reviewed, approved findings are ever sent.

---

## 1. What this mode produces

One GitHub PR review, created with a single `gh api` call to
`POST /repos/{owner}/{repo}/pulls/{pr_number}/reviews`, containing:

- A short top-level **review body** (verdict + framing + the one highest-leverage move,
  if one exists — see §6).
- Zero or more **inline comments**, each anchored to a `path` + `line` + `side` that falls
  within the PR's actual diff.

Only Blocker / High / Medium findings become inline comments. **Low/nit findings are
dropped entirely from this mode** — don't post them, and don't mention that they were
omitted. GitHub review comments are plain markdown with no custom styling, so there's no
"grouped nits card" equivalent here; a nit-severity comment is just noise on a line, and
the value of grouping them (as the HTML report does) doesn't carry over.

---

## 2. Resolving the target PR

`gh` talks to `github.com` by default. This repo (and others) may live on a GitHub
Enterprise host instead, so the target host must be resolved explicitly rather than
assumed — never omit `--hostname`/`-R` on the calls below and let `gh` silently default to
`github.com`.

1. If the user gives a full PR **URL**, parse `host`, `owner`, `repo`, and `pr_number`
   directly out of it — no `gh` call needed
   (e.g. `https://github.mycompany.com/acme/widgets/pull/123` →
   `host=github.mycompany.com`, `owner=acme`, `repo=widgets`, `pr_number=123`).
2. Otherwise (the user gave a bare PR number, or gave nothing and it should be inferred
   from the current branch), run:
   ```
   gh pr view <number, if given> --json number,headRepositoryOwner,headRepository,baseRefName,url
   ```
   and parse `host`, `owner`, `repo`, and `pr_number` from the returned `url` field the
   same way as step 1, for one uniform parsing path.
3. If that returns no PR for the current branch, stop and tell the user — don't guess and
   don't fall back to some other target.

Every `gh` call from here on must carry this resolved host explicitly. The flag differs by
subcommand family:

- `gh api ...` → `--hostname <host>`
- `gh pr ...` (e.g. `gh pr diff`) → `-R <host>/<owner>/<repo>`

---

## 3. Finding valid anchors: parse the diff first

GitHub's review-comment API rejects (`422`) any `line`/`side` that isn't part of the PR's
actual diff — you cannot comment on an untouched line elsewhere in a file. Don't discover
this by trial and error against the live API. Instead, resolve valid anchors up front:

1. Run `gh pr diff <pr_number> -R <host>/<owner>/<repo>` to get the unified diff.
2. Parse the hunk headers (`@@ -a,b +c,d @@`) per file to know, for every line in the
   diff, whether it's addressable on the `RIGHT` side (added/changed lines — from the `+`
   range) or the `LEFT` side (removed/context lines — from the `-` range).
3. For each finding, check whether its `file:line` falls inside one of these ranges.
   - **If it does:** anchor there directly, `side: RIGHT` for added/changed lines,
     `side: LEFT` for a line that only exists pre-change.
   - **If it doesn't** (the finding is about pre-existing code near the change, not a
     changed line itself): anchor to the **nearest changed line in the same file/hunk**,
     and open the comment body with a short note that it refers to nearby existing code
     (e.g. *"(re: the surrounding function, not this exact line)"*) so the anchor doesn't
     read as more precise than it is.
4. If a finding's file isn't part of the diff at all, it can't be posted as an inline
   comment — fold it into the review body instead, or drop it if it's not important
   enough to warrant that (use judgment; this should be rare for a review of this PR's own
   diff).

---

## 4. Skipping findings already flagged (dedup)

Before drafting comments, fetch the PR's existing review comments:

```
gh api --hostname <host> repos/{owner}/{repo}/pulls/{pr_number}/comments
```

A new finding is **already flagged** if an existing comment satisfies all of:

- same `path`
- `line` within a few lines of the finding's anchor (small shifts from reformatting/rebase
  are expected; this is intentionally loose, not exact-match)
- same severity/category tag in the existing comment's text (e.g. it also opens with
  `**🟠 HIGH**` and is clearly about the same kind of problem)

Skip drafting a new inline comment for anything that matches. During the approval
walk-through (§5), still surface these as skipped — e.g. "skipping: already flagged at
`foo.py:42`" — so the user can override and re-flag if they disagree (the fix may have
regressed, or the match may be a false positive).

This is a heuristic, not a guarantee — treat the human approval step as the real
safety net against duplicates, not this check.

---

## 5. Approval flow: one comment at a time

Never post anything without explicit approval first — even a "clean" review with only a
`COMMENT` event still needs a human to say go.

Walk through the draft findings **one at a time**, in the same severity-first order used
by the HTML report (structural regressions → missed code-judo → spaghetti/branching →
boundary/type → file-size → modularity → legibility). For each:

1. Show the severity, `file:line` anchor, and the full comment body as drafted.
2. Ask the user to approve, edit, or drop it.
3. Apply their answer immediately (edit the body in place if they give a correction) and
   move to the next one.

After the walk-through, show the final approved set once more before posting — total
count and a one-line list — as a last confirmation. Only what survived this process goes
into the `gh api` call. If the user drops everything, don't post an empty review; tell
them nothing was posted and stop.

---

## 6. Review body (top-level, not line-anchored)

Keep this short — it is **not** a condensed version of the HTML report. Include only:

1. **Verdict line** — one sentence stating the review's overall take (see §8 for how this
   maps to the `event` field).
2. **Framing** — 2–4 sentences: what the change does, what the review pushes on. Same
   spirit as the HTML hero, just in prose.
3. **The one high-leverage move**, only if one genuinely exists — one sentence naming the
   fix and why it's high-leverage (e.g. "this single relocation makes four other findings
   disappear"). Omit if no single fix stands out; don't manufacture one.

Do **not** include: severity counts, the approval-bar checklist, a "what's good" section,
or a list of every finding — the inline comments themselves are the substance of the
review body's counterpart.

---

## 7. Reusing findings from an HTML report

If an HTML report was already generated earlier in this same conversation and the
findings are still in context, don't re-run the review from scratch — reuse that exact
set of findings when drafting GitHub comments. Re-review from scratch only if:

- there's no HTML report findings in context (fresh session, or HTML mode was never run), or
- the branch has new commits since that report was generated.

---

## 8. The review event: never `event: APPROVE`

The `event` field is one of `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`. This skill **never
uses `APPROVE`** — even a clean review with zero findings posts as `COMMENT`, not
`APPROVE`. Approving a PR is a consequential action (it can satisfy branch-protection
requirements and unblock a merge) that should stay a deliberate human action, not
something a review skill does on the user's behalf. See
[docs/adr/0001-no-auto-approve-github-reviews.md](../../docs/adr/0001-no-auto-approve-github-reviews.md)
for the full rationale.

Map the verdict to the two remaining events the same way the HTML report maps to its
three-way verdict, minus the approve case:

- Any approved **Blocker** or **High** finding present → `REQUEST_CHANGES`.
- Otherwise (only Medium/Low survived, or nothing did) → `COMMENT`.

---

## 9. Posting

Once the approved set is final, build the payload and post it in one call:

```bash
gh api --hostname <host> repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input - <<EOF
{
  "event": "REQUEST_CHANGES",
  "body": "<review body from §6, github markdown>",
  "comments": [
    {
      "path": "src/index.js",
      "line": 42,
      "side": "RIGHT",
      "body": "<comment body from §10>"
    }
  ]
}
EOF
```

If the call fails for any reason (not authenticated, PR not found, a comment's anchor
still gets rejected, network error), **surface the exact error and stop** — no retries,
and no silent fallback to the HTML report. Tell the user what failed and let them decide
how to proceed.

---

## 10. Inline comment body format

Each inline comment is GitHub-flavored markdown, structured like a compressed version of
the HTML finding card:

```markdown
**🟠 HIGH** — <one-line problem statement>

<1-3 sentences: what's wrong and why it matters structurally — not just "this is ugly">

Current:
```<language>
<the problematic code>
```

Recommended:
```<language>
<the fix>
```

<one-line note on what this deletes/simplifies>
```

Severity prefixes match the HTML palette's meaning, written as bold + emoji since there's
no badge styling available: `**🔴 BLOCKER**`, `**🟠 HIGH**`, `**🔵 MEDIUM**`. (Low/nit never
appears here — see §1.)

When the anchor was snapped to a nearby line rather than the exact line (§3), open with
the nearby-code note before the severity line, e.g.:

```markdown
_(re: the surrounding function, not this exact line)_

**🟠 HIGH** — ...
```

Keep comments focused — one problem per comment, matching one finding. Don't bundle
multiple unrelated findings into a single comment body just because they're anchored to
the same line.
