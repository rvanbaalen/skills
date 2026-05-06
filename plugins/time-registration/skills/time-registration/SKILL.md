---
name: time-registration
description: Summarize recent git work for time registration. Use when the user asks what they worked on, needs a time log, wants a work summary, asks about today's/yesterday's/last week's work, or invokes /time-registration:time-registration. Accepts an optional time period argument (defaults to today).
argument-hint: [today|yesterday|this-week|last-week|last-3-days|since-<day>]
allowed-tools: Bash(git log:*), Bash(git worktree list:*), Bash(git config:*), Bash(git rev-parse:*), Bash(git fetch:*), Bash(gh pr:*), Bash(gh repo:*), Bash(gh api:*), Bash(command:*), Bash(pbcopy:*), AskUserQuestion
---

# Time Registration

Summarize recent git activity into a short, comma-separated one-liner suitable for time registration or standup notes. Includes commits from sibling worktrees of the current repo, remote-tracking branches (work pushed from other machines), and recently merged PRs — not just the current working tree.

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

### 2. Sync with remote

Work may have been pushed from other machines or already merged upstream — fetch before scanning so remote-tracking refs are current. Run once per unique repo across worktrees (worktrees share an object store, so one fetch covers all of them):

```bash
git fetch --all --quiet --prune
```

If fetch fails (offline, auth error), warn the user and continue with whatever local refs already exist — do not fail the skill.

### 3. Enumerate worktrees and scan all branches

Commits in other worktrees, on unchecked-out branches, or on remote-tracking refs don't show up in the current tree's `git log` by default. List every worktree and run a log scoped with `--all` so each iteration surfaces the full ref graph reachable from that worktree's repo store (local branches, remote-tracking branches, refs/stash):

```bash
git worktree list --porcelain | awk '/^worktree /{print $2}'
```

```bash
author="$(git config user.name)"
email="$(git config user.email)"
for wt in $(git worktree list --porcelain | awk '/^worktree /{print $2}'); do
  echo "=== $wt ==="
  git -C "$wt" log --all --author="$author" --since="<start>" --until="<end>" --oneline --no-merges
  # Also pick up commits where the user is the GitHub-recorded author by email,
  # in case user.name varies across machines:
  git -C "$wt" log --all --author="$email" --since="<start>" --until="<end>" --oneline --no-merges
done
```

Dedupe by commit SHA across iterations — `--all` returns overlapping sets across worktrees that share refs. Keep the SHA → first-seen worktree mapping for attribution context.

If every worktree returns empty, fall through to step 4 — merged PRs may still surface activity (e.g., squash-merged work where the original branch was pruned).

### 4. List merged PRs

Squash-merge workflows replace branch commits with a single new SHA on the default branch, sometimes authored by the merger rather than the user. The user's own work disappears from `git log --author=<self>` once the source branch is deleted. To recover it, query GitHub directly.

Skip this step silently if `gh` isn't installed (`command -v gh`) or the repo isn't on GitHub (`gh repo view --json url 2>/dev/null` fails).

Otherwise, list PRs authored by the user merged within the same window:

```bash
gh pr list --author "@me" --state merged \
  --search "merged:>=<start-date> merged:<=<end-date>" \
  --json number,title,mergedAt,headRefName,url \
  --limit 50
```

Translate the date range into ISO `YYYY-MM-DD` for the search qualifiers (e.g., `merged:>=2026-04-29 merged:<=2026-05-06`).

If a PR's commits already showed up in step 3 (match by `headRefName` or commit SHA via `gh pr view <num> --json commits`), prefer the PR title for summarization — PR titles tend to read better than individual commit messages. If a PR's commits are NOT in step 3's output (squash-merged + branch pruned), add the PR title as a standalone summary item.

### 5. Summarize

Read through the commit messages across all worktrees plus the merged PR titles and distill them into a single comma-separated summary line. The summary should:

- Use plain, human-readable language (not commit message format)
- Group related commits and PRs into one item, even across worktrees and remote refs (e.g., 3 commits + 1 merged PR about auth → "implemented OAuth login")
- Deduplicate: the same commit SHA can appear in multiple worktrees sharing history, and a PR's commits may already be in the local log — count each piece of work once
- Prefer PR titles over individual commit messages when a PR is the better summary unit
- Use past-tense action verbs: worked on, fixed, implemented, upgraded, refactored, added, removed, updated
- Keep it short — aim for one line that fits in a timesheet entry
- Mention package/dependency upgrades with version numbers if available

**Example output:**

```
Implemented user authentication, fixed pagination bug on dashboard, upgraded React from 18 to 19, refactored API error handling
```

### 6. Offer to copy to clipboard

After printing the summary line, use `AskUserQuestion` to offer copying it to the macOS clipboard. Default to "Yes" — most callers want to paste into a timesheet.

- Question: `Copy summary to clipboard?`
- Options: `Yes, copy it` / `No, leave it`

If the user picks "Yes", pipe the exact summary line to `pbcopy`:

```bash
printf %s "<summary line>" | pbcopy
```

Confirm with a single line (e.g. `Copied.`). Skip this step if the summary was empty (no commits found).

### 7. Multiple repositories

Only if the user explicitly asks to check multiple repos, ask which directories to check using `AskUserQuestion`. Then repeat the worktree-aware log in each directory and produce one summary per repo.
