---
name: session-start
description: >
  Beginning-of-session check-in. Shows timeline health, validates alignment with the plan,
  and sets session intent. Writes SESSION_START to the journal.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Session Check-In

Fast by default. If everything is on track, this is 30 seconds.

## Step 0 — Verify Context

If you do not already know the project data path, follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run `/pm` to set up." and stop.

## Step 1 — Read Current State

Read `milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`.

Also read today's journal (`sessions/YYYY-MM-DD-journal.md`) if it exists — this tells you if a session already happened today.

## Step 2 — Show Timeline Health

For each milestone:
- Days until deadline
- Tasks done vs. total
- Status: on-track / at-risk / overdue
- Format as a brief summary, not a data dump.

## Step 3 — Check Alignment

Ask: "What are you working on this session?"

Compare to active tasks in `tasks.md` with status `pending` or `in-progress`.
- If aligned with plan: "Good, that's on the critical path. Go."
- If NOT aligned: challenge. "That's not in the plan. The [milestone] deadline is in [N] days. Are you sure?" Accept the user's answer either way.

## Step 4 — Set Session Intent

Record what the user commits to shipping this session.

## Step 5 — Journal the Session Start

Get the current time: `date +%H:%M`

Append to `sessions/YYYY-MM-DD-journal.md` (create if it doesn't exist):

```
[HH:MM] SESSION_START — intent: <session intent from step 4>
```

If there are tasks the user said they'd work on, also journal:

```
[HH:MM] TASK_START <id> — <task name>
```

for each task they're starting.
