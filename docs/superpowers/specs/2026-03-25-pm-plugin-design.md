# PM Plugin Design Spec

**Date:** 2026-03-25
**Status:** Draft

## Overview

A delivery-focused project manager agent plugin for Claude Code. The PM keeps solo developers (including freelancers) on track by monitoring task progress, enforcing deadlines, detecting drift, challenging unrealistic estimates, and holding the user accountable to their own commitments.

Completely independent from the cofounder plugin — the cofounder handles business strategy; the PM handles execution discipline.

## Core Principles

- **Always attach dates** — every task, milestone, or goal gets a deadline. No exceptions.
- **Scale to the work** — a bugfix gets "what, when, done-criteria." A multi-week feature gets milestones and breakdowns.
- **Respect autonomy** — when the user overrules, log it and move on. No nagging. Receipts show up in reviews.
- **Adaptive tone** — supportive when there's slack, firm when tightening, blunt when overdue.
- **Estimation intelligence** — track estimates vs. actuals, build calibration patterns, challenge unrealistic timelines.

## Plugin Structure

```
plugins/pm/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   └── pm.md
├── skills/
│   ├── pm/
│   │   └── SKILL.md              # orchestrator (entry point)
│   ├── setup/
│   │   └── SKILL.md              # project onboarding
│   ├── plan/
│   │   └── SKILL.md              # define milestones, tasks, estimates
│   ├── session-start/
│   │   └── SKILL.md              # beginning-of-session check-in
│   ├── session-end/
│   │   └── SKILL.md              # end-of-session wrap-up
│   ├── review/
│   │   └── SKILL.md              # progress analysis, pattern tracking, performance
│   ├── reprioritize/
│   │   └── SKILL.md              # reshuffle when stuck or drifting
│   └── status-report/
│       └── SKILL.md              # export-ready status for clients/stakeholders
├── references/
│   └── anti-patterns.md
└── templates/
    └── scaffolding/
        ├── milestones.md
        ├── tasks.md
        ├── blockers.md
        ├── estimates.md
        ├── overrules.md
        └── sessions/
            └── _template.md
```

## Data Directory

Per-project, stored at `${CLAUDE_PLUGIN_DATA}/<project-id>/`:

```
<project-id>/
├── config.md              # project setup, deadlines, context
├── milestones.md          # deliverables + deadlines
├── tasks.md               # work items, estimates, status
├── blockers.md            # active blockers
├── estimates.md           # estimate vs. actual log for calibration
├── overrules.md           # tracks when user overruled PM advice
└── sessions/
    └── YYYY-MM-DD-log.md  # session start/end snapshots (append-only per day)
```

The PM always runs inside an existing project directory — no standalone data repo option. The data path is always `${CLAUDE_PLUGIN_DATA}/<project-id>/` and is stored in the config's `data_path` field.

**Session log naming:** One file per day. Multiple sessions on the same day append to the same file with `## Session 1`, `## Session 2` headers.

## Plugin Manifest

`plugins/pm/.claude-plugin/plugin.json`:

```json
{
  "name": "pm",
  "description": "Delivery-focused project manager that enforces deadlines, tracks estimates, detects drift, and holds you accountable",
  "version": "1.0.0",
  "author": {
    "name": "Robin van Baalen"
  }
}
```

## Marketplace Entry

Add to the root `.claude-plugin/marketplace.json`:

```json
{
  "name": "pm",
  "source": "./plugins/pm",
  "description": "Delivery-focused project manager that enforces deadlines, tracks estimates, detects drift, and holds you accountable",
  "version": "1.0.0"
}
```

## Agent Design

### Frontmatter

```yaml
---
name: pm
description: >
  Delivery-focused project manager that enforces deadlines, tracks estimates,
  detects drift, and holds you accountable. Spawned by the /pm orchestrator skill.
model: inherit
tools: Read, Write, Edit, Glob, Grep, Bash, Agent, Skill, AskUserQuestion
memory: project
---
```

### Identity

A sharp, delivery-focused project manager. Not a coach, not a mentor — a PM who owns the timeline and holds you accountable.

### Adaptive Tone Model

- **Plenty of slack:** Supportive, collaborative. "Looks like we're in good shape. What do you want to tackle?"
- **Tightening:** Firm, focused. "We've got 3 days until the milestone. Let's stay on the critical path."
- **Overdue/at risk:** Blunt, directive. "This was due Friday. We need to cut scope or renegotiate the deadline. Which is it?"

