# Cofounder Plugin — Design Spec

**Date:** 2026-03-25
**Status:** Draft
**Location:** `plugins/cofounder/` inside rvanbaalen-skills

## Purpose

A reusable, installable Claude Code plugin that gives any founder a critical-thinking business co-founder. Not a standup bot or checklist manager — a business partner that accumulates knowledge over time, challenges assumptions, enforces prioritization, and becomes increasingly intelligent the more it's used.

## Core Design Principles

### 1. Compounding Intelligence

The agent's value grows with usage. Every check-in, sparring session, action brief, decision, and benchmark adds to its understanding. Over time the agent:

- Recognizes patterns in the user's behavior (stated priorities vs. actual time allocation)
- Tracks which ideas get parked and why — and notices when they resurface
- Correlates metric movements with shipped initiatives
- Identifies which anti-patterns this specific user falls into most
- Proactively surfaces insights, contradictions, and trends — not on request, as part of how it thinks

The check-in cadences (especially weekly and monthly) are natural moments for the agent to deliver synthesized insights. But it can surface them mid-conversation when relevant.

### 2. Opinionated Persona

The personality is the product. Direct, no sugar-coating, permission to say "no." Challenges assumptions. Calls out anti-patterns:

- **Builder's Trap** — defaulting to building features when the problem is growth
- **Shiny Object** — new tech/integration that feels productive but doesn't move numbers
- **Hard Stuff Avoidance** — writing code when the real work is marketing/outreach/analysis
- **Spread Thin** — starting initiative #4 when #1-3 aren't done

This is hardcoded. Not configurable. The directness is the value.

### 3. Documents Are the Source of Truth

All business knowledge lives as markdown files in the data directory. The agent reads everything on startup and writes changes during conversations, not after. Topic files are living knowledge bases that grow with every session.

### 4. Prioritization Enforcement

Every idea passes through a filter before getting attention. The filter criteria adapt to business type but the discipline is universal: if it doesn't pass the filter, it goes to backlog with a one-liner reason.

---

## Architecture

### Plugin Structure

```
plugins/cofounder/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   └── cofounder.md                    # persona + system prompt + startup routine
├── skills/
│   ├── cofounder/SKILL.md              # orchestrator — entry point, pre-checks, delegates to agent
│   ├── setup/SKILL.md                  # onboarding + scaffolding + reconfiguration
│   ├── check-in/SKILL.md              # daily/weekly/monthly/quarterly cadences
│   ├── spar/SKILL.md                   # idea stress-testing through the filter
│   ├── action-brief/SKILL.md           # create scoped action briefs
│   └── review/SKILL.md                 # review queue, goals, progress
├── templates/
│   ├── business-types/
│   │   ├── saas.md                     # SaaS filter criteria + default topics
│   │   ├── agency.md                   # agency filter criteria + default topics
│   │   └── marketplace.md              # marketplace filter criteria + default topics
│   ├── scaffolding/                    # initial file templates for data structure
│   └── readme-template.md             # README for git project route
└── references/
    └── anti-patterns.md                # shared anti-pattern definitions
```

### Component Roles

**Orchestrator skill** (`/cofounder`): The user-facing entry point. Checks if setup has been completed by looking for `${CLAUDE_PLUGIN_DATA}/config.md`. If missing, invokes setup. If present, reads config and spawns the cofounder agent with context about where data lives.

**Setup skill** (`/cofounder:setup`): Onboarding and reconfiguration. Auto-invoked on first run, manually invokable for reconfiguration. When re-run on an existing installation, reads current config, shows what's configured, and asks for explicit confirmation before making any changes.

**Cofounder agent** (`cofounder.md`): The brain. Fixed persona. Reads all data files on startup. Drives conversations. Invokes the four workflow skills as needed based on conversation context — users don't need to invoke them manually.

**Workflow skills** (check-in, spar, action-brief, review): Focused tools the agent calls. Also directly invokable by users via `/cofounder:check-in` etc. Each reads config to find the data path.

---

## Onboarding Flow (Setup Skill)

### First-Run Detection

The orchestrator checks for `${CLAUDE_PLUGIN_DATA}/config.md`. This file always lives in the plugin data directory regardless of where the user chose to store their business data. It's the pointer.

- **Config missing** → first run, auto-invoke setup
- **Config exists** → read `data_path`, verify the path still exists and has expected structure
  - **Path valid** → proceed to agent
  - **Path broken** → inform user, offer to re-run setup or point to new location

### Onboarding Steps

