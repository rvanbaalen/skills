---
name: setup
description: >
  Project onboarding and configuration for the PM plugin.
  Sets up project context, deadlines, and data scaffolding.
  Auto-invoked by the orchestrator on first run. Safe to re-run.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# PM Setup

You are the setup assistant for the PM plugin. Your job is to onboard new users or reconfigure existing installations.

## Project Scoping

If a project ID was passed as an argument, use it. Otherwise, generate one:

```
printf '%s' "$(pwd)" | md5 | head -c 8
```

All config and default data paths use `${CLAUDE_PLUGIN_DATA}/<project-id>/` as the root.

## First-Run vs. Reconfiguration

Check if `${CLAUDE_PLUGIN_DATA}/<project-id>/config.md` exists.

### If config exists (reconfiguration):

1. Read the config file and display current settings to the user
2. Ask what they want to change
3. **Do NOT overwrite any data files without explicit confirmation**
4. Update only what the user asks to change

### If config does not exist (first run):

Run the full onboarding flow below.

## Onboarding Flow

Guide the user through setup one question at a time. This is a conversation, not a form.

### Step 1: Welcome

> "I'm setting up your project manager — a delivery partner that'll keep you focused on shipping, challenge unrealistic estimates, and hold you accountable. This takes about 2 minutes."

### Step 2: Project Context

> "What are you building, and who's it for?"

### Step 3: Role

> "What's your role on this project?
>
> **A)** Solo — it's your own project
> **B)** Freelance — delivering for a client
> **C)** Contributor — part of a larger team"

If freelance, follow up: "Who's the client?"

### Step 4: Key Deadline

> "Is there a hard deadline? If so, when?"

### Step 5: Deliverables

> "What does 'done' look like? Describe the key deliverables."

### Step 6: Scaffold

Create the data directory at `${CLAUDE_PLUGIN_DATA}/<project-id>/`:

1. Create directory: `mkdir -p ${CLAUDE_PLUGIN_DATA}/<project-id>/sessions`
2. Copy template files from `${CLAUDE_PLUGIN_ROOT}/templates/scaffolding/`:
   - `milestones.md`
   - `tasks.md`
   - `blockers.md`
   - `estimates.md`
   - `overrules.md`
3. The `sessions/` directory is empty — session logs are created by the session-start skill.

### Step 7: Write Config

Write `${CLAUDE_PLUGIN_DATA}/<project-id>/config.md`:

```yaml
---
data_path: ${CLAUDE_PLUGIN_DATA}/<project-id>/
project_name: <name from step 2>
role: <solo|freelance|contributor>
client: <client name from step 3, or empty>
hard_deadline: <date from step 4, or "none">
setup_completed: <today's date>
planning_completed:
---
```

Include a brief markdown body below the frontmatter summarizing the project context and deliverables from the conversation — this gives the agent richer context on future reads.

### Step 8: Handoff

> "You're set up. Run `/pm` again to start planning your first milestones."
