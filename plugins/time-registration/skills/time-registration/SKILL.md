---
name: time-registration
description: Summarize recent git work for time registration. Use when the user asks what they worked on, needs a time log, wants a work summary, asks about today's/yesterday's/last week's work, or invokes /time-registration:time-registration. Accepts an optional time period argument (defaults to today).
argument-hint: [today|yesterday|this-week|last-week|last-3-days|since-<day>]
allowed-tools: Bash(git log:*), Bash(git worktree list:*), Bash(git config:*), Bash(git rev-parse:*), Bash(pbcopy:*), AskUserQuestion
---

# Time Registration

Summarize recent git activity into a short, comma-separated one-liner suitable for time registration or standup notes. Always includes commits from sibling worktrees of the current repo, not just the current working tree.

## Arguments

The user may provide a time period as a free-text argument:
- "today" (default if nothing specified)
- "yesterday", "this week", "last week", "last 3 days", "monday", "since friday", etc.

Parse the intent and translate it to a `git log --since`/`--until` date range.

Before running the log, echo the accepted hints so the user sees their options:

```
Time period: today (default). Other options: yesterday, this-week, last-week, last-3-days, since-<day>.
```

If the user passed an argument, skip the hint line and just confirm the parsed range (e.g. `Time period: last week (2026-04-13 → 2026-04-20)`).

## Process

### 1. Determine the date range

Convert the user's input to concrete dates. Examples:
- "today" → `--since="today 00:00"` (default when no argument given)
- "yesterday" → `--since="yesterday 00:00" --until="today 00:00"`
- "last 3 days" → `--since="3 days ago"`
- "this week" → `--since="last monday"`
- "last week" → `--since="2 mondays ago" --until="last monday"`

### 2. Enumerate worktrees

Commits in other worktrees of the same repo don't show up in the current tree's `git log` by default — but they're all reachable from the same object store. List every worktree and iterate:

```bash
git worktree list --porcelain | awk '/^worktree /{print $2}'
```

For each worktree path, run the log scoped to that worktree's HEAD so per-branch work is attributed correctly:

```bash
author="$(git config user.name)"
for wt in $(git worktree list --porcelain | awk '/^worktree /{print $2}'); do
  echo "=== $wt ==="
  git -C "$wt" log --author="$author" --since="<start>" --until="<end>" --oneline --no-merges
done
```

If every worktree returns empty, tell the user there are no commits for that period and stop.

### 3. Summarize

Read through the commit messages across all worktrees and distill them into a single comma-separated summary line. The summary should:

- Use plain, human-readable language (not commit message format)
- Group related commits into one item, even across worktrees (e.g., 3 commits about auth on two branches → "implemented OAuth login")
- Deduplicate: the same commit SHA can appear in multiple worktrees sharing history — count it once
- Use past-tense action verbs: worked on, fixed, implemented, upgraded, refactored, added, removed, updated
- Keep it short — aim for one line that fits in a timesheet entry
- Mention package/dependency upgrades with version numbers if available

**Example output:**

```
Implemented user authentication, fixed pagination bug on dashboard, upgraded React from 18 to 19, refactored API error handling
```

### 4. Offer to copy to clipboard

After printing the summary line, use `AskUserQuestion` to offer copying it to the macOS clipboard. Default to "Yes" — most callers want to paste into a timesheet.

- Question: `Copy summary to clipboard?`
- Options: `Yes, copy it` / `No, leave it`

If the user picks "Yes", pipe the exact summary line to `pbcopy`:

```bash
printf %s "<summary line>" | pbcopy
```

Confirm with a single line (e.g. `Copied.`). Skip this step if the summary was empty (no commits found).

### 5. Multiple repositories

Only if the user explicitly asks to check multiple repos, ask which directories to check using `AskUserQuestion`. Then repeat the worktree-aware log in each directory and produce one summary per repo.