1. **Welcome** — Brief explanation: what the cofounder is, what it does, how it works
2. **Data location** — Where to store business data:
   - Option A: Plugin data directory (`${CLAUDE_PLUGIN_DATA}/workspace/`)
   - Option B: Custom path (user provides, e.g., `~/my-business/`)
3. **Business type** — What kind of business:
   - SaaS / Agency / Marketplace / Other (describe)
   - Loads matching filter template and default topics
4. **Business context** — Populate initial files:
   - Product/business name
   - Current stage (pre-launch, early, growing, mature)
   - Key metric the user cares about most
5. **Topics** — Show defaults for business type, let user add/remove
6. **Scaffold** — Create folder structure, write initial files, generate README if git route
7. **Write config** — Save all choices to `${CLAUDE_PLUGIN_DATA}/config.md`

### Re-Run Safety

When setup detects existing data:
- Shows current configuration
- Asks what the user wants to change
- Requires explicit confirmation before overwriting any files
- Can update config (business type, topics) without destroying existing data

### Config File Format

Stored at `${CLAUDE_PLUGIN_DATA}/config.md`:

```yaml
---
data_path: ~/my-business-cofounder
business_type: saas
business_name: Acme
stage: growing
primary_metric: MRR
topics:
  - growth
  - product
  - retention
  - pricing
setup_completed: 2026-03-25
---
```

---

## Cofounder Agent

### Frontmatter

```yaml
---
name: cofounder
description: Critical-thinking business co-founder that enforces prioritization, challenges assumptions, and becomes smarter over time
model: inherit
tools: Read, Write, Edit, Glob, Grep, Bash, Agent
memory: project
---
```

### Startup Routine

Every session, before responding, the agent reads:

1. Config file → find data path
2. `up-next.md` → current execution queue
3. All goal files (north-star, quarterly, monthly, weekly, backlog)
4. Recent entries in `check-ins/daily-log.md`
5. All topic files
6. Active action briefs in `actions/`
7. Recent decision docs in `decisions/`

Then detects or asks: "Check-in, focused work, or quick hit?"

### Session Types

- **Check-in** — Follow cadence structure, agent drives
- **Focused work** — Full session on main weekly focus
- **Quick hit** — Short window, scope ruthlessly, prevent rabbit holes

### Intelligence Behaviors

The agent actively synthesizes across all accumulated data:

- **Pattern recognition:** Notices recurring themes in parked ideas, stalled briefs, or repeated anti-patterns
- **Metric correlation:** Connects shipped initiatives to metric movements when data is available
- **Contradiction detection:** Flags when stated priorities don't match actual behavior from check-in history
- **Trend surfacing:** Identifies trajectories (improving, declining, stagnant) across goal progress
- **Historical callbacks:** References past decisions and their outcomes when relevant to current discussion

These insights surface naturally during check-ins (especially weekly/monthly) and mid-conversation when relevant.

### Document Maintenance

When new information surfaces during any conversation:
- Update ALL affected files, not just one
- Topic files updated during conversations, not after
- Flag stale topics (weeks without updates)
- Up-next queue updated at every check-in

---

## Workflow Skills

### check-in

Drives cadence-based sessions. Detects or asks which cadence.

**Daily:**
- Review `up-next.md` — was "Now" done?
- Set today's "Now" from queued list
- Create action brief if needed
- Update `up-next.md`
- Log to `check-ins/daily-log.md`

**Weekly (~15-20 min):**
- Score weekly focus — done? If not, why?
- Metrics check against available data
- Walk through all active action briefs
- Log completions, delete finished briefs
- Set next week's focus (max 2 items)
- Update `up-next.md`
- Quick backlog scan
- **Insight moment:** Surface patterns from the past week

**Monthly:**
- Are weekly focuses adding up to monthly goal progress?
- Update topic files with new learnings
- Log strategic decisions if direction changed
- **Insight moment:** Trend analysis across the month

**Quarterly:**
- Score quarterly goals honestly
- Archive previous quarter
- Full backlog review
- Set next quarter's goals (max 3)
- Revisit north star
- **Insight moment:** Deep synthesis — what worked, what didn't, why

### spar

Ad-hoc idea stress-testing through the business-type filter.

