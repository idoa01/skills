# Writing Skills

This guide covers how to add a new skill to this repository. Skills live under `plugins/<name>/commands/` and work in both Claude Code and Cursor from a single source file.

## Directory structure

```
plugins/
  <name>/
    commands/
      <cmd>.md      # Required: skill entry point (one file per skill)
    docs/           # Optional: supporting reference docs
      topic-a.md
      topic-b.md
```

Each plugin is a directory under `plugins/`. A plugin can contain multiple skills — one `.md` file per skill in the `commands/` subdirectory. The only required file is `SKILL.md`. Add a `docs/` subdirectory when the skill body would grow unwieldy — reference docs let you keep the main file focused and load detail on demand.

## SKILL.md frontmatter

Every `SKILL.md` starts with a YAML frontmatter block. Both Claude Code and Cursor read this block; each agent ignores fields it doesn't recognise.

```yaml
---
name: my-skill
description: One-sentence description of what this skill does and when to invoke it.
alwaysApply: false
allowed-tools: Bash, Read, Edit, Write
model: sonnet
effort: high
when_to_use: Describe the trigger conditions here.
---
```

### Field reference

| Field | Used by | Required | Description |
|---|---|---|---|
| `name` | Both | Yes | Skill identifier; becomes the slash command (`/my-skill`) |
| `description` | Both | Yes | Shown in the skill list; also used by Claude Code to decide when to trigger the skill |
| `alwaysApply` | Cursor | Yes | Set to `false` so Cursor treats the skill as on-demand (slash command), not auto-applied context |
| `allowed-tools` | Claude Code | No | Comma-separated list of tools the skill is permitted to use |
| `model` | Claude Code | No | Model to use for this skill (e.g. `sonnet`, `opus`) |
| `effort` | Claude Code | No | Effort level hint (`low`, `medium`, `high`) |
| `when_to_use` | Claude Code | No | Human-readable trigger description; supplements `description` for Claude's routing logic |

`name`, `description`, and `alwaysApply` are the minimum viable frontmatter for a skill that works in both agents.

## Writing the body

The body is the full instruction set Claude or Cursor will follow when the skill is invoked. Write it as Markdown.

**Be complete.** Unlike a README, the skill body is loaded into the model's context and must be self-contained. Don't rely on the model knowing your conventions — state them explicitly.

**Structure with headings.** Break the skill into named phases or sections (e.g. `## Planning`, `## Workflow`, `## Checklist`). This makes the document scannable and lets you reference sections by name.

**Reference docs with relative paths.** Link to files in `docs/` using paths relative to `SKILL.md`:

```markdown
See [docs/topic-a.md](docs/topic-a.md) for detail on X.
```

These paths resolve correctly both in the source repo and after the skill is installed to a target project, because `cursor-install.sh` copies the entire skill directory together.

**Avoid prose dumps.** Use checklists, code blocks, and short paragraphs. The model reads the whole body; dense walls of text reduce instruction fidelity.

## Writing reference docs

Each file in `docs/` should cover one topic and be self-contained — a reader should be able to understand it without reading the others.

- Name files by topic: `fixtures.md`, `mocking.md`, `interface-design.md`
- Start each file with a brief statement of what it covers
- Include concrete examples; abstract principles without examples are hard to act on
- Cross-link to other docs in the same directory when relevant: `[docs/mocking.md](docs/mocking.md)`

The skill body typically lists its reference docs at the end under a heading like `## Reference files`. The model loads them on demand rather than all at once.

## Testing locally

### Claude Code

Claude Code discovers skills automatically from `plugins/*/commands/*.md` when the marketplace is installed. To test a skill you're writing:

1. From the repo root, open Claude Code.
2. Invoke the skill by name: `/my-skill`
3. Confirm the skill loads with the correct instructions and that any doc links are reachable.

No install step is needed — Claude Code reads from the repo directly.

### Cursor

Cursor requires the skill files to be present in the target project. Use the install script:

```bash
./scripts/cursor-install.sh --target /path/to/test-project
```

The script will list available skills and prompt you to select which to install. After installation:

1. Open the test project in Cursor.
2. Invoke the skill via slash command: `/my-skill`
3. Verify the skill runs as expected and that doc links resolve correctly.

To re-test after changes, re-run the install script — it overwrites the destination.

## How cursor-install.sh works

The script does three things:

1. **Filesystem scan**: Finds all `plugins/*/commands/*.md` files. Adding a new `.md` file to a plugin's `commands/` directory is all that's needed — there is no manifest to update.
2. **Frontmatter parse**: Extracts the `description` field from each skill's YAML frontmatter using `sed` (no `jq` required).
3. **Nested install**: For each `commands/<cmd>.md`, creates `<target>/.cursor/skills/<plugin>/<cmd>/SKILL.md`. Also copies `docs/` next to the command folders so that relative paths like `../docs/topic-a.md` resolve correctly from the installed location.

Skills are installed to `.cursor/skills/` (not `.cursor/rules/`) so Cursor treats them as on-demand slash commands rather than auto-applied context.

## Checklist for adding a new skill

- [ ] Create `plugins/<name>/commands/` directory
- [ ] Write `plugins/<name>/commands/<name>.md` with valid frontmatter (`name`, `description`, `alwaysApply: false`)
- [ ] Add `plugins/<name>/docs/` subdirectory with reference files if the body references them (use `../docs/` relative paths)
- [ ] Invoke the skill from the repo root in Claude Code and confirm it loads correctly
- [ ] Run `./scripts/cursor-install.sh --target <test-project>`, open in Cursor, invoke the skill, confirm it works
- [ ] Open a PR — no manifest update needed
