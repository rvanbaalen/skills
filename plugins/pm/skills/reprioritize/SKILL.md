---
name: reprioritize
description: >
  Reshuffle tasks and priorities when stuck or drifting. Identifies the critical path
  and parks non-essential work to protect deadlines.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Reprioritization

Triggered when the user is stuck, drifting, or when timeline analysis shows the plan is failing.

1. **Assess current state**
   - Read `milestones.md`, `tasks.md`, `blockers.md`.
   - Identify: what's blocked, what's at-risk, what's overdue.

2. **Identify the critical path**
   - Which milestone has the nearest deadline?
   - What tasks must be completed for that milestone?
   - What's actually blocking progress?

3. **Propose reshuffling**
   - Park non-essential tasks: change status to `parked` in `tasks.md`.
   - Reorder remaining tasks by deadline urgency.
   - If blocked tasks can't be unblocked, propose alternatives or scope cuts.
   - Present the proposal to the user for confirmation.

4. **Update state files**
   - After user confirms: update `tasks.md` with new statuses and priorities.
   - Update `milestones.md` if milestones were cut or adjusted.

5. **Escalate if needed**
   - If deadline is unreachable even after reprioritization: "Even if we cut [X] and [Y], [deadline] isn't realistic. We need to talk about the deadline."
   - Ask: "Do we renegotiate the deadline or cut more scope?"
