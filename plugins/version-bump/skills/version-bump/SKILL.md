---
name: version-bump
description: Checks for changed plugin/skill files in marketplace projects and suggests semver version bumps before pushing. Use this skill whenever the user wants to push changes (git push, "push this", "push to remote") and the working directory contains a .claude-plugin/marketplace.json file — even if the user doesn't mention versions. Also trigger when the user explicitly mentions version bumping, releasing plugins, or preparing marketplace updates.
allowed-tools: Bash(git diff *) Bash(git log *) Bash(git status *)
---

# Version Bump

Before pushing changes in a marketplace project, check if any plugin files have been modified and guide the user through appropriate semver version bumps. This prevents plugins from being updated without their version reflecting the change — which matters for users who install plugins and need to know when updates are available.

## Detecting a marketplace project

A marketplace project has a `.claude-plugin/marketplace.json` file at the repository root. If this file doesn't exist, this skill doesn't apply — proceed with the push normally without mentioning this skill.

## Workflow

### 1. Identify changed plugins

Compare the current branch against the remote tracking branch:

```bash
git diff --name-only @{upstream}...HEAD 2>/dev/null
```

If there's no upstream yet (new branch), compare against the default branch (`main` or `master`).

Filter the results for paths matching `plugins/<plugin-name>/...` and extract the unique plugin names.

If no plugin files changed (only root-level files like README.md), skip version bumping and proceed with the push.

### 2. Check current versions

For each affected plugin, read the current version from:
- `plugins/<name>/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

Flag any version mismatches between the two files — the user should know if they've drifted out of sync.

If a plugin doesn't have a `version` field in its `plugin.json`, note this and suggest adding one.

### 3. Analyze changes and suggest a bump level

For each affected plugin, look at the actual diff to categorize the changes:

**Patch (x.y.Z)** — backwards-compatible fixes:
- Typo fixes, wording improvements in SKILL.md
- Description or metadata updates in plugin.json
- Bug fixes in scripts or reference files
- Minor clarifications or formatting changes

**Minor (x.Y.0)** — backwards-compatible additions:
- New skills added to a plugin
- New reference files, scripts, or agents added
- New features or capabilities in existing skills
- Significant content additions to SKILL.md
- New configuration options

**Major (X.0.0)** — breaking changes:
- Renamed or removed skills
- Changed skill invocation names (the `name` field in frontmatter)
- Restructured plugin directory layout
- Removed features or capabilities users may depend on

Present each plugin with:
- Its name and current version
- A short summary of what changed
- Your suggested bump level with reasoning
- The resulting new version number

Ask the user to confirm or override the suggestion for each plugin.

### 4. Apply the version bump

Before making any changes, explicitly ask the user which files to update. Present these as options:
1. `plugins/<name>/.claude-plugin/plugin.json` only
2. `.claude-plugin/marketplace.json` only
3. Both (recommend this to keep them in sync)

Do not assume "both" — wait for the user's answer. Then read each chosen file, update only the `version` field, and write it back.

### 5. Commit and push

After applying version bumps:
1. Stage the modified version files
2. Create a new commit with message: `chore: bump <plugin-name> to <new-version>` (or a combined message if multiple plugins were bumped)
3. Proceed with the push

## Edge cases

- **Multiple plugins changed**: Handle each one separately — different plugins may warrant different bump levels.
- **Version mismatch between files**: Alert the user and suggest aligning them before bumping.
- **No version field exists**: Suggest starting at `1.0.0`.
- **Only non-plugin files changed**: Skip version bumping entirely, don't mention it.
- **User declines all bumps**: Respect this and push without version changes.
