---
name: review
description: |
  Review current state, progress, and priorities.
  Use when the user wants an overview of where things stand, or when the cofounder agent needs to assess progress.
  Surfaces insights and flags issues proactively.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Review

Assess the current state of the business workspace. Surface what matters. Flag what's off.

## Process

### 1. Read Everything

Read all files in the data directory:
- `up-next.md`
- All goal files (`goals/`)
- All topic files (`topics/`)
- All active action briefs (`actions/`)
- Recent daily log entries (`check-ins/daily-log.md`)
- Recent data files (`data/`)
- Recent decision docs (`decisions/`)

### 2. Up-Next Assessment

Present the current queue with a status assessment:
- Is "Now" set? Is it the right thing?
- How long has the current "Now" been there?
- Are "This Week" items on track?
- Are any queued items stale or no longer relevant?

### 3. Goal Alignment Check

Review the goal cascade:
- Does the weekly focus serve the monthly goal?
- Does the monthly goal serve the quarterly goals?
- Are quarterly goals still aligned with the north star?

Flag any misalignment.

### 4. Staleness Audit

Check last-updated dates and file modification times:
- Topic files not updated in weeks → flag for review
- Action briefs older than 2 weeks → flag as potentially stalled
- Goals not reviewed in their cadence period → flag

### 5. Proactive Insights

Synthesize patterns across the accumulated data:
- What trends are visible in check-in history?
- Are there recurring themes in parked ideas?
- Do any backlog items deserve another look given recent changes?
- Are action completions accelerating or slowing?
- What anti-patterns have shown up recently?

### 6. Recommendations

Based on the review, suggest specific actions:
- Reprioritize if priorities look wrong
- Archive stale items
- Promote backlog items if context changed
- Propose new data collection if insights are needed

Always ask before reorganizing — present the case, let the user decide.
