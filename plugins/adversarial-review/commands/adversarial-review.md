---
name: adversarial-review
description: Adversarial plan-review loop where Claude (builder) and Cursor Agent (read-only critic) argue over a plan before any code is written. Use after /grill-with-docs to stress-test the converged plan with a cross-model second opinion. Claude writes a detailed PLAN.md, Cursor reviews it in plan mode and returns VERDICT:APPROVED or VERDICT:REVISE, Claude revises and resumes the SAME Cursor session until approved or MAX_ROUNDS is hit. Ends by updating CONTEXT.md and calling /to-prd then /to-issues.
alwaysApply: false
allowed-tools: Bash, Read, Edit, Write
effort: high
when_to_use: Use when the user says "/adversarial-review", "adversarial review", "have Cursor review my plan", "stress-test this plan", or has just finished /grill-with-docs and wants a cross-model sanity check before committing to implementation.
---

# Adversarial Review — Cross-Model Plan Stress-Test

Claude is the builder and orchestrator. Cursor Agent is a read-only critic — it reads the repo and `PLAN.md` but cannot write files (`--mode plan` enforces this on every call). They communicate through `PLAN.md` plus a Cursor session that persists across rounds. The human enters at exactly two points: kickoff and final sign-off.

Use this after `/grill-with-docs`. The grilling resolves domain language and design decisions; this skill stress-tests the resulting plan with a different model before the work is committed to a PRD and issues.

## Prerequisites

- Cursor Agent CLI installed: `cursor agent --version`
- Cursor authenticated: `cursor agent status`
- This skill is meant to run after `/grill-with-docs`. If no grilling session has happened, ask the user if they want to proceed with a plan from context or run `/grill-with-docs` first.

## Tunable variables

| Var | Default | Meaning |
|-----|---------|---------|
| `MAX_ROUNDS` | `5` | Hard cap on review rounds. Loop always terminates here. |
| `CURSOR_MODEL` | `gpt-5.5-high` | Model passed to `--model` on every Cursor call. |
| `PLAN_FILE` | `PLAN.md` | Where the evolving plan lives (repo root). |
| `LOG_FILE` | `PLAN-REVIEW-LOG.md` | Append-only transcript of every round's critique and Claude's response. The artifact. |

If the user passed args like `rounds=3` or `model=claude-fable-5-thinking-high`, apply them. Echo resolved values before starting.

### Recommended models for `CURSOR_MODEL`

| Model ID | When to use |
|----------|-------------|
| `gpt-5.5-high` | Default. Strong GPT, different model family from Claude — good cross-model tension. |
| `gpt-5.5-extra-high` | Maximum effort GPT when the plan is high-stakes (auth, schema, payments). |
| `composer-2.5` | Cursor's own default model — optimised for code planning in this environment. |
| `gemini-3.5-flash` | Fast and cheap — good for early rounds or when you want high iteration speed. |
| `grok-4.3` | Different architecture entirely — useful for a genuinely foreign perspective on the plan. |

## Flow

### Step 0 — Kickoff (human gate #1)

Confirm scope in one line: what is being planned. If no task is clear from context, ask for it (one question only). Then proceed — do NOT ask for round-by-round approval.

### Step 1 — Claude writes the plan

Synthesize everything from the current conversation (grilling session, domain context, ADRs, constraints) into `PLAN_FILE`. Be detailed — Cursor has more to bite into when the plan is specific.

Use this structure:

```markdown
# Plan: <task>
_Round 0 — initial draft by Claude_

## Goal
<one paragraph — what success looks like from the user's perspective>

## Background & constraints
<domain context, glossary terms resolved during grilling, ADRs in play, known constraints>

## User stories
<numbered list — every actor/want/benefit pair surfaced during grilling; be exhaustive>

## Approach
<numbered steps, concrete and sequenced>

## Module breakdown
| Module | What changes | HITL / AFK |
|--------|-------------|------------|
| ...    | ...         | ...        |

## Key decisions & tradeoffs
<the contestable choices — name them explicitly so Cursor has something to challenge>

## Risks / open questions
<what is uncertain or could go wrong>

## Testing approach
<what gets tested, how, and why those boundaries were chosen>

## Out of scope
<explicit bounds — what is deliberately excluded>
```

Initialize `LOG_FILE`:
```markdown
# Plan Review Log: <task>
Started <session start>. MAX_ROUNDS=<n>.
```

