# Issue tracker: Beads

Issues for this repo live as Beads issues. Use the `bd` CLI for all operations.

Run `bd prime` to understand important commands and workflows for AI agents.

## Mandatory rules — apply in every session, regardless of which skill is running

1. **Session start**: Run `bd prime` before doing any issue tracker work. Do not skip this even if the session feels like a continuation.
2. **Read the spec before claiming**: If the issue has a parent epic, run `bd show <parent-id> --json` to read the spec (you may know this as a PRD). Use it as background context only — understand the broader goal, but do not act on work described there that falls outside the specific issue you are about to claim.
3. **Before working on an issue**: Claim it in the tracker before writing any code or making any changes.
4. **After completing an issue**: Close it in the tracker immediately. Do not batch closures to the end of a session.
5. **Spec-level issues are epics**: Every spec-level issue must be created as an epic. Sub-issues must reference their parent epic.
6. **Closing an epic**: Close the parent epic only after every issue under it is closed. Before closing, verify that no child issue is in any non-closed state (ready, in-progress, blocked, or otherwise open). If the state of any child is unclear, display the current child issue states and ask the user for directions before proceeding.
7. **One issue per session**: When working from the issue tracker, pick up exactly one issue per session. Once that issue is closed, stop. Write a closing report of 5–10 sentences summarising what was done. For each non-obvious decision, complication, or anything not explicitly derived from the issue description, add 2–3 sentences explaining what it was, why it arose, and how you resolved it. Then go silent — do not pick up another issue, suggest next steps, or continue with related work unless the user gives a new instruction.

## Conventions

- When you use `bd` use `--json` to get the details structured.
- Each issue (spec or task) should have a title and description, descriptions should be in md format, use heredocs for multiline bodies.
- Each spec needs to live inside one `epic` issue:
  - Use `--type epic` when creating the spec level issue
- Issues:
  - issues under the spec level should be created with `--type bug|feature|task|epic|chore|decision`, the default should be `--type task`
  - issues under the spec **must** be created with `--parent <epic-id>` at creation time — this gives the child a hierarchical ID like `wk8.1`, `wk8.2`. A post-hoc `bd dep add --type=parent-child` only adds a graph edge; it does NOT rename the issue, and Beads IDs cannot be changed after creation. If you forget `--parent`, delete the issue and recreate it.
  - avoid chaining multiple `bd create` calls in a single Bash command — they can race on the DB and silently drop issues. Run each `bd create` as a separate command.
  - give each issue a relevant priority with `-p <level>` with levels 0-4 or P0-P4, 0=highest) (default "2")
  - set issue dependencies with `--deps`. Dependencies in format 'type:id' or 'id' (e.g., 'discovered-from:bd-20,blocks:bd-15' or 'bd-20')
- When you need to understand what to do now, use `bd ready`

## When a skill says "publish to the issue tracker"

Create a Beads issue with `bd create`.

## When a skill says "fetch the relevant ticket"

Run `bd show <issue-id> --json`, and also `bd comments <issue-id> --json` if comment history matters.

## Mapping canonical triage roles to Beads

Beads is an AI-agent-first issue tracker so, by default, new issues are ready to be claimed by an AI agent through `bd ready`. Here's how the canonical triage roles map to beads issues:

| Canonical triage label     | Beads status         | Beads labels              | Description                              |
| -------------------------- | -------------------- | --------------------------| ---------------------------------------- |
| `needs-triage`             | Blocked              | `human`, `needs-triage`   | Maintainer needs to evaluate this issue  |
| `needs-info`               | Blocked              | `human`, `needs-info`     | Waiting on reporter for more information |
| `ready-for-agent`          | Open                 | None                      | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | Open                 | `human`                   | Requires human implementation            |
| `wontfix`                  | Closed               | `wont-fix`                | Will not be actioned                     |

Example: Add an issue that needs triaging: `bd create <id> --status blocked --add-label human,needs-triage`

## Wayfinding operations

Used by `/wayfinder`. The **map** is an epic with **child** issues as tickets — the same epic/parent-child hierarchy already used for specs above, not a separate label convention.

- **Map**: `bd create <title> --type epic --add-label wayfinder:map --description "..."`, body holding the Notes / Decisions-so-far / Fog. The label disambiguates a wayfinder map from an ordinary spec epic, which also uses `--type epic`.
- **Child ticket**: `bd create <title> --parent <epic-id> --type task --add-label wayfinder:<type>` where `<type>` is one of `research`/`prototype`/`grilling`/`task`. Must be created with `--parent` at creation time (see the parent-child rule above); a post-hoc `bd dep add --type=parent-child` only adds a graph edge and does not rename the issue.
- **Blocking**: Beads' **native** `blocks` dependency — `bd dep add <blocked-id> <blocker-id>` (or `bd link <blocked-id> <blocker-id>`). This is the canonical representation: `bd ready --explain` and `bd dep tree` render it directly, so no body-convention fallback is needed. A ticket is unblocked when every issue blocking it is closed.
- **Frontier query**: `bd children <epic-id> --json`, filtered to `status: open` with no unclosed blocker and no assignee — equivalently, `bd ready --json` scoped to children of the map (children inherit the parent-child edge, so an unblocked, unassigned child surfaces there directly). First in map order wins.
- **Claim**: `bd update <id> --claim` (or `bd assign <id> <you>`) — the session's first write.
- **Resolve**: `bd comment <id> "<answer>"`, then `bd close <id>`, then append a context pointer (gist + link) to the map's Decisions-so-far in the epic's description (`bd update <epic-id> --append-notes "..."` or re-editing the description).
