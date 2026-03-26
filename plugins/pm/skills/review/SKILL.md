---
name: review
description: >
  On-demand progress analysis. Timeline health, estimation accuracy, blocker history,
  anti-pattern report, overrule analysis, and recommendations.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Progress Review

## Step 0 — Verify Context

If you do not already know the project data path, follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run `/pm` to set up." and stop.

Read all state files before starting: `milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`, `overrules.md`, and all journal/session files in `sessions/` (use Glob to find them).

Present the review in these sections:

## 1. Timeline Health

- For each milestone: progress (tasks done/total), days remaining, status.
- Overall burn rate: are we ahead, on track, or behind?
- Call out overdue milestones explicitly.

## 2. Estimation Accuracy

- Read `estimates.md`. Calculate stats:
  - Overall average ratio (actual/estimated) — use `User Est` column for the user's raw accuracy
  - Per-category ratios (frontend, backend, bugfix, etc.)
  - Trend: getting more accurate or less?
  - Split view: "Your raw estimates average <X>x actual. With calibration applied: <Y>x."
- Suggest calibration adjustments: "Your frontend estimates need a 2x buffer. Backend is accurate."
- If fewer than 5 data points: "Still calibrating — not enough data for reliable patterns yet."

## 3. Blocker History

- Active blockers and how long each has been open.
- Resolved blockers and average resolution time.
- Recurring themes: "You've been blocked by [X] 3 times."

## 4. Anti-Pattern Report

- Scan journal files for `ANTI_PATTERN` entries.
- Frequency of each pattern.
- Trends: "Scope creep is increasing — flagged 4 times in the last 2 weeks, up from 1."

## 5. Overrule Analysis

- Read `overrules.md`.
- For `tbd` entries, propose outcome assessments and ask user to confirm.
- Surface patterns: "You've overruled scope creep warnings 3 times — 2 of those cost deadline slippage."
- Overall track record: "Your overrules have been [correct/costly] X% of the time."

## 6. Time Tracking Summary

- Scan journals for `TASK_START` and `TASK_DONE` pairs.
- Show time spent per task, per milestone, per day.
- Identify tasks that took significantly longer than estimated.
- Total hours tracked vs. total hours estimated.

## 7. Recommendations

Based on all the above, give concrete recommendations:
- Scope cuts needed?
- Deadlines to renegotiate?
- Approach changes?
- Anti-patterns to watch?
