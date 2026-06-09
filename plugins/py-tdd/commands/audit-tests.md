---
name: audit-tests
description: Audit existing Python tests for quality and coverage gaps when they were written WITHOUT the py-tdd loop. Grades each test against py-tdd's good/bad-test rubric and reasons about which behaviors the tests should check but don't. Use when you wrote tests in a session that skipped /py-tdd and want to confirm they're still good tests, or ask "are these tests any good / what are they missing".
alwaysApply: false
---

# Audit Tests

A retroactive quality gate for tests written **without** the [py-tdd](py-tdd.md) red-green
loop. When you forget to run `/py-tdd` and hand Claude a task, the tests that come back
may be coupled to implementation, may assert nothing meaningful, or may miss the
behaviors that actually matter. This skill catches that after the fact.

It does **two** things:

1. **Quality audit** — grade each existing test against py-tdd's good/bad-test rubric.
2. **Coverage gaps** — read the code each test exercises and reason about which observable
   behaviors *should* be checked but aren't.

It is **report-only**. It never rewrites tests or adds new ones in this pass — bulk-writing
tests is the "horizontal slice" anti-pattern py-tdd exists to prevent. When it finds gaps,
it hands off to `/py-tdd` so they get filled one vertical slice at a time, with your
approval.

The rubric is not duplicated here — it lives in py-tdd's reference docs, and this skill
reads them so the two skills can never drift:

- Good vs bad tests → [docs/tests.md](../docs/tests.md)
- When/how to mock, Protocols → [docs/mocking.md](../docs/mocking.md)
- Fixtures, DI patterns → [docs/fixtures.md](../docs/fixtures.md)
- Testability principles → [docs/interface-design.md](../docs/interface-design.md)
- Deep modules → [docs/deep-modules.md](../docs/deep-modules.md)
- Pydantic model/factory testing → [docs/pydantic.md](../docs/pydantic.md)

## Arguments

```
/audit-tests [path-or-glob ...] [--run]
```

- **`path-or-glob`** *(optional)* — explicit test files/dirs to audit. Overrides git inference.
- **`--run`** *(optional)* — execute the target tests once with pytest before auditing.
  Off by default; the common path is a fast static read. Pass it when you want to catch
  tests that error, are skipped, or pass vacuously.

## Workflow

### 1. Scope — decide which test files to audit

Resolve the target in this precedence order; stop at the first that yields files:

1. **Explicit argument.** If a path/glob was passed, audit exactly those files.
2. **Branch diff.** Else, the test files changed on this branch:
   `git diff --name-only <base>...HEAD` where `<base>` is `main` (fall back to `master`).
   Keep only paths that look like tests (`test_*.py`, `*_test.py`, or under a `tests/` tree).
3. **Uncommitted changes.** If the branch diff is empty (you're on the base branch, or it's
   clean), fall back to `git diff --name-only HEAD` plus untracked test files from
   `git status`.
4. **Ask.** If all of the above are empty, ask the user which tests to audit. Do not
   default to the whole suite — that re-flags old tests nobody asked about.

State what you resolved before proceeding, e.g. *"Auditing 3 changed test files vs `main`:
…"* so the user can redirect if it's wrong.

### 2. (Optional) Run the tests — only with `--run`

If `--run` was passed, execute just the target files once:

```
pytest <target files> -q
```

Record per-test outcomes. Feed them into the audit:

- **error / fail** — the test isn't green. Flag it; a red test can't be trusted as a spec.
- **skipped / xfail** — note it; a skipped test covers nothing.
- **passed** — still scrutinize it in step 3. Passing ≠ meaningful.

Never add coverage instrumentation or mutation testing — a single plain run is the only
execution this skill does.

### 3. Quality audit — grade each test

Load [docs/tests.md](../docs/tests.md) and [docs/mocking.md](../docs/mocking.md) and apply
their rules. For each test, decide: **does it verify observable behavior through the public
interface, or is it coupled to implementation?**

Flag a test when you see any red flag from the rubric:

- [ ] **Mocks an internal collaborator** (not a true boundary like a network/DB/clock).
      See [docs/mocking.md](../docs/mocking.md) for the boundary distinction.
- [ ] **Asserts on call counts / call order / arguments** (`mock.assert_called_once_with`,
      `assert_has_calls`) instead of on a result the caller can observe.
- [ ] **Exercises a private method** (`obj._helper(...)`) or other non-public surface.
- [ ] **Verifies through a side channel** — e.g. raw `SELECT` against the DB instead of
      reading back through the interface.
- [ ] **Name describes HOW, not WHAT** (`test_calls_validate_then_save` vs
      `test_rejects_invalid_email`).
- [ ] **Vacuous / weak assertion** — no assert, `assert True`, or `assert x is not None`
      when a stronger, behavior-level assertion was available.
