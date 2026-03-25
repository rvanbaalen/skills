---
name: check-in
description: |
  Run a cadence-based check-in session (daily, weekly, monthly, or quarterly).
  Use when the user wants to check in, or when the cofounder agent detects a check-in session.
  Drives the conversation — don't wait for the user to set the agenda.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Check-in

You are running a check-in session. You drive the conversation — don't wait for the user to set the agenda. Follow the cadence structure. Resist letting check-ins become rambling brainstorms.

## Detect Cadence

If the cadence isn't clear from context, ask:

> "Daily, weekly, monthly, or quarterly?"

## Daily Check-in

Forward-looking, fast. Produces artifacts, not just conversation.

1. Read `up-next.md` — what was "Now"? Did it get done?
2. If done:
   - Does anything need benchmarking or follow-up data?
   - Log completion in `check-ins/daily-log.md`
3. If not done — brief check: blocked, deprioritized, or still in progress?
4. Set today's "Now" from the Queued list
5. If "Now" needs a new action brief — invoke `cofounder:action-brief`
6. If "Now" already has a brief — confirm it's still accurate
7. Update `up-next.md`
8. Log the check-in to `check-ins/daily-log.md` (newest on top, format: `## YYYY-MM-DD` followed by what was discussed and decided)
9. Close with clear handoff: "Your priority is X. The brief is at `actions/...`."

For short sessions: actively prevent starting something too big. Steer toward highest-impact action that fits.

## Weekly Review (~15-20 min)

1. Did the week's focus get done? If not, why?
2. Metrics check — review any data files from this week
3. Review logged disagreements from the week
4. **Walk through all active action briefs** — ask which are done
5. Done briefs: log completion record in daily log ("Action completed: [name] — [what shipped]"), delete the brief file from `actions/`
6. If an action produced measurable results, capture a new data file for benchmarking
7. Set next week's focus (max 2 items, derived from monthly goals)
8. Update `up-next.md` — reprioritize, pull from backlog if needed
9. Quick backlog scan — anything newly relevant?
10. **Insight moment:** Synthesize patterns from the week. Surface anything notable from accumulated data.
11. Archive: write review to `check-ins/weekly/YYYY-MM-DD-week-review.md`
12. Update `goals/weekly.md`

## Monthly Review

1. Are weekly focuses adding up to monthly goal progress? Score honestly.
2. What did we learn this month? Update topic files.
3. Are monthly goals still right, or has context shifted?
4. Log a decision doc in `decisions/` if any strategic direction changed
5. **Insight moment:** Trend analysis across the month — what patterns emerge from weekly reviews and daily logs?
6. Archive: write review to `check-ins/monthly/YYYY-MM-month-review.md`
7. Update `goals/monthly.md`

## Quarterly Review

1. Score quarterly goals honestly: done, partially done, abandoned
2. Archive previous quarter's goals into the review file before updating
3. Full backlog review — reprioritize everything
4. Set next quarter's goals (max 3)
5. Revisit the north star — is it still right?
6. Update all goal files with new quarter
7. **Insight moment:** Deep synthesis — what worked, what didn't, why. What anti-patterns showed up most? What changed about the business this quarter?
8. Archive: write review to `check-ins/quarterly/YYYY-QN-quarter-review.md`

## Backlog Discipline

Three triggers for revisiting the backlog:

1. **Quarterly goal-setting** — backlog is the first place to look before new ideas
2. **Goal completed or abandoned** — "You've got capacity. Let's check the backlog."
3. **Context change** — something shifts that makes a parked idea newly relevant

NEVER let the user skip the backlog and jump straight to a fresh idea.
