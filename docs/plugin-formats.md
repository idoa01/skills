# Plugin and Marketplace Format Reference

Source: https://code.claude.com/docs/en/plugins-reference and https://code.claude.com/docs/en/plugin-marketplaces

---

## marketplace.json

**Location**: `.claude-plugin/marketplace.json` at the repo root

### Required fields

| Field | Description |
|---|---|
| `name` | Marketplace identifier (kebab-case). Users see this in `/plugin install foo@<name>` |
| `owner.name` | Name of the maintainer or team |
| `plugins` | Array of plugin entries (can be empty, but that triggers a warning) |

### Optional top-level fields

| Field | Description |
|---|---|
| `description` | Brief marketplace description |
| `version` | Marketplace manifest version |
| `metadata.pluginRoot` | Base path prepended to relative plugin sources (e.g. `"./plugins"` lets you write `"source": "py-tdd"`) |

### Plugin entry — required fields

| Field | Description |
|---|---|
| `name` | Plugin identifier (kebab-case). Used in `/plugin install <name>@marketplace` |
| `source` | Where to fetch the plugin (relative path string or source object) |

### Plugin entry — optional fields (those we care about)

| Field | Description |
|---|---|
| `description` | Brief plugin description |
| `author.name` | Plugin author name |
| `category` | Plugin category string |
| `tags` | Array of strings for searchability |
| `version` | If set here or in plugin.json, pins the plugin — users only get updates when this changes. Omit to use git SHA (recommended for active dev). |

### Source types

| Type | Format | Notes |
|---|---|---|
| Relative path | `"./plugins/foo"` | Must start with `./`. Resolves from marketplace root (the dir containing `.claude-plugin/`), NOT from `.claude-plugin/` itself |
| GitHub | `{"source": "github", "repo": "owner/repo", "ref"?: "...", "sha"?: "..."}` | |
| Git URL | `{"source": "url", "url": "https://...", "ref"?: "...", "sha"?: "..."}` | |
| Git subdir | `{"source": "git-subdir", "url": "...", "path": "tools/plugin", "ref"?: "..."}` | Sparse clone for monorepos |
| npm | `{"source": "npm", "package": "@org/pkg", "version"?: "..."}` | |

### Minimal example

```json
{
  "name": "my-marketplace",
  "owner": { "name": "My Team" },
  "plugins": [
    {
      "name": "my-skill",
      "source": "./plugins/my-skill",
      "description": "Does X",
      "author": { "name": "My Team" },
      "category": "productivity",
      "tags": ["python", "testing"]
    }
  ]
}
```

---

## plugin.json

**Location**: `<plugin-root>/.claude-plugin/plugin.json`

The file is optional. If omitted, Claude Code auto-discovers components from default locations. Include it when you need to provide metadata or non-default component paths.

### Required field (if the file exists)

| Field | Description |
|---|---|
| `name` | Unique identifier (kebab-case) |

### Metadata fields we care about

| Field | Description |
|---|---|
| `description` | Brief plugin description |
| `version` | Semantic version. If set, must be bumped on each release. If omitted, git SHA is used as version (good for active dev). |
| `author.name` | Author name (email optional) |

### Component path fields (relevant for our structure)

| Field | Description |
|---|---|
| `skills` | Adds to default `skills/` scanning. Set `["./"]` when SKILL.md lives directly at the plugin root (not under a `skills/` subdir). |

### Skill discovery rules

- Default: Claude scans `<plugin-root>/skills/<name>/SKILL.md`
- **Our convention**: skills live in `commands/<cmd>.md` at the plugin root — no `plugin.json` skills field needed for Cursor (the install script handles placement). Claude Code picks up the skill via marketplace source path.
- The `skills` field **adds to** (does not replace) the default `skills/` directory scan

### Minimal example (our structure)

```json
{
  "name": "py-tdd",
  "description": "TDD workflow for Python with pytest",
  "author": { "name": "Ido Abramovich" }
}
```

Note: `version` is intentionally omitted — every commit is treated as a new version via git SHA, so users always get the latest without manual version bumps.

---

## Key gotchas

1. **`plugins` array is required** in marketplace.json — a file without it is not a valid marketplace catalog.
2. **Relative source paths resolve from the marketplace root**, not from `.claude-plugin/`. So `./plugins/py-tdd` in a marketplace whose root is the repo root points to `<repo>/plugins/py-tdd`.
3. **`owner.url` is not a documented field** — only `owner.name` and `owner.email` are supported.
4. **Version pinning**: setting `version` in plugin.json means users only get updates when you bump it. **We omit `version`** so every commit is a new version — no manual release process needed.
5. **`strict: true` (default)**: `plugin.json` is authoritative. The marketplace entry can supplement but not replace it. Use `strict: false` only when the marketplace operator wants full control and the plugin has no `plugin.json`.
