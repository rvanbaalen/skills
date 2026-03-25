---
name: review
description: >
  On-demand progress analysis. Timeline health, estimation accuracy, blocker history,
  anti-pattern report, overrule analysis, and recommendations.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Progress Review

Read all state files before starting: `milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`, `overrules.md`, and all session logs in `sessions/`.

Present the review in these sections:

## 1. Timeline Health

- For each milestone: progress (tasks done/total), days remaining, status.
- Overall burn rate: are we ahead, on track, or behind?
- Call out overdue milestones explicitly.

## 2. Estimation Accuracy

- Read `estimates.md`. Calculate stats:
  - Overall average ratio (actual/estimated)
  - Per-category ratios (frontend, backend, bugfix, etc.)
  - Trend: getting more accurate or less?
- Suggest calibration adjustments: "Your frontend estimates need a 2x buffer. Backend is accurate."
- If fewer than 5 data points: "Still calibrating — not enough data for reliable patterns yet."

## 3. Blocker History

- Active blockers and how long each has been open.
- Resolved blockers and average resolution time.
- Recurring themes: "You've been blocked by [X] 3 times."

## 4. Anti-Pattern Report

- Scan session logs for noted anti-patterns.
- Frequency of each pattern.
- Trends: "Scope creep is increasing — flagged 4 times in the last 2 weeks, up from 1."

## 5. Overrule Analysis

- Read `overrules.md`.
- For `tbd` entries, propose outcome assessments and ask user to confirm.
- Surface patterns: "You've overruled scope creep warnings 3 times — 2 of those cost deadline slippage."
- Overall track record: "Your overrules have been [correct/costly] X% of the time."

## 6. Recommendations

Based on all the above, give concrete recommendations:
- Scope cuts needed?
- Deadlines to renegotiate?
- Approach changes?
- Anti-patterns to watch?
