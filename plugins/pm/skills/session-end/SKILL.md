---
name: session-end
description: >
  End-of-session wrap-up. Reads the journal to reconcile structured files,
  computes actual durations from timestamps, and dispatches background
  sub-agents for file updates.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion
---

# Session Wrap-Up

Session-end is a **reconciliation step**, not a reconstruction step. The journal has everything that happened. Your job is to review it, fill gaps, and ensure structured files are in sync.

## Step 0 — Verify Context

If you do not already know the project data path, follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run `/pm` to set up." and stop.

## Step 1 — Read Today's Journal

Read `sessions/YYYY-MM-DD-journal.md`.

**If the journal doesn't exist or is empty:** No session was formally tracked today. Ask the user: "I don't have a record of today's session. What did you work on, and what did you accomplish?" Then manually create journal entries based on their answers before proceeding with reconciliation.

**If the journal exists:** Parse all entries. Build a summary of:
- Tasks started (TASK_START entries)
- Tasks completed (TASK_DONE entries)
- Tasks started but not completed (TASK_START without matching TASK_DONE)
- Estimates given (ESTIMATE entries)
- Blockers raised/resolved
- Scope changes
- Anti-patterns noted
- Overrules

## Step 2 — Fill Gaps

For each TASK_START without a matching TASK_DONE, ask the user: "You started <task> but I don't have a completion record. Is it done, still in progress, or blocked?"

Based on answers, append the appropriate journal entries (TASK_DONE, BLOCKER, etc.).

## Step 3 — Ask About Unlisted Work

Ask: "Did you work on anything else that isn't in the journal?" If yes, create journal entries for those tasks.

## Step 4 — Ask About Blockers

Ask: "Any blockers to flag?" If yes, append BLOCKER entries to the journal.

## Step 5 — Dispatch Background Sub-Agents

Now that the journal is complete, dispatch Sonnet sub-agents to update structured files. Use the Agent tool with `model: sonnet` and `run_in_background: true` for each.

**Sub-agent 1: Task Reconciliation**

Prompt:
> "Read `<data-path>/tasks.md`. Make these status updates:
> - Set <list of task IDs> to `done`
> - Set <list of task IDs> to `in-progress`
> - Set <list of task IDs> to `blocked` (if any)
> Preserve all other columns. Write the updated file."

**Sub-agent 2: Estimates Logging**

Prompt:
> "Read `<data-path>/estimates.md`. Append these rows:
> | <task> | <category> | <calibrated est> | <user est> | <actual from timestamps> | <ratio> | <today's date> |
> (one row per completed task that has both a TASK_START and TASK_DONE in the journal)
> Preserve all existing rows. Write the updated file."

**Sub-agent 3: Blockers and Overrules Sync**

Prompt:
> "Read `<data-path>/blockers.md`. Add these new blockers: <list>.
> Resolve these blockers (set Resolved date to today): <list>.
> Then read `<data-path>/overrules.md`. Add these new overrules: <list>.
> Write both updated files."

**Sub-agent 4: Milestone Recalculation**

Prompt:
> "Read `<data-path>/tasks.md` (after sub-agent 1 completes).
> Count done/total tasks per milestone.
> Read `<data-path>/milestones.md`. Update:
> - Tasks Done and Tasks Total columns
> - Status: set to `at-risk` if deadline is within 2 days and < 80% done
> - Status: set to `overdue` if deadline has passed and not 100% done
> - Status: set to `completed` if 100% done
> Write the updated file."

Note: Sub-agent 4 depends on sub-agent 1. Either run it after sub-agent 1 completes, or include the task status changes in its prompt so it can calculate independently.

**Sub-agent 5: Journal Finalization**

Prompt:
> "Read `<data-path>/sessions/YYYY-MM-DD-journal.md`. Append this entry:
> `[HH:MM] SESSION_END — completed: <list>. Incomplete: <list>.`
> Write the updated file."

## Step 6 — Flag Slippage

After milestone recalculation, check for at-risk or overdue milestones. Alert the user:
- At-risk: "Milestone <name> is due in <N> days with <X>% of tasks remaining. Stay focused."
- Overdue: "Milestone <name> was due <date>. We need to cut scope or renegotiate."

## Step 7 — Scan Overrules

Read `overrules.md`. For any entry with outcome `tbd` that is older than 1 week, ask the user: "You overruled my [type] warning on [date]. How did that turn out — was it the right call?" Update outcome to `correct`, `costly`, or `neutral`.

## Step 8 — Summary

Give the user a brief summary:
- Tasks completed today
- Tasks still in progress
- Estimation accuracy for today's work (if any tasks completed with estimates)
- Active blockers
- Next session focus suggestion
