# PM Plugin — Memory Persistence & Reliability Redesign

**Date:** 2026-03-25
**Status:** Approved
**Scope:** plugins/pm/

---

## Problem Statement

The PM plugin writes structured project data (tasks, milestones, estimates, blockers) during sessions, but fails to maintain continuity across sessions due to three root causes:

1. **Skills run without context** — Individual sub-skills (session-start, session-end, plan, etc.) can be invoked without going through the orchestrator. When this happens, they have no data path, no project hash, no context. They fly blind.

2. **No session journaling** — Even when the PM runs correctly, no session logs are written. The `sessions/` directory stays empty. When context is cleared, all knowledge of what happened during the session is lost. Session-end tries to reconstruct from conversation memory, which doesn't survive context clears.

3. **PM guesses estimates** — The PM assigns its own time estimates instead of asking the user first, breaking the estimation intelligence system that depends on tracking the user's estimation accuracy.

## Design

### 1. Context Gate

**Every sub-skill gets a mandatory Step 0** that verifies project context is loaded before doing anything else.

The bootstrap logic lives in a single shared reference file (`references/context-bootstrap.md`) rather than being duplicated across skills. Each skill's preamble is minimal:

> **Step 0 — Verify context.** If you do not already know the project data path, follow the bootstrap procedure in `${CLAUDE_PLUGIN_ROOT}/references/context-bootstrap.md`. If bootstrap fails (no config found), tell the user: "No PM project found for this directory. Run /pm to set up." and stop.

The bootstrap procedure:
1. Compute project hash: `printf '%s' "$(pwd)" | md5 | head -c 8` (Linux fallback: `md5sum`)
2. Resolve data path: `${CLAUDE_PLUGIN_DATA}/<hash>/`
3. Read `config.md` — verify it exists and has valid frontmatter
4. Check `pm_version` against plugin version — trigger migration if mismatched (see Section 6)
5. Verify expected files exist (`milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`, `overrules.md`, `sessions/`)
6. Read all project files to ground the PM agent

The PM agent's startup sequence also references this bootstrap, replacing its current ad-hoc file reading. Single source of truth.

### 2. Write-Through Journal

A running journal file that captures PM-relevant events in real-time as they happen during a session — not deferred to session-end.

**File location:** `sessions/YYYY-MM-DD-journal.md`

**Event types with machine-parseable prefixes:**

| Event | Format |
|-------|--------|
| Session started | `[HH:MM] SESSION_START — intent: <what user plans to do>` |
| Task started | `[HH:MM] TASK_START <id> — <task name>` |
| Task completed | `[HH:MM] TASK_DONE <id> — <task name>` |
| User estimate | `[HH:MM] ESTIMATE <id> — user: <duration>, calibrated: <duration> (<reason>)` |
| Blocker raised | `[HH:MM] BLOCKER — <description>, blocks: <task id>` |
| Blocker resolved | `[HH:MM] BLOCKER_RESOLVED — <description>` |
| Scope change | `[HH:MM] SCOPE_CHANGE — <what changed> (user accepted/rejected)` |
| Anti-pattern detected | `[HH:MM] ANTI_PATTERN — <pattern_name>: <description>` |
| Overrule | `[HH:MM] OVERRULE — PM recommended: <X>, user decided: <Y>` |
| Session ended | `[HH:MM] SESSION_END — completed: <list>. Incomplete: <list>.` |

**Rules:**
- Append-only during the session. Never rewrite earlier entries.
- Every sub-skill that changes state writes to the journal.
- Timestamps are wall-clock, taken from the system at the moment of the event. This enables accurate duration tracking.
- Machine-parseable prefixes allow programmatic scanning during reviews and estimation calibration.

The journal is the raw event stream. The structured files (tasks.md, milestones.md, etc.) remain the system of record. Journal entries drive immediate updates to structured files — but even if a structured file update is missed, the journal preserves the data for later reconciliation.

### 3. Session-End as Background Reconciliation

Session-end becomes a journal-based reconciliation step. The PM agent handles thinking and user interaction; background Sonnet sub-agents handle file writes.

**Flow:**

1. **PM agent reads today's journal** — analyzes what happened, identifies gaps, asks the user clarifying questions (e.g., "T7 was started but not completed — what's the status?")

2. **PM agent dispatches background sub-agents** (model: sonnet) with explicit file-update instructions:
   - **Sub-agent 1: Task reconciliation** — update `tasks.md` statuses based on journal events
   - **Sub-agent 2: Estimates logging** — append rows to `estimates.md` with computed actual durations from journal timestamps
   - **Sub-agent 3: Blockers/overrules sync** — sync `blockers.md` and `overrules.md` with journal events
   - **Sub-agent 4: Milestone recalculation** — recount done/total per milestone, update statuses in `milestones.md`
   - **Sub-agent 5: Journal finalization** — append `SESSION_END` summary block to journal

3. Sub-agents run in parallel, in the background. The user isn't blocked.

**This pattern extends beyond session-end.** Any skill that changes state can dispatch a Sonnet sub-agent for the file write. The PM stays focused on the conversation.

**Sub-agent failure handling:** If a background sub-agent fails (file write error, unexpected format), it reports the failure. The PM agent logs the failure to the journal (`[HH:MM] WRITE_FAILED — <file>: <reason>`) and retries once. If it fails again, the PM tells the user: "Failed to update <file>. You may need to check it manually." The journal still has the data, so nothing is lost — just not yet reconciled.

### 4. Self-Reflect Validation Agent

A dedicated validation agent that checks proposed PM actions against a rule set before file writes execute. Prevents the PM from taking shortcuts.

