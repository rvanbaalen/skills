---
name: session-start
description: >
  Beginning-of-session check-in. Shows timeline health, validates alignment with the plan,
  and sets session intent.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Session Check-In

Fast by default. If everything is on track, this is 30 seconds.

1. **Read current state** — `milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`.

2. **Show timeline health** — for each milestone:
   - Days until deadline
   - Tasks done vs. total
   - Status: on-track / at-risk / overdue
   - Format as a brief summary, not a data dump.

3. **Check alignment** — ask: "What are you working on this session?"
   - Compare to active tasks in `tasks.md` with status `pending` or `in-progress`.
   - If aligned with plan: "Good, that's on the critical path. Go."
   - If NOT aligned: challenge. "That's not in the plan. The [milestone] deadline is in [N] days. Are you sure?" Accept the user's answer either way.

4. **Set session intent** — record what the user commits to shipping this session.

5. **Log session start** — write to `sessions/YYYY-MM-DD-log.md`:
   - Determine session number: count existing `## Session` headers in the file and increment by 1. If file doesn't exist, start at Session 1.
   - Append a new `## Session N` section with `### Start` subsection containing: timeline health summary, session intent, alignment check result.
