---
name: session-end
description: >
  End-of-session wrap-up. Compares intent vs. actual, updates estimates,
  flags slippage, and logs overrules.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Session Wrap-Up

1. **Compare intent vs. actual**
   - Read today's session log to find session intent.
   - If no session-start was logged today (no intent recorded), ask: "What did you work on this session, and what did you intend to accomplish?" Then proceed with the comparison.
   - Ask: "Did you ship what you planned? What got done, what didn't?"

2. **Update task statuses** — mark completed tasks as `done` in `tasks.md`. Update `in-progress` for ongoing work.

3. **Log estimates** — for each completed task, add a row to `estimates.md`: task name, category, estimated hours, actual hours, ratio (actual/estimated), today's date.

4. **Update blockers** — ask: "Any blockers?" If yes, add to `blockers.md`. If existing blockers were resolved, update `Resolved` date and clear from active list.

5. **Flag slippage** — check `milestones.md`. For any milestone where deadline is approaching and tasks are behind, update status to `at-risk`. For past-deadline milestones, update to `overdue`. Alert the user.

6. **Log session end** — append `### End` subsection to today's session log: what was completed, estimate vs. actual, blockers surfaced, anti-patterns noted, overrules.

7. **Log overrules** — if the user overruled PM advice during this session (anti-pattern callouts, scope challenges, etc.), add row to `overrules.md` with date, context, PM recommendation, user decision, outcome `tbd`.

8. **Scan overrules** — read `overrules.md`. For any entry with outcome `tbd` that is older than 1 week, ask the user to assess: "You overruled my [type] warning on [date]. How did that turn out — was it the right call?" Update outcome to `correct`, `costly`, or `neutral`.
