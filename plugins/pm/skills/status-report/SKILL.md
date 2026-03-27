---
name: status-report
description: >
  Generate an export-ready status summary for clients, team leads, standups, or personal logs.
  Reads all state files and journals, formats for the target audience.
allowed-tools: Read, Glob, Grep, AskUserQuestion
---

# Status Report

Generate a formatted status update ready to copy/paste.

## Step 0 — Verify Context

If you do not already know the project data path, the plugin data root is `${CLAUDE_PLUGIN_DATA}`. Follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run `/pm` to set up." and stop.

## Step 1 — Read All State Files

Read `milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`, and recent journal files from `sessions/` (use Glob to find them). Journals provide richer context than structured files alone — use them for "what happened" narratives.

## Step 2 — Ask Audience

"Who's this for?"
- **A)** Client
- **B)** Team lead / standup
- **C)** Personal log

## Step 3 — Generate Report by Audience

**Client format:**
- High-level, professional tone
- Milestone status and dates
- What was delivered since last update (derive from journal TASK_DONE entries)
- What's coming next
- Blockers framed as risks (not complaints)
- No internal metrics or anti-pattern data

**Team/standup format:**
- What's done since last standup (derive from journal TASK_DONE entries with timestamps)
- What's in progress (derive from TASK_START entries without TASK_DONE)
- Blockers (direct, technical)
- ETA for current work

**Personal format:**
- Raw stats: tasks completed, hours estimated vs. actual
- Estimation accuracy by category (from `estimates.md`, split by User Est and calibrated)
- Time tracking: hours per day, per milestone (from journal timestamps)
- Velocity trends
- Anti-pattern frequency (from journal ANTI_PATTERN entries)
- Overrule track record

## Step 4 — Output

Output to terminal — formatted for easy copy/paste. Do NOT write to a file unless the user explicitly asks.
