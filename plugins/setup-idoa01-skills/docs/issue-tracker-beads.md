# Issue tracker: Beads

Issues for this repo live as Beads issues. Use the `bd` CLI for all operations.

Run `bd prime` to understand important commands and workflows for AI agents.

## Mandatory rules — apply in every session, regardless of which skill is running

1. **Session start**: Run `bd prime` before doing any issue tracker work. Do not skip this even if the session feels like a continuation.
2. **Before working on an issue**: Claim it in the tracker before writing any code or making any changes.
3. **After completing an issue**: Close it in the tracker immediately. Do not batch closures to the end of a session.
4. **PRD-level issues are epics**: Every PRD-level issue must be created as an epic. Sub-issues must reference their parent epic.
5. **Closing an epic**: Close the parent epic only after every issue under it is closed. Before closing, verify that no child issue is in any non-closed state (ready, in-progress, blocked, or otherwise open). If the state of any child is unclear, display the current child issue states and ask the user for directions before proceeding.
6. **One issue per session**: When working from the issue tracker, pick up exactly one issue per session. Once that issue is closed, stop. Write a closing report of 5–10 sentences summarising what was done. For each non-obvious decision, complication, or anything not explicitly derived from the issue description, add 2–3 sentences explaining what it was, why it arose, and how you resolved it. Then go silent — do not pick up another issue, suggest next steps, or continue with related work unless the user gives a new instruction.

## Conventions

- When you use `bd` use `--json` to get the details structured.
- Each issue (PRD or task) should have a title and description, descriptions should be in md format, use heredocs for multiline bodies.
- Each PRD needs to live inside one `epic` issue:
  - Use `--type epic` when creating the PRD level issue
- Issues:
  - issues under the PRD level should be created with `--type bug|feature|task|epic|chore|decision`, the default should be `--type task`
  - issues under the PRD should be created with `--parent <epic-id>` with the id of the parent epic
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