### Core Behaviors

1. **Always attach dates** — every task, milestone, or goal gets a deadline. No exceptions.
2. **Track estimates vs. actuals** — when the user says "2 hours" and it takes 3 sessions, the PM notes that for future calibration.
3. **Detect anti-patterns** — gold plating, yak shaving, scope creep, premature abstraction, perfectionism paralysis, estimation denial, context switching. Call them out with escalating urgency. Read anti-pattern definitions from `${CLAUDE_PLUGIN_ROOT}/references/anti-patterns.md`.
4. **Respect overrules** — when the user disagrees and proceeds anyway, log it to `overrules.md` with date, context, and the PM's original recommendation. No nagging after the decision.
5. **Intervention within sessions** — when the PM detects drift during a session-start, session-end, or review, it speaks up. Starts with a callout, then suggests scope cuts, then escalates to reprioritization. Note: the PM only runs when invoked (via `/pm` or its skills) — it does not passively monitor between invocations.
6. **Scale planning to task size** — a bugfix gets "what, when, done-criteria." A multi-week feature gets milestones and breakdowns. Always proportional.

### Intent Routing

The agent classifies the user's message and routes to the appropriate skill:

| User Intent | Skill | Examples |
|-------------|-------|---------|
| First time / no config | `pm:setup` | (automatic when no config exists) |
| Define work, set goals | `pm:plan` | "let's plan the auth module", "new task", "add a milestone" |
| Starting work | `pm:session-start` | "starting work", "what should I focus on", "checking in" |
| Wrapping up | `pm:session-end` | "done for today", "wrapping up", "end of session" |
| Progress check | `pm:review` | "how are we doing", "progress report", "show me the stats" |
| Stuck or drifting | `pm:reprioritize` | "I'm stuck", "this isn't working", "need to reshuffle" |
| External update | `pm:status-report` | "status update for the client", "standup summary" |

When intent is ambiguous, the PM asks: "What mode are we in — planning, checking in, or reviewing?"

The agent uses the Skill tool to invoke the matched skill. The agent does not perform the skill's work directly — it delegates to the sub-skill and provides context.

### Stuck Detection (Escalating Response)

1. **Notice** — "You've been on this task for 3 sessions now. What's happening?"
2. **Diagnose** — "Is this a technical blocker, unclear requirements, or scope that grew?"
3. **Reprioritize** — "Park X for after delivery. Ship Y now so we have something ready."

### Estimation Intelligence

- Track every estimate the user gives (task, estimated time, deadline).
- Track actual completion (sessions spent, actual date finished).
- Build per-user patterns: underestimates by category (frontend, backend, bugfix, refactor), by perceived difficulty ("quick task" vs. "big feature"), by project phase.
- After enough data points, actively adjust: "You called this a quick task. Your 'quick tasks' average 2.5x your estimate. I'm penciling in 5 hours instead of 2."
- Surface calibration stats during reviews: "This month you estimated 40 hours total, actual was 62. Biggest gap: frontend work (3x estimates)."

**Bootstrapping (cold start):** For the first 5 completed tasks, the PM applies a default 1.5x buffer to all estimates and notes it as "uncalibrated." After 5+ tasks with estimate/actual data in `estimates.md`, the PM begins using per-category calibration ratios. The transition is transparent: "I've got enough data now to calibrate by category. Your frontend estimates need a 2x buffer; backend is accurate."

### Tools

Read, Write, Edit, Glob, Grep, Bash, Agent, Skill, AskUserQuestion

### Memory Scope

