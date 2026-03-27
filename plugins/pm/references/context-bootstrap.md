# Context Bootstrap

Every PM skill and the PM agent MUST follow this procedure before doing any work. If you already know the project data path (e.g., it was passed by the orchestrator), skip to step 3.

## Procedure

### 1. Compute project hash

Run:
```
printf '%s' "$(pwd)" | md5 | head -c 8
```

On Linux, fall back to:
```
printf '%s' "$(pwd)" | md5sum | head -c 8
```

This produces an 8-character hex string (the project ID).

### 2. Resolve data path

The plugin data root was provided by the skill or agent that invoked this procedure. The project data lives at: `<data-root>/<project-id>/`

### 3. Read config

Read `<data-path>/config.md`.

- **If the file does not exist:** Tell the user: "No PM project found for this directory. Run `/pm` to set up." Then stop. Do not proceed with any skill work.
- **If the file exists:** Parse the YAML frontmatter. Extract: `data_path`, `project_name`, `role`, `client`, `hard_deadline`, `setup_completed`, `planning_completed`.

### 4. Check version

Read `pm_version` from the config frontmatter. If it is missing, treat it as `1.0.0`.

Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and extract the `version` field.

If the config version does not match the plugin version, read `${CLAUDE_PLUGIN_ROOT}/references/migrations.md` and execute all migration blocks between the config version and the plugin version, in order. After migration completes, update `pm_version` in the config to match the plugin version.

### 5. Verify project files

Check that all expected files exist in the data path:
- `milestones.md`
- `tasks.md`
- `blockers.md`
- `estimates.md`
- `overrules.md`
- `sessions/` (directory)

If any are missing, report which files are missing and offer to re-scaffold them from `${CLAUDE_PLUGIN_ROOT}/templates/scaffolding/`.

### 6. Read all project files

Read every file listed in step 5, plus all files in `sessions/` (use Glob to find them). Also read the config body (below frontmatter) for project context.

You are now grounded. Proceed with the skill's work.