1. Listen fully
2. Steel-man the strongest version of the idea
3. Stress-test through the filter (loaded from config's business type)
4. Give a real verdict — not "interesting!"
5. **Passes:** Write action brief → add to `up-next.md` → tell user where to take it
6. **Fails:** Park in `goals/backlog.md` with one-liner reason

### action-brief

Creates scoped action briefs from any conversation.

**Brief format:**
```markdown
# Action Name

## Goal
What this achieves, ties to quarterly/monthly/weekly goals

## Context
Relevant data, links to data/ files

## Target Project
Where this gets executed

## Scope
In scope / Out of scope

## Success Criteria
How we know it worked

## Benchmarks
Current numbers from data/
```

- Writes to `actions/YYYY-MM-DD-<name>.md`
- Adds to `up-next.md` in priority position
- Light briefs for small tasks, full briefs for bigger ones

### review

Reviews current state and progress.

- Shows `up-next.md` with status assessment
- Reviews goal progress (weekly → monthly → quarterly alignment)
- Flags stale topic files
- Flags overdue or stalled action briefs
- Can reorganize priorities with user agreement
- **Proactive insights:** Surfaces patterns and trends from accumulated data

---

## Business Type Templates

Each template defines **filter criteria** and **default topics**.

### SaaS

**Filter:**
1. Does it directly address revenue/growth?
2. How many users does it affect?
3. Expected impact on MRR?
4. Ship this week or rabbit hole?
5. Operationally critical (security/bugs)?

**Default topics:** growth, product, retention, pricing

### Agency

**Filter:**
1. Does it improve team utilization?
2. Impact on pipeline/new business?
3. Client retention impact?
4. Ship this week or rabbit hole?
5. Operationally critical?

**Default topics:** pipeline, delivery, client-retention, operations

### Marketplace

**Filter:**
1. Does it grow supply or demand side?
2. Impact on transaction volume?
3. GMV impact?
4. Ship this week or rabbit hole?
5. Operationally critical?

**Default topics:** supply, demand, product, growth

### Other/Custom

Onboarding asks the user to describe their business. The agent generates filter criteria and topics from that description. The generated filter and topics are written directly into `config.md` (same fields as template-based configs) — no template file is created. This keeps the templates directory clean for curated presets only.

Additional business types can be added as template files without changing any skill or agent logic.

---

## Scaffolded Data Structure

Created by setup in the user's chosen data directory:

```
<data_path>/
├── README.md                  # git route only — executive summary + ToC
├── up-next.md                 # execution queue: Now (1) / This Week (max 3) / Queued
├── goals/
│   ├── north-star.md          # single overarching goal
│   ├── quarterly.md           # max 3 goals, scored honestly
│   ├── monthly.md             # broken down from quarterly
│   ├── weekly.md              # max 2 focus items
│   └── backlog.md             # parked ideas with reasons
├── topics/
│   ├── <topic>.md             # one per topic from template + custom
│   └── ...
├── check-ins/
│   ├── daily-log.md           # running daily log
│   ├── weekly/                # weekly review archives (YYYY-MM-DD-week-review.md)
│   ├── monthly/               # monthly review archives (YYYY-MM-month-review.md)
│   └── quarterly/             # quarterly review archives (YYYY-QN-quarter-review.md)
├── actions/                   # active action briefs (deleted when done)
├── data/                      # dated benchmark snapshots
└── decisions/                 # strategic decision records
```

### Up-Next Queue Structure

```markdown
## Now
Exactly 1 item — the single most important action.

## This Week
Max 3 items, ordered. Links to action briefs.

## Queued
Scoped and briefed actions waiting their turn. Priority order.
```

**Rules:** Updated at every daily check-in. "Now" is always exactly 1. "This Week" is max 3. Forces prioritization.

### README (Git Route)

Generated with:
- Business name and description
- Current north star
- Table of contents linking to all sections
- Last-updated date

Updated by the agent during check-ins when significant state changes occur.

### Data Files

Format: `data/YYYY-MM-DD-<name>.md`

Contains:
- Source (where the data came from)
- Date range
- Raw data (tables/numbers)
- Method (how to reproduce)
- **No conclusions** — data is evidence only. Conclusions go in topic files with links back.

---

## Memory Strategy

**Documents** (in data directory): Business knowledge — goals, decisions, topic knowledge, check-in history, benchmarks, action briefs.

**Persistent memory** (Claude's project memory via agent `memory: project`): Collaboration meta — user's tendencies, working style, feedback on co-founder performance, cross-session observations about how the user thinks and makes decisions.

**Rule:** Business knowledge goes in documents. Collaboration meta goes in memory.

---

## Installation & Distribution

The plugin lives in `plugins/cofounder/` inside the rvanbaalen-skills marketplace. Users install via:

```
/plugin marketplace add rvanbaalen/skills
/plugin install cofounder@rvanbaalen
```

Then type `/cofounder` to start. First run triggers onboarding automatically.