Show the user the plan inline and say you're sending it to Cursor for adversarial review.

### Step 2 — The review loop

Maintain `ROUND` (start at 1) and `SESSION_ID` (empty until round 1 returns).

**The review prompt** sent to Cursor each round:

> You are an adversarial reviewer for an implementation plan. Be skeptical and specific — your job is to find what breaks, not to be agreeable. Read the plan at `PLAN.md` and any repo files you need. Identify concrete flaws: security holes, race conditions, missing edge cases, schema conflicts, wrong assumptions, observability gaps, missing user stories, simpler alternatives. For each flaw, give a one-line fix. Do NOT modify any files. End your reply with EXACTLY one line: `VERDICT: APPROVED` if the plan is sound enough to proceed, or `VERDICT: REVISE` if it still has material problems.

**Round 1** (creates the session):

```bash
cursor agent \
  --model "$CURSOR_MODEL" \
  --mode plan \
  --print \
  --output-format json \
  --sandbox enabled \
  --trust \
  "<review prompt>" \
  > /tmp/cursor-verdict.json 2>/dev/null
```

Parse `session_id` from the JSON result field → that is `SESSION_ID`. The critique text is in the `result` field. Read it.

If the command fails (non-zero exit, `is_error: true`, or no `session_id`), stop and surface the error to the user — do not silently retry.

**Rounds 2..MAX** (resume the same session — Cursor remembers its prior critiques):

```bash
cursor agent \
  --resume "$SESSION_ID" \
  --mode plan \
  --print \
  --output-format json \
  --sandbox enabled \
  --trust \
  "I revised the plan based on your feedback. Re-read PLAN.md. Same rules. Check whether your prior concerns were addressed. End with VERDICT: APPROVED or VERDICT: REVISE." \
  > /tmp/cursor-verdict.json 2>/dev/null
```

**Each round, after Cursor returns:**

1. Parse `result` from `/tmp/cursor-verdict.json`. Append to `LOG_FILE`:
   ```
   ## Round <n> — Cursor
   <full critique>
   ```
2. Grep the last line for the verdict token.
   - `VERDICT: APPROVED` → break, go to Step 3 (converged).
   - `VERDICT: REVISE` → Claude reads the critique and decides **what is worth acting on**. Claude is the final arbiter — incorporate good critiques, reject weak ones with a reason logged. Revise `PLAN_FILE`. Append to `LOG_FILE`:
     ```
     ### Claude's response (Round <n>)
     Changed: <what was updated and why>
     Rejected: <what was not changed and why>
     ```
     Increment `ROUND`.
3. If `ROUND > MAX_ROUNDS` → break to Step 3 (deadlock).

### Step 3 — Resolution (human gate #2)

**If APPROVED:**

Present to the user:
- The final `PLAN_FILE` inline
- A 3-bullet summary of what the argument improved
- The round count

Ask: *"Plan approved after N rounds. Ready to create the PRD and issues?"*

**If MAX_ROUNDS hit without APPROVED (deadlock):**

Do NOT pretend it converged. Surface the unresolved disagreements explicitly — list each point Cursor still flags and Claude's counter-position. Ask the user to break the tie before proceeding.

**On user confirmation (either path):**

Run the three steps automatically in sequence:

1. **Update `CONTEXT.md`** — incorporate any new terms or decisions that crystallised during the review. Keep `CONTEXT.md` a pure glossary: no implementation details, no file paths.

2. **Call `/to-prd`** — synthesize the approved plan into a PRD and publish it to the issue tracker.

3. **Call `/to-issues`** — break the PRD into vertical slice issues and publish them to the issue tracker.

Do NOT write any code.

## Hard rules

- Cursor is read-only every round — `--mode plan` is non-negotiable. Never drop it.
- The loop always terminates at `MAX_ROUNDS`. No unbounded recursion.
- Claude is the final arbiter on every REVISE — don't capitulate to Cursor blindly, but log every rejection with a reason.
- No code is written at any point in this skill.
- `LOG_FILE` is the deliverable — it tells the full story of the argument. Keep it complete.

## What NOT to do

- Don't drop `--mode plan` — without it Cursor can write files.
- Don't skip the log — the argument transcript is the most valuable artifact.
- Don't cave to every Cursor critique — that defeats the cross-model check.
- Don't ignore every Cursor critique — that defeats the point.
- Don't write code — hand off to `/to-prd` and `/to-issues` instead.
