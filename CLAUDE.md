# Marketplace conventions

This repo is a Claude Code plugin marketplace. All plugins use **relative-path sources** (`./plugins/<name>`).

## Plugin versions live in marketplace.json, not plugin.json

Per [Claude Code docs](https://code.claude.com/docs/en/plugin-marketplaces): "For relative-path plugins, set the version in the marketplace entry. For all other plugin sources, set it in the plugin manifest." The plugin manifest always wins silently if both are set, so duplicating invites drift.

Rules for this repo:

- **`marketplace.json`**: each plugin entry MUST include `version`.
- **`plugin.json`**: MUST NOT include `version` (omit the field entirely).
- When bumping a version, edit `marketplace.json` only.

## Plugin `name` field = namespace

The `name` in `plugin.json` is the skill namespace (`/<plugin>:<skill>`). Each plugin must have its own unique `name`, matching the marketplace entry and the directory name under `plugins/`. Never share `name` across plugins — that collapses their skills into one namespace and causes conflicts.

## Adding a new plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `description`, `author` — no `version`.
2. Add an entry to `.claude-plugin/marketplace.json` with `name`, `source: "./plugins/<name>"`, `description`, `version`.
3. For side-effect skills, set `disable-model-invocation: true` in the SKILL.md frontmatter.
4. Pre-approve tool usage via `allowed-tools` where it cuts prompt fatigue.
5. Add `argument-hint` when the skill takes arguments.
6. Keep `SKILL.md` under ~500 lines; split long reference material into sibling files and link to them.