**Flow:**
```
PM agent decides action
    -> Self-reflect agent validates (sonnet, background)
        -> If valid: dispatch file-update sub-agents
        -> If invalid: flag back to PM agent with reason
```

**Validation rules:**

| Rule | Violation example |
|------|------------------|
| Estimates must come from the user | PM wrote `ESTIMATE T4 — 30m` without a user message containing that number |
| Task completion must be confirmed by user | PM marking `TASK_DONE` without user saying it's done |
| Scope changes require user consent | PM adding/removing tasks without user agreement |
| Deadlines require user input | PM assigning a deadline the user never agreed to |
| Actuals computed from timestamps, not guessed | `estimates.md` row with actual duration that doesn't match journal timestamps |

**Implementation:** The self-reflect agent receives:
- The proposed journal entry or file update
- The relevant portion of the conversation (what the user actually said)
- The rule set

Returns `VALID` (proceed) or `INVALID: <reason>` (PM corrects course).

The self-reflect agent is Sonnet, fast, narrowly scoped. It pattern-matches proposed actions against rules. It's a guardrail, not a second PM.

The validation rules live in `references/self-reflect-rules.md` so they can be updated without modifying the agent definition.

### 5. Estimation Protocol Fix

A strict ask-first protocol, enforced by the self-reflect agent.

**Flow for every new task:**

1. PM asks the user: "How long do you think T4 (TeamListItem.js) will take?"
2. User answers: "30 minutes"
3. PM applies calibration (if enough data in `estimates.md`):
   - Cold start (< 5 completed tasks): "I'm adding a 1.5x buffer — penciling in 45m."
   - Calibrated (5+ tasks): "Your frontend estimates run 2x historically. I'd suggest 60m."
4. Journal entry captures both: `[12:45] ESTIMATE T4 — user: 30m, calibrated: 45m (1.5x cold-start buffer)`
5. The user's raw estimate goes in `tasks.md`. The calibrated number is used for timeline planning. The raw number is what gets compared to actuals for accuracy tracking.

**Changes to `estimates.md`:** Adds a `User Est` column. This enables the review skill to show split accuracy: "Your raw estimates average 0.6x actual (you underestimate by 40%). With calibration, we're at 0.95x."

### 6. Version Migration

A versioned migration system so plugin upgrades don't break existing project data.

**Mechanism:**

1. `config.md` gets a `pm_version` field in its frontmatter. Existing configs without this field are implicitly `1.0.0`.
2. `plugin.json` is the source of truth for the current plugin version.
3. The context bootstrap (Section 1) compares versions on every session. If they differ, migration runs before proceeding.
4. `references/migrations.md` contains the ordered migration changelog.

**Migration changelog format:**
```
## 1.0.0 -> 2.0.0

### File changes
- Added: sessions/YYYY-MM-DD-journal.md (created automatically during sessions)
- Modified: estimates.md — added `User Est` column

### Config changes
- Added: pm_version field to frontmatter

### Migration steps
1. Add pm_version: 2.0.0 to config.md frontmatter
2. Read estimates.md, insert empty User Est column for existing rows
3. ...
```

**Constraints:**
- Migrations are idempotent — running the same migration twice doesn't break anything
- Migrations are forward-only — no downgrades
- The migrations file is append-only — each version adds a section, old sections remain so projects can skip versions (1.0.0 -> 3.0.0 runs both migration blocks)
- Migrations execute via background Sonnet sub-agent (mechanical file transforms)
- User sees: "PM plugin updated to v2.0.0 — migrated your project data."

## File Changes Summary

| File | Change |
|------|--------|
| `references/context-bootstrap.md` | **New.** Bootstrap procedure: hash, data path, config, version check, file verification. |
| `references/journal-protocol.md` | **New.** Event types, timestamp format, append rules, prefixes. |
| `references/estimation-protocol.md` | **New.** Ask-first rules, calibration logic, raw vs calibrated storage. |
| `references/self-reflect-rules.md` | **New.** Validation rules for the self-reflect agent. |
| `references/migrations.md` | **New.** Versioned migration changelog. |
| `agents/pm.md` | **Updated.** References context-bootstrap. Journal-on-every-state-change. Dispatches Sonnet sub-agents. Invokes self-reflect before writes. |
| `agents/self-reflect.md` | **New.** Sonnet validation agent. Checks proposed actions against rules. |
| `skills/pm/SKILL.md` | **Updated.** References context-bootstrap instead of inline logic. |
| `skills/session-start/SKILL.md` | **Updated.** Adds context gate preamble. Writes SESSION_START to journal. |
| `skills/session-end/SKILL.md` | **Rewritten.** Journal-based reconciliation with background Sonnet sub-agents. |
| `skills/plan/SKILL.md` | **Updated.** Adds context gate. Enforces ask-first estimation. Journals new tasks/milestones. |
| `skills/review/SKILL.md` | **Updated.** Adds context gate. Reads journals for richer reporting data. |
| `skills/reprioritize/SKILL.md` | **Updated.** Adds context gate. Journals scope changes. |
| `skills/status-report/SKILL.md` | **Updated.** Adds context gate. Reads journals for richer data. |
| `skills/setup/SKILL.md` | **Minor update.** References context-bootstrap. |
| `templates/scaffolding/estimates.md` | **Updated.** Adds `User Est` column. |
| `.claude-plugin/plugin.json` | **Updated.** Version bump to 2.0.0. |

## What Doesn't Change

- Overall skill routing (orchestrator -> PM agent -> sub-skills)
- Structured file formats (tasks.md, milestones.md, blockers.md, overrules.md) — except extra column in estimates.md
- PM personality, tone scaling, anti-pattern detection, overrule protocol
- Setup flow (minor reference update only)
- Status-report and review output formats (they just get richer input data)
