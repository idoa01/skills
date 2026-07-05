# Thermo-nuclear GitHub reviews never use event: APPROVE

The thermo-nuclear-code-quality-review skill can post its findings as a GitHub PR review via `gh api .../pulls/{pr}/reviews`. That endpoint's `event` field supports `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`, and the skill's HTML-report verdict already has three matching states (Approve / Request changes / Comment), so mapping a clean review straight to `APPROVE` would be the obvious, symmetric choice.

We deliberately never use `APPROVE`. A clean review posts as `COMMENT` instead of `APPROVE`; only `COMMENT` and `REQUEST_CHANGES` are reachable. Approving a PR is a meaningful, consequential action — it can satisfy branch-protection review requirements and unblock merges — and that decision should stay with a human reviewer, not be delegated to an automated skill invocation, however clean the diff looks.

## Consequences

Even a review with zero findings still requires a human to click Approve on GitHub. The skill's HTML report can keep showing a full three-state verdict (Approve / Request changes / Comment) for the reader's benefit; only the GitHub-posting path collapses "Approve" down to "Comment."
