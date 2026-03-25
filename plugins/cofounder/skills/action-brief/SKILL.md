---
name: action-brief
description: |
  Create a scoped action brief from the current conversation.
  Use when a conversation produces something actionable that needs to be captured as a brief.
  Invoked by the cofounder agent or other skills when actions emerge.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Action Brief

When any conversation produces something actionable — check-in, sparring, focused work, goal-setting, data analysis — produce an action brief.

## Creating a Brief

Write to `actions/YYYY-MM-DD-<short-name>.md` in the data directory. Scale depth to the task.

### Full Brief (multi-day initiatives)

```
# <Action Name>

## Goal
What this achieves and why it matters. Tie to weekly/monthly/quarterly goals.

## Context
Relevant data, findings, links to data files that informed this decision.

## Target Project
Where this gets executed (if applicable — e.g., the main codebase, a marketing channel, etc.)

## Scope
What's in. What's explicitly out.

## Success Criteria
How do we know it worked?

## Benchmarks
Current numbers to measure against. Link to data source in `data/` if available.
```

### Light Brief (small tasks, focused fixes)

Goal and Scope in a few sentences is enough. The brief should be exactly as detailed as the person executing it needs — no more.

## After Creating a Brief

1. Update `up-next.md` — add to the appropriate section (This Week or Queued) in priority order
2. Tell the user: "Your brief is at `actions/YYYY-MM-DD-name.md`."
3. If relevant, suggest where the user should take this to execute (target project, channel, etc.)

## Brief Lifecycle

- Active briefs in `actions/` = work in progress
- Weekly review: user confirms which are done → log completion in daily log ("Action completed: [name] — [what shipped]") → delete the brief file
- Empty `actions/` directory = everything shipped
