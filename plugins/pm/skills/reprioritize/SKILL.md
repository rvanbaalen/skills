---
name: reprioritize
description: >
  Reshuffle tasks and priorities when stuck or drifting. Identifies the critical path
  and parks non-essential work to protect deadlines.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion
---

# Reprioritization

Triggered when the user is stuck, drifting, or when timeline analysis shows the plan is failing.

## Step 0 — Verify Context

If you do not already know the project data path, the plugin data root is `${CLAUDE_PLUGIN_DATA}`. Follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run `/pm` to set up." and stop.

## Step 1 — Assess Current State

Read `milestones.md`, `tasks.md`, `blockers.md`.

Also read today's journal (`sessions/YYYY-MM-DD-journal.md`) for context on what's been happening this session.

Identify: what's blocked, what's at-risk, what's overdue.

## Step 2 — Identify the Critical Path

- Which milestone has the nearest deadline?
- What tasks must be completed for that milestone?
- What's actually blocking progress?

## Step 3 — Propose Reshuffling

- Park non-essential tasks: propose changing status to `parked` in `tasks.md`.
- Reorder remaining tasks by deadline urgency.
- If blocked tasks can't be unblocked, propose alternatives or scope cuts.
- Present the proposal to the user for confirmation.

## Step 4 — Update State Files

After user confirms: dispatch background Sonnet sub-agents to update files.

Journal every change:
- `[HH:MM] SCOPE_CHANGE — parked <task id>: <reason> (user accepted)`
- `[HH:MM] SCOPE_CHANGE — reprioritized <task id>: moved to <milestone> (user accepted)`
- `[HH:MM] MILESTONE_UPDATE <id> — status: <new status>, reason: reprioritization`

Validate all proposed changes through the self-reflect agent before dispatching writes.

## Step 5 — Escalate if Needed

If deadline is unreachable even after reprioritization: "Even if we cut [X] and [Y], [deadline] isn't realistic. We need to talk about the deadline."

Ask: "Do we renegotiate the deadline or cut more scope?"

Journal the decision: `[HH:MM] SCOPE_CHANGE — <decision> (user accepted)`