- [ ] **Tests shape, not behavior** — asserts on data-structure layout, field presence, or
      method signatures rather than what the system *does* (a tell-tale sign of tests
      written in bulk against imagined behavior).
- [ ] **Would break on a pure refactor** — the decisive test: if you renamed an internal
      method or restructured the implementation without changing behavior, would this test
      fail? If yes, it's testing implementation.

Also note the **solid** tests briefly — honest acknowledgement of what's already good keeps
the critical findings credible, and tells the user what *not* to touch.

If the project has a `CONTEXT.md` glossary at its root, use it so your verdicts and any
suggested test names use the project's canonical domain language, exactly as `/py-tdd` does.

### 4. Coverage gaps — what these tests should also check

For each unit under test, **read the implementation** and enumerate its observable
behaviors, then check which are asserted by at least one test. Reason from the code — do
not run coverage tooling.

For each public entry point the changed tests touch, enumerate:

- **Happy-path outcomes** — each distinct successful result the caller can observe.
- **Branches** — each `if`/`match`/early-return that produces a different observable result.
- **Error paths** — every `raise` / documented exception / error return the caller could hit.
- **Boundaries** — empty, zero, single-element, max, None/optional, duplicate inputs.
- **Contracts** — anything a docstring or type signature promises.

A behavior is a **gap** if no test asserts it. List gaps, **prioritized** — py-tdd's rule is
*you can't test everything*, so lead with critical paths and complex logic, not exhaustive
edge cases. Mark each gap's priority so the user can choose where to spend effort.

Do **not** propose gaps for behavior outside the audited scope — stay anchored to the code
the changed tests actually exercise, unless the user widened the scope explicitly.

### 5. Report

Emit a single terminal markdown report. Keep it scannable — verdict first, then findings.
Anchor every finding to `file:line`. Group low-value nits into one line rather than spending
a bullet each.

```markdown
# Test Audit — <target>

<N test files · M tests>[ · ran: P passed, F failed, S skipped]   ← run stats only if --run

## Verdict
<one or two sentences: are these good tests, and what's the biggest problem>

## Quality findings

### 🔴 Coupled to implementation
- `test_checkout.py:42` `test_checkout_calls_payment` — patches the internal
  `PaymentService`; breaks on refactor without behavior change. Assert on
  `result.status` instead.

### 🟠 Weak or misleading
- `test_user.py:18` `test_create_user` — only asserts the returned object is not None.
  Assert the user is retrievable through `get_user`.

### ✅ Solid (leave alone)
- `test_cart.py:30` `test_total_sums_line_items` — behavior through the public API.

## Coverage gaps — behaviors not asserted
Reasoned from `app/checkout.py`:
- 🔴 `checkout()` raises `PaymentDeclined` when the card is rejected — untested.
- 🟠 `checkout()` with an empty cart — untested boundary.
- ⚪ `checkout()` applies a discount code — untested.

## Next step
<the py-tdd handoff offer — see step 6>
```

Severity legend: 🔴 must-fix / critical behavior · 🟠 should-fix · ⚪ minor / nice-to-have ·
✅ already good.

### 6. Offer the py-tdd handoff

End by offering — not performing — the fix. Two tracks:

- **Quality fixes** (rewriting a coupled or weak test): these are behavior-preserving edits
  to existing tests; offer to do them directly if the user approves, one test at a time.
- **Coverage gaps** (writing missing tests): hand off to **[`/py-tdd`](py-tdd.md)**. Do
  **not** bulk-write the missing tests here — that's the horizontal-slice anti-pattern.

  Most gaps you find are **already-working behavior that just isn't tested** — the code
  runs, only the test is missing. A test written against working code passes immediately,
  so there's no RED, and a test you never saw fail can be silently vacuous. py-tdd's
  **test-after mode** handles exactly this: write the test, then confirm it can fail by
  temporarily breaking the implementation before trusting it. Route gaps accordingly:
  - *already-working behavior* → py-tdd **test-after** recipe (break-to-confirm-RED).
  - *missing or broken behavior* → py-tdd **normal** red→green loop.

  Frame it as: *"I found N gaps. Most are untested-but-working behavior, so I'll run
  py-tdd's test-after recipe — write each test, then break the code to confirm it actually
  catches the bug — one at a time, highest priority first. The M that look genuinely
  missing get the normal red→green loop. Want me to start?"*

Wait for the user to pick. Never edit or create tests without explicit approval.

## Checklist

```
[ ] Target resolved and stated (arg → branch diff → uncommitted → ask)
[ ] Ran pytest once IFF --run was passed
[ ] Each test graded against the docs/tests.md + docs/mocking.md rubric
[ ] Solid tests acknowledged, not just the bad ones
[ ] Coverage gaps reasoned from the code under test, prioritized by criticality
[ ] Findings anchored to file:line
[ ] No tests written or rewritten — only reported
[ ] py-tdd handoff offered for gaps; waited for approval
```
