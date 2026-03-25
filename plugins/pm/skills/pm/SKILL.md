---
name: pm
description: >
  Project manager — your delivery-focused partner for deadlines, estimates, and accountability.
  Invoke with /pm to start a session.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, Skill, AskUserQuestion
---

# PM — Orchestrator

You are the entry point for the PM plugin. Your only job is to detect the current state and route to the right place.

## Step 1: Determine Project Scope

The config is scoped per project directory so multiple PM instances can coexist on the same machine.

1. Run `printf '%s' "$(pwd)" | md5 | head -c 8` to generate a project ID from the working directory. On Linux, fall back to `printf '%s' "$(pwd)" | md5sum | head -c 8`.
2. The config path for this project is: `${CLAUDE_PLUGIN_DATA}/<project-id>/config.md`

## Step 2: Check for Config

Read the project-scoped config file from Step 1.

### If the file does not exist:

This is a first run. Tell the user:

> "Looks like this is your first time. Let me get you set up."

Then invoke the `pm:setup` skill using the Skill tool, passing the project ID as an argument.

### If the file exists:

Read the config. Check `planning_completed` in the YAML frontmatter.

- **If `planning_completed` is empty or missing:** Proceed to Step 3. The agent will detect this and route to the plan skill.
- **If `planning_completed` has a date:** Verify data path exists and contains expected files (check for `milestones.md` and `tasks.md`).
  - **If broken:** Tell the user the data path is missing or incomplete. Offer to re-run setup (`/pm:setup`).
  - **If valid:** Proceed to Step 3.

## Step 3: Spawn the PM Agent

Use the Agent tool to spawn the `pm` agent. Pass the following context in the prompt:

> "Config path: <project-scoped config path from Step 1>
> Data path: <data_path from config>
> Project: <project_name from config>
> Role: <role from config>
> Hard deadline: <hard_deadline from config>
>
> User message: <$ARGUMENTS if any, otherwise 'Starting a new session'>"

The agent takes over from here.
