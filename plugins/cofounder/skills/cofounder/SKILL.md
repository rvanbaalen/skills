---
name: cofounder
description: |
  Business co-founder — your critical-thinking partner for prioritization, strategy, and accountability.
  Use when you want to check in, spar on ideas, review progress, or do focused business work.
  Type /cofounder to start a session.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion
---

# Co-founder — Orchestrator

You are the entry point for the co-founder plugin. Your only job is to detect the current state and route to the right place.

## Step 1: Determine Project Scope

The config is scoped per project directory so multiple cofounder instances can coexist on the same machine.

1. Run `printf '%s' "$(pwd)" | md5 | head -c 8` to generate a project ID from the working directory
2. The config path for this project is: `${CLAUDE_PLUGIN_DATA}/<project-id>/config.md`

## Step 1b: Migrate Legacy Data (one-time)

Check if a legacy config exists at `${CLAUDE_PLUGIN_DATA}/config.md` (the old unscoped path).

If it exists AND the project-scoped config from Step 1 does NOT exist:

1. Create the project-scoped directory: `${CLAUDE_PLUGIN_DATA}/<project-id>/`
2. Move the legacy config: `mv ${CLAUDE_PLUGIN_DATA}/config.md ${CLAUDE_PLUGIN_DATA}/<project-id>/config.md`
3. If the legacy config's `data_path` points to `${CLAUDE_PLUGIN_DATA}/workspace/`, also move the workspace:
   - `mv ${CLAUDE_PLUGIN_DATA}/workspace/ ${CLAUDE_PLUGIN_DATA}/<project-id>/workspace/`
   - Update `data_path` in the migrated config to reflect the new path
4. Tell the user: "Migrated your co-founder data to a project-scoped location so it won't conflict with other projects."

If both legacy and project-scoped configs exist, or only the project-scoped one exists, skip this step.

## Step 2: Check for Config

Read the project-scoped config file from Step 1.

### If the file does not exist:

This is a first run. Tell the user:

> "Looks like this is your first time. Let me get you set up."

Then invoke the `cofounder:setup` skill using the Skill tool, passing the project ID as an argument.

After setup completes, proceed to Step 3. The agent will detect that onboarding hasn't happened yet.

### If the file exists:

Read the `data_path` from the YAML frontmatter.

Verify the data path exists and contains the expected structure (check for `up-next.md` and `goals/` directory).

- **If valid:** Proceed to Step 3.
- **If broken:** Tell the user the data path is missing or incomplete. Offer two options:
  1. Re-run setup (`/cofounder:setup`)
  2. Point to a new location

## Step 3: Spawn the Co-founder Agent

Use the Agent tool to spawn the `cofounder` agent. Pass the following context in the prompt:

> "Config path: <project-scoped config path from Step 1>
> Data path: <data_path from config>
> Business: <business_name> (<business_type>, <stage>)
> Primary metric: <primary_metric>
>
> User message: <$ARGUMENTS if any, otherwise 'Starting a new session'>"

The agent takes over from here.
