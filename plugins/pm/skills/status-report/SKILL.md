---
name: status-report
description: >
  Generate an export-ready status summary for clients, team leads, standups, or personal logs.
  Reads all state files and formats for the target audience.
allowed-tools: Read, Glob, Grep, AskUserQuestion
---

# Status Report

Generate a formatted status update ready to copy/paste.

1. **Read all state files** — `milestones.md`, `tasks.md`, `blockers.md`, `estimates.md`, recent session logs.

2. **Ask audience** — "Who's this for?"
   - **A)** Client
   - **B)** Team lead / standup
   - **C)** Personal log

3. **Generate report by audience:**

   **Client format:**
   - High-level, professional tone
   - Milestone status and dates
   - What was delivered since last update
   - What's coming next
   - Blockers framed as risks (not complaints)
   - No internal metrics or anti-pattern data

   **Team/standup format:**
   - What's done since last standup
   - What's in progress
   - Blockers (direct, technical)
   - ETA for current work

   **Personal format:**
   - Raw stats: tasks completed, hours estimated vs. actual
   - Estimation accuracy by category
   - Velocity trends
   - Anti-pattern frequency
   - Overrule track record

4. **Output to terminal** — formatted for easy copy/paste. Do NOT write to a file unless the user explicitly asks.