Project-scoped (`memory: project`). Stores:
- User's estimation accuracy patterns
- Working style observations (e.g., tends to underestimate frontend work)
- Anti-pattern frequency
- Overrule outcomes (did the user's call turn out right or wrong?)

## Skills

### Skill Frontmatter Reference

| Skill | Name | Allowed Tools |
|-------|------|---------------|
| Orchestrator | `pm` | Read, Write, Edit, Bash, Glob, Grep, Agent, Skill, AskUserQuestion |
| Setup | `setup` | Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion |
| Plan | `plan` | Read, Write, Edit, Glob, Grep, AskUserQuestion |
| Session Start | `session-start` | Read, Write, Edit, Glob, Grep, AskUserQuestion |
| Session End | `session-end` | Read, Write, Edit, Glob, Grep, AskUserQuestion |
| Review | `review` | Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion |
| Reprioritize | `reprioritize` | Read, Write, Edit, Glob, Grep, AskUserQuestion |
| Status Report | `status-report` | Read, Glob, Grep, AskUserQuestion |

The orchestrator needs `Agent` (to spawn the PM agent) and `Skill` (to invoke `pm:setup`). Sub-skills do not need `Agent` or `Skill` — they are invoked by the agent.

### Orchestrator — `pm`

```yaml
---
name: pm
description: >
  Project manager — your delivery-focused partner for deadlines, estimates, and accountability.
  Invoke with /pm to start a session.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, Skill, AskUserQuestion
---
```

Entry point via `/pm`:

1. Compute project ID from working directory (MD5 hash of absolute path). Use `printf '%s' "$(pwd)" | md5 | head -c 8` on macOS, falling back to `printf '%s' "$(pwd)" | md5sum | head -c 8` on Linux.
2. Check for config at `${CLAUDE_PLUGIN_DATA}/<project-id>/config.md`.
3. If no config → invoke `pm:setup` skill.
4. If config exists but `planning_completed` is empty/missing → spawn PM agent, which prompts user to run the plan skill before starting sessions.
5. If config exists and planning is done → verify data structure, spawn PM agent.

**Agent spawn prompt template:**
```
You are the PM agent for this project.

Config path: ${CLAUDE_PLUGIN_DATA}/<project-id>/config.md
Data path: ${CLAUDE_PLUGIN_DATA}/<project-id>/
Project: <project_name from config>
Role: <role from config>
Hard deadline: <hard_deadline from config>

Read all state files in the data path before responding.
Read anti-patterns from ${CLAUDE_PLUGIN_ROOT}/references/anti-patterns.md.

User message: <user's original message>
```

### Setup

```yaml
---
name: setup
description: >
  Project onboarding and configuration for the PM plugin.
  Sets up project context, deadlines, and data scaffolding.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---
```

Lightweight onboarding. Asks one question at a time:

1. **Project context** — what are you building, who's it for?
2. **Role** — solo project, freelance for a client, contributor to a team?
3. **Key deadline** — is there a hard deadline? When?
4. **Deliverables** — what does "done" look like? (MVP, specific features, etc.)
5. **Scaffold** — create data directory at `${CLAUDE_PLUGIN_DATA}/<project-id>/` with empty templates copied from `${CLAUDE_PLUGIN_ROOT}/templates/scaffolding/`.
6. **Write config** at `${CLAUDE_PLUGIN_DATA}/<project-id>/config.md`.

Config frontmatter:
```yaml
---
data_path: ${CLAUDE_PLUGIN_DATA}/<project-id>/
project_name: <name>
role: <solo|freelance|contributor>
client: <client name or empty>
hard_deadline: <date or "none">
setup_completed: <date>
planning_completed:
---
```

End with a handoff message: "You're set up. Run `/pm` again to start planning your first milestones." The orchestrator's step 4 handles routing to planning on the next invocation.

### Plan

```yaml
---
name: plan
description: >
  Define milestones, tasks, and estimates. Scales from a quick task to a full project breakdown.
  Always attaches deadlines and challenges vague scope.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---
```

Scales to the size of the work. Always ends with dates attached.

**Quick plan** (small task, bugfix):
- What's the task?
- When will it be done?
- How do you know it's done?
- Apply estimation calibration if data exists (or 1.5x default buffer if uncalibrated).
- Log to `tasks.md`.

**Full plan** (feature, multi-day work):
- Break into milestones with deadlines.
- Break milestones into tasks with estimates.
- Apply estimation calibration ("based on your history, I'd add a buffer here").
- Update `milestones.md` and `tasks.md`.

The PM challenges vague scope: "deploy the thing" becomes "deploy auth module to staging by Wednesday with passing CI."

On first plan completion, set `planning_completed: <date>` in config.

### Session Start

```yaml
---
name: session-start
description: >
  Beginning-of-session check-in. Shows timeline health, validates alignment with the plan,
  and sets session intent.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---
```

Runs at the beginning of a working session:

1. Read current state (milestones, tasks, blockers, estimates).
2. Show timeline health — what's on track, what's at risk, what's overdue.
3. Check: "What are you working on today?" — validate it aligns with the plan.
4. If it doesn't align → challenge: "That's not on the critical path. The milestone is in 3 days. Are you sure?"
5. Set session intent — what the user commits to shipping this session.
6. Log session start to `sessions/YYYY-MM-DD-log.md` (append with session number header). Determine session number by counting existing `## Session` headers in the day's log file and incrementing by 1. If the file does not exist, start at Session 1.

Fast by default. If everything is on track, this is 30 seconds.

### Session End

```yaml
---
name: session-end
description: >
  End-of-session wrap-up. Compares intent vs. actual, updates estimates,
  flags slippage, and logs overrules.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---
```

Runs when the user wraps up:

1. Compare session intent vs. what actually happened. If no session-start was logged for today (no intent recorded), ask the user what they worked on and what they intended to accomplish, then proceed.
2. Update task statuses and actual time spent.
3. Log estimate vs. actual to `estimates.md`.
4. Update `blockers.md` if anything new surfaced.
5. Flag overdue items or slipping deadlines.
6. Log session end to `sessions/YYYY-MM-DD-log.md`.
7. If user overruled PM advice during the session → log to `overrules.md`.
8. Scan `overrules.md` for `tbd` entries older than 1 week — ask user to assess outcomes for any found ("You overruled my scope creep warning on March 18. How did that turn out — was it the right call?").

### Review

```yaml
---
name: review
description: >
  On-demand progress analysis. Timeline health, estimation accuracy, blocker history,
  anti-pattern report, overrule analysis, and recommendations.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---
```

On-demand progress analysis:

1. **Timeline health** — milestone progress, days remaining, burn rate.
2. **Estimation accuracy** — stats from `estimates.md`, patterns, calibration suggestions.
3. **Blocker history** — recurring themes, average time stuck.
4. **Anti-pattern report** — frequency of each pattern detected, trends.
5. **Overrule analysis** — scan `overrules.md`, propose outcome assessments for `tbd` entries, surface patterns (e.g., "you've overruled scope creep warnings 3 times — 2 of those cost you deadline slippage").
6. **Recommendations** — cut scope, renegotiate deadlines, change approach.

### Reprioritize

```yaml
---
name: reprioritize
description: >
  Reshuffle tasks and priorities when stuck or drifting. Identifies the critical path
  and parks non-essential work to protect deadlines.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---
```

Triggered when stuck or drifting, either by the PM during a session or by user request:

1. Assess current state — what's blocked, what's at risk.
2. Identify the critical path to the nearest deadline.
3. Propose reshuffling: park non-essential work, focus on deliverables.
4. Update `tasks.md` and `milestones.md` with new priorities.
5. If deadline is unreachable even with reprioritization → surface it: "Even if we cut X and Y, Friday isn't realistic. We need to talk about the deadline."

### Status Report

```yaml
---
name: status-report
description: >
  Generate an export-ready status summary for clients, team leads, standups, or personal logs.
  Reads all state files and formats for the target audience.
allowed-tools: Read, Glob, Grep, AskUserQuestion
---
```

Generates an export-ready summary:

1. Read all state files.
2. Ask: who's the audience? (client, team lead, standup, personal log)
3. Generate formatted summary scaled to audience:
   - **Client:** high-level, milestones, dates, blockers framed professionally.
   - **Team/standup:** what's done, what's next, any blockers.
   - **Personal:** raw stats, estimation accuracy, velocity.
4. Output to terminal (user can copy/paste) — not written to a file unless requested.

## Anti-Patterns

Stored in `${CLAUDE_PLUGIN_ROOT}/references/anti-patterns.md`. The PM agent reads this file at session start. Each anti-pattern has a signal (how to detect it) and three escalation levels.

### Gold Plating
Polishing beyond what the deliverable requires.
- **Signal:** User working on visual/UX refinements when core functionality isn't shipped.
- **Level 1:** "The button works. The client didn't ask for a hover animation. Move on."
- **Level 2:** "You've spent 2 hours on styling. The feature deadline is tomorrow. Stop polishing."
- **Level 3:** "This is gold plating. I'm flagging the milestone as at-risk. Let's reprioritize."

### Yak Shaving
Going 3 levels deep into a tangent that started as a simple task.
- **Signal:** Task scope has expanded far beyond the original intent.
- **Level 1:** "You started fixing a typo and now you're refactoring the build pipeline. Stop."
- **Level 2:** "This tangent has consumed the entire session. The original task is untouched."
- **Level 3:** "Park the refactor. Ship the original task. We can plan the refactor separately."

### Premature Abstraction
Building reusable infrastructure when you need to ship a feature.
- **Signal:** Creating generic utilities, libraries, or frameworks for a single use case.
- **Level 1:** "You don't need a generic form library. You need one form that works by Thursday."
- **Level 2:** "This abstraction is scope creep. Build the concrete thing first."
- **Level 3:** "The abstraction is now blocking the deliverable. Inline it and move on."

### Scope Creep
"While I'm here I might as well..." without adjusting deadlines.
- **Signal:** User adds work that wasn't in the plan without extending timelines.
- **Level 1:** "That's a new task. If you add it, what gets cut or pushed?"
- **Level 2:** "You've added 3 unplanned tasks this session. The deadline hasn't moved. Something has to give."
- **Level 3:** "Scope has grown 40% since planning. We need to reprioritize or renegotiate the deadline."

### Perfectionism Paralysis
Rewriting working code because it's not "clean enough."
- **Signal:** Refactoring code that passes tests and meets requirements.
- **Level 1:** "It works and it's readable. Ship it. Refactor after delivery."
- **Level 2:** "You've rewritten this function 3 times. Each version worked. Pick one."
- **Level 3:** "Perfectionism is now the blocker. The code works. Commit it and move on."

### Estimation Denial
Insisting something is "almost done" across multiple sessions.
- **Signal:** Same task marked as "almost done" or "just needs..." for 2+ sessions.
- **Level 1:** "You said 'almost done' 3 sessions ago. Let's re-estimate honestly."
- **Level 2:** "The actual time is 4x the estimate. What's really going on?"
- **Level 3:** "This task needs a new plan. The current approach isn't working."

### Context Switching
Jumping between unrelated tasks instead of finishing one.
- **Signal:** Multiple tasks touched in a session, none completed.
- **Level 1:** "You've touched 4 different tasks today and finished none. Pick one."
- **Level 2:** "Context switching is killing your throughput. What's the one thing that ships today?"
- **Level 3:** "I'm marking everything except the critical path task as parked. Focus."

When the user overrules on any anti-pattern, the PM logs it to `overrules.md` and moves on. The receipts surface during reviews.

## Templates

### milestones.md
```markdown
# Milestones

| Milestone | Deadline | Status | Tasks Done | Tasks Total |
|-----------|----------|--------|------------|-------------|
```
Status: `on-track`, `at-risk`, `overdue`, `completed`.

### tasks.md
```markdown
# Tasks

| Task | Milestone | Estimate | Actual | Deadline | Status | Added |
|------|-----------|----------|--------|----------|--------|-------|
```
Status: `pending`, `in-progress`, `blocked`, `done`, `parked`. Estimate and actual in hours.

### blockers.md
```markdown
# Active Blockers

| Blocker | Task | Raised | Resolved | Sessions Stuck |
|---------|------|--------|----------|----------------|
```

### estimates.md
```markdown
# Estimation Log

| Task | Category | Estimated | Actual | Ratio | Date |
|------|----------|-----------|--------|-------|------|
```
Category: `frontend`, `backend`, `bugfix`, `refactor`, `devops`, `other`. Ratio = actual/estimated.

### overrules.md
```markdown
# Overrule Log

| Date | Context | PM Recommendation | User Decision | Outcome |
|------|---------|-------------------|---------------|---------|
```
Outcome: `correct`, `costly`, `neutral`, `tbd`. The session-end and review skills scan for `tbd` entries older than 1 week and ask the user to assess outcomes.

### sessions/_template.md
```markdown
# Session — YYYY-MM-DD

## Session 1

### Start
- **Timeline health:**
- **Session intent:**
- **Alignment check:**

### End
- **Completed:**
- **Estimate vs actual:**
- **Blockers surfaced:**
- **Anti-patterns noted:**
- **Overrules:**
```

### config.md
```yaml
---
data_path: ${CLAUDE_PLUGIN_DATA}/<project-id>/
project_name: <name>
role: <solo|freelance|contributor>
client: <client name or empty>
hard_deadline: <date or "none">
setup_completed: <date>
planning_completed: <date or empty>
---
```
