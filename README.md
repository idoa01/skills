# idoa01 Skills

Claude Code and Cursor skills for my personal use

## Structure

```
plugins/
  py-tdd/
    SKILL.md        # Skill entry point (Claude Code + Cursor)
    docs/           # Supporting documentation
scripts/
  cursor-install.sh # Install skills into a Cursor project
docs/
  writing-skills.md # Contributor guide
```

## Usage

### Claude Code

Add the marketplace:

```
/plugin marketplace add idoa01/skills
```

Then invoke a skill:

```
/py-tdd
```

### Cursor

Copy skills into your project with the install script:

```bash
./scripts/cursor-install.sh --target /path/to/your/project
```

Then invoke a skill:

```
/py-tdd
```

## Contributing

See [docs/writing-skills.md](docs/writing-skills.md) for the contributor guide.
