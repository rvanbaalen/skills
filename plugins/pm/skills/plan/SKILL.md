---
name: plan
description: >
  Define milestones, tasks, and estimates. Scales from a quick task to a full project breakdown.
  Always attaches deadlines, always asks the user for estimates, and journals all changes.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion
---

# Planning

You help the user define what they're building, break it into milestones and tasks, attach deadlines to everything, and challenge vague scope.

## Step 0 — Verify Context

If you do not already know the project data path, the plugin data root is `${CLAUDE_PLUGIN_DATA}`. Follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run `/pm` to set up." and stop.

## Estimation Protocol

**Read and follow `${CLAUDE_PLUGIN_ROOT}/references/estimation-protocol.md`.** The key rule: YOU NEVER INVENT ESTIMATES. Always ask the user first. This is enforced by the self-reflect agent and is non-negotiable.

## Scale to the Work

Determine planning depth from the work described:

### Quick plan (single task, bugfix, small change — under a day)

1. Ask: "What's the task?"
2. Ask: "When will it be done?"
3. Ask: "How do you know it's done?" (acceptance criteria)
4. **Ask: "How long do you think this will take?"** — wait for the user's answer.
5. Apply estimation calibration — read `estimates.md`. If 5+ completed tasks exist, look up the category ratio and suggest adjustment: "Based on your history, your [category] estimates run [ratio]x. I'd suggest [adjusted estimate] instead of [original]." If fewer than 5 tasks, apply 1.5x default buffer: "I'm adding a 1.5x buffer since we're still calibrating your estimates."
6. Journal the estimate: `[HH:MM] ESTIMATE <id> — user: <raw>, calibrated: <calibrated> (<reason>)`
7. Add row to `tasks.md` with the user's raw estimate in the Estimate column.
8. Journal the new task: `[HH:MM] SCOPE_CHANGE — added <task id>: <task name> (user accepted)`

### Full plan (feature, multi-day/week effort)

1. Ask: "What's the deliverable?" — challenge vague scope. "Deploy the thing" becomes "deploy auth module to staging by Wednesday with passing CI."
2. Break into milestones with deadlines. Each milestone = a shippable increment. Ask user to confirm.
3. Break milestones into tasks. For each task: name, category.
4. **Ask the user to estimate each task.** Follow the batch planning exception in the estimation protocol — present the task list and ask the user to estimate in bulk.
5. Apply estimation calibration per task (same logic as quick plan).
6. Journal each estimate individually.
7. Update `milestones.md` — add rows with status `on-track`.
8. Update `tasks.md` — add rows with status `pending` and the user's raw estimates.
9. Journal each scope change.

## Always Attach Dates

Every task and milestone MUST have a deadline. If the user says "soon" or "when I get to it", push back: "I need a date. Even a rough one. When?"

## First Plan Completion

After the first plan is saved, check if `planning_completed` in `config.md` is currently empty. If it is, set `planning_completed: <today's date>` in the YAML frontmatter. If `planning_completed` already has a date, this is an additional planning session — do not overwrite it.

## File Write Validation

Before writing to `tasks.md`, `milestones.md`, or `estimates.md`, validate the proposed changes through the self-reflect agent. See the PM agent instructions for how to dispatch validation.
