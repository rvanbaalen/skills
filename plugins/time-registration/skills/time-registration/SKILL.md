---
name: time-registration
description: Summarize recent git work for time registration. Use when the user asks what they worked on, needs a time log, wants a work summary, asks about yesterday's/last week's work, or invokes /rvanbaalen:time-registration. Accepts an optional time period argument (defaults to yesterday).
---

# Time Registration

Summarize recent git activity into a short, comma-separated one-liner suitable for time registration or standup notes.

## Arguments

The user may provide a time period as a free-text argument:
- "yesterday" (default if nothing specified)
- "last 3 days", "this week", "last week", "monday", "since friday", etc.

Parse the intent and translate it to a `git log --since`/`--until` date range.

## Process

### 1. Determine the date range

Convert the user's input to concrete dates. Examples:
- "yesterday" → `--since="yesterday 00:00" --until="today 00:00"`
- "last 3 days" → `--since="3 days ago"`
- "this week" → `--since="last monday"`
- "last week" → `--since="2 mondays ago" --until="last monday"`

### 2. Query git log

```bash
git log --author="$(git config user.name)" --since="<start>" --until="<end>" --oneline --no-merges
```

If the result is empty, tell the user there are no commits for that period and stop.

### 3. Summarize

Read through the commit messages and distill them into a single comma-separated summary line. The summary should:

- Use plain, human-readable language (not commit message format)
- Group related commits into one item (e.g., 3 commits about auth → "implemented OAuth login")
- Use past-tense action verbs: worked on, fixed, implemented, upgraded, refactored, added, removed, updated
- Keep it short — aim for one line that fits in a timesheet entry
- Mention package/dependency upgrades with version numbers if available

**Example output:**

```
Implemented user authentication, fixed pagination bug on dashboard, upgraded React from 18 to 19, refactored API error handling
```

### 4. Multiple repositories

Only if the user explicitly asks to check multiple repos, ask which directories to check using `AskUserQuestion`. Then run the git log in each directory and produce one summary per repo.
