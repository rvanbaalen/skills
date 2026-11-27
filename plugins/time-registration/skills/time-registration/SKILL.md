---
name: time-registration
description: Summarize recent git work for time registration. Use when the user asks what they worked on, needs a time log, wants a work summary, asks about today's/yesterday's/last week's work, asks for time registration for a project, or invokes /time-registration:time-registration. Can log the result to Zoho Invoice as time entries. Accepts an optional project name and time period (defaults to the current repo's project and today).
argument-hint: [project] [today|yesterday|this-week|last-week|last-3-days|since-<day>]
allowed-tools: Bash(git log:*), Bash(git reflog:*), Bash(git worktree list:*), Bash(git config:*), Bash(git fetch:*), Bash(git rev-parse:*), Bash(git remote:*), Bash(git -C * log *), Bash(git -C * reflog *), Bash(git -C * worktree list *), Bash(git -C * config *), Bash(git -C * fetch *), Bash(git -C * rev-parse *), Bash(git -C * remote *), Bash(gh pr:*), Bash(gh repo:*), Bash(gh api:*), Bash(command:*), Bash(date:*), Bash(find:*), Bash(jq:*), Bash(pbcopy:*), Read(~/.claude/time-registration/**), Write(~/.claude/time-registration/**), mcp__claude_ai_ZohoMCP__ZohoInvoice_List_all_Organizations, mcp__claude_ai_ZohoMCP__ZohoInvoice_Get_the_Current_User, mcp__claude_ai_ZohoMCP__ZohoInvoice_List_all_Projects, mcp__claude_ai_ZohoMCP__ZohoInvoice_List_all_Tasks_of_a_Project, mcp__claude_ai_ZohoMCP__ZohoInvoice_List_all_Time_Entries, AskUserQuestion
---

# Time Registration

Summarize recent git activity into a short, comma-separated one-liner suitable for time registration or standup notes, written for the client or employer who reads it and in the user's own style. Covers every repo that belongs to the project, every worktree of those repos, remote-tracking branches (work pushed from other machines), and the user's PRs — not just the current working tree. Distinguishes new work from iteration on existing PRs, so a day of review fixes doesn't read as a day of building. A thin git log is never taken as an empty day without checking the reflog, reviews and session logs. The result is copied to the clipboard or, once set up per project, logged to Zoho Invoice.

## Arguments

The user may name a project and a time period, in free text:
- Project: "for acme", "project acme" (default: the project the current repo belongs to)
- Period: "today" (default), "yesterday", "this week", "last week", "last 3 days", "monday", "since friday", etc.

Before running the log, echo the accepted hints so the user sees their options:

```
Time period: today (default). Other options: yesterday, this-week, last-week, last-3-days, since-<day>.
```

If the user passed a period, skip the hint line and just confirm the parsed range (e.g. `Time period: last week (2026-04-13 → 2026-04-20)`).

## Process

### 1. Resolve the project's repos

Work for one client or product is often spread over several repos (an app, a design system, an admin panel, an API). Ask once which repos make up the project, remember the answer, and check all of them on every run.

The answers live in `~/.claude/time-registration/projects.json`. Read it with the Read tool; a missing file means no projects are known yet:

```json
{
  "projects": {
    "acme": {
      "repos": [
        "/Users/me/Sites/acme/web-app",
        "/Users/me/Sites/acme/design-system"
      ]
    }
  }
}
```

Repo paths are always the main checkout, never a worktree. For the current directory, the main checkout is the parent of `git rev-parse --path-format=absolute --git-common-dir`, which resolves the same from any of its worktrees.

Look the project up:
1. If the user named a project, match it against the project names, ignoring case.
2. Otherwise, find the project whose `repos` contains the current main checkout.
3. If either matches, use its repos without asking. Confirm the scope in one line: `Project: acme (web-app, design-system)`.

If nothing matches, ask once. Collect candidates first: the git repos next to the current one (`find <parent of main checkout> -mindepth 2 -maxdepth 2 -name .git`), minus the current repo. Then use `AskUserQuestion`:

- Question: `Does <project> include other repos besides <current repo>?`
- `multiSelect: true`, with up to four likely candidates as options, a "Just this repo" option, and "Other" for paths elsewhere.

Name the project after what the user called it, or else after the current repo's parent folder (`~/Sites/acme/web-app` → `acme`), and write the entry with the Write tool, keeping existing projects intact. Save "Just this repo" too, as a one-repo project, so the question isn't asked again. When the user later says a repo is missing or no longer belongs, update the entry.

If the user names an unknown project while standing in an unrelated repo, ask which directories it covers instead of offering the current repo.

Run steps 4 to 7 for every repo in the project. For repos other than the current one, add `-C "<repo>"` to each git command, pass `-R <owner>/<name>` to each `gh pr` command (taken from `git -C "<repo>" remote get-url origin`), and use that repo's path for the session-log slug.

### 2. Choose the output

The summary goes to the clipboard, or straight into Zoho Invoice as time entries. The project's `output` field in `projects.json` remembers the choice. It is per project: a project without its own `output` gets its own first-time setup, whatever other projects chose.

- `"zoho"` — log to Zoho in step 10, using the saved `zoho` settings. If the detected Zoho tool prefix differs from the saved `tool_prefix`, rerun the tool-approval question in [zoho.md](zoho.md) first.
- `"clipboard"` — the user declined Zoho. Don't ask about Zoho again; offer the clipboard in step 10.
- Not set — check whether a Zoho Invoice MCP is connected (a tool whose name ends in `ZohoInvoice_Log_a_Time_Entry`, possibly deferred). If it is, run the first-time setup in [zoho.md](zoho.md) now, before scanning. If it isn't, use the clipboard and save nothing, so the setup runs once Zoho is connected.

### 3. Determine the date range

Resolve the period to absolute local dates before touching git. Take today's date from context, or `date +%F` if unsure. Don't pass relative phrases like `"last monday"` or `"2 mondays ago"` to git: its date parser guesses, and "last monday" run on a Monday is off by a week.

The window is `[start, end)`, with `end` exclusive:
- "today" → start = today, end = tomorrow
- "yesterday" → start = yesterday, end = today
- "last 3 days" → start = today − 2, end = tomorrow
- "this week" → start = this week's Monday, end = tomorrow
- "last week" → start = last week's Monday, end = this week's Monday
- "since friday" → start = the most recent Friday before today, end = tomorrow

Every later step uses these same dates. GitHub and Claude session logs report UTC timestamps; convert them to local time before comparing.

### 4. Sync with remote

Work may have been pushed from other machines or already merged upstream — fetch before scanning so remote-tracking refs are current. Worktrees share one object store, so one fetch per repo covers all of its worktrees:

```bash
git fetch --all --quiet --prune
```

If fetch fails (offline, auth error), warn the user and continue with whatever local refs already exist — do not fail the skill.

### 5. Log commits

Read the identity first with `git config user.name` and `git config user.email`, then put the literal values in the log command (command substitution triggers permission prompts):

```bash
git log --all --no-merges \
  --author="<name>" --author="<email>" \
  --since="<start> 00:00" \
  --date=format:'%Y-%m-%d %H:%M' \
  --format='%H | %ad | %cd | %s'
```

Then compare the two dates on every line: the **author date** (first, when the commit was written) and the **committer date** (second, when it was last rewritten). Keep only commits whose author date falls in the window.

A rebase moves commits in both directions, so filtering on either date alone is wrong:

- **Pushed out.** `--since` and `--until` check the committer date. A rebase or amend after the window moves a commit's committer date past it, and `--until` would drop work that was really done in the window. So pass only `--since` (the committer date is never earlier than the author date) and judge by author date yourself.
- **Pulled in.** A rebase inside the window gives old commits a fresh committer date, so they pass `--since` although they were written days earlier. One rebased PR can surface 20 commits written the week before. Author date before the window, committer date inside it: the commit was rewritten, not written. Leave it out. At most the rebase itself is iteration on that PR ("rebased X onto main", "resolved conflicts on X"), and only if nothing else in the window covers that PR.
- One run covers the whole repo: `--all` reads the shared ref store, so it sees every worktree's branches and detached HEADs, remote-tracking branches, and the stash. There is no need to loop over worktrees here.
- The two `--author` flags OR together, catching commits where `user.name` varies across machines but the email is consistent.

### 6. List the user's PRs

Squash-merge workflows replace branch commits with a single new SHA on the default branch, sometimes authored by the merger rather than the user, so the user's own work disappears from `git log --author` once the source branch is deleted. PRs also give the context step 8 needs: whether the work is new or iteration.

Skip the GitHub checks in steps 6 and 7 silently if `gh` isn't installed (`command -v gh`) or the repo's `origin` isn't on GitHub.

List the user's PRs in any state (open, draft, merged, closed) touched in the window:

```bash
gh pr list --author "@me" --state all \
  --search "updated:>=<start>" \
  --json number,title,state,isDraft,createdAt,mergedAt,headRefName,commits \
  --limit 50
```

A PR counts as work in the window if it was created or merged in the window, or if any of its `commits[]` has an `authoredDate` in the window. Judge PR commits by `authoredDate` too, never `committedDate`: a force-pushed rebase gives every commit a new `committedDate`. The PR's commit list keeps the original commits after a squash-merge or a pruned branch, so this catches work step 5 can't see. Match to step 5's log by SHA (`commits[].oid`). Ignore other PRs: someone else commented, or only a trivial event happened (see step 8), and the user did no real work.

### 7. A thin log doesn't mean an empty day

If steps 5 and 6 found nothing across the project's repos, or much less than the period plausibly held (one or two commits for a full working day), look further before reporting a quiet day. Anything found here goes into the summary, except trivial GitHub events (see step 8).

**Reflog in every worktree.** The reflog records commits later squashed, dropped or reset away, plus rebases, amends and checkouts. `HEAD`'s reflog is per worktree, so list the worktrees with `git worktree list --porcelain` and run this for each path:

```bash
git -C "<worktree>" reflog -n 500 --date=format:'%Y-%m-%d %H:%M' --format='%gd | %h | %gs'
```

Keep entries whose `HEAD@{…}` timestamp falls in the window. `commit:` and `commit (amend):` lines are the user's own commits. `rebase (pick):` lines replay old commits and are not new work; they, `reset` and `checkout: moving from a to b` lines only show which branches the user was working on.

**PRs authored in any state.** Recheck step 6's list with an eye for closed, unmerged PRs and drafts: abandoned or unfinished work is still time spent.

**PRs reviewed.** Get the user's login with `gh api user --jq .login`, then:

```bash
gh pr list --state all \
  --search "reviewed-by:@me updated:>=<start>" \
  --json number,title,author,reviews \
  --limit 50
```

Keep PRs with a review in `reviews[]` by that login whose `submittedAt` falls in the window.

**Claude session logs.** Claude Code stores sessions as JSONL under `~/.claude/projects/<slug>/`, where `<slug>` is the repo's absolute path with every `/` and `.` replaced by `-` (e.g. `/Users/me/Sites/app` → `-Users-me-Sites-app`). Sessions started in a worktree live in sibling folders named `<slug>--<worktree path>`. Find the session files modified since the window started:

```bash
find ~/.claude/projects -maxdepth 2 \( -path "*/<slug>/*" -o -path "*/<slug>--*" \) \
  -name '*.jsonl' -newermt "<start>"
```

For each file, read the session title and the user's prompts inside the window:

```bash
jq -r 'select(.type=="ai-title") | .aiTitle' "<file>" | tail -1
jq -r 'select(.type=="user" and (.message.content|type)=="string") | "\(.timestamp) \(.message.content[0:200])"' "<file>"
```

Prompts wrapped in `<command-name>` or `<local-command-…>` tags are slash-command noise; skip them. Claude Code deletes old sessions (after 30 days by default), so a period further back may have no logs at all.

Only report no activity if all four checks come up empty too.

### 8. Classify the work

A run of commits is usually iteration, not new work. Sort every piece of work into one of these kinds:

- **New work** — a PR created or merged within the window, or commits that match no PR and add something new. Only these get "built", "implemented" or "added".
- **Iteration** — commits on a PR created before the window that wasn't merged in it. Describe these as "iterated on", "addressed review feedback on" or "retested", picked from the commit messages (review wording like "address feedback", "apply suggestions" or "nit" → "addressed review feedback"). Never "built" or "implemented", however many commits there are.
- **Bug fixes** — commits or PRs that fix a defect ("fix", "bug", "regression"), written as "fixed …".
- **Reviews** — PRs by others that the user reviewed, written as "reviewed …".
- **Other work** — found only in the reflog or session logs, with no commit or PR behind it. Describe it by what the prompts show: "investigated", "debugged", "researched", "prototyped".

Keep the kinds as separate items, even when they touch the same feature. A day of review fixes on one old PR plus one new PR is two items, not "worked on X and Y".

Leave out trivial GitHub events. They move a PR's `updatedAt` into the window but aren't time worth logging: requesting or re-requesting a reviewer, assigning, labelling, editing a title or description, toggling draft or ready for review, re-running CI, or closing a PR with no other work on it in the window. A PR whose only activity in the window is one of these is not an item.

### 9. Summarize

The note is read by whoever pays for the hours: a client or an employer who knows the product, not the code. Distill the classified work from all of the project's repos into one short line they understand at a glance. When logging to Zoho over a multi-day period, write the notes per day instead (see [zoho.md](zoho.md)).

Follow the project's saved `style` first (see "Match the user's own notes" below). Where it is silent:

- **Name the result in the reader's words.** The feature, screen or integration and what changed for it: "added a filter builder to the employee list", not the classes, components, hooks or files that were touched.
- **Leave out the plumbing.** No PR or issue numbers, branch names, commit counts or internal version numbers, and no process steps such as rebasing, pushing, review rounds, re-running CI or filing follow-up issues. They are how the work was done, not what was done.
- **Stay to the point.** One line of one to four items, at most about 200 characters. When a day holds more than that, merge the small items into the larger piece of work they belong to instead of listing them.
- **Say what this day added.** Work on one feature often spans days; name the part that was done on this day ("employee list: saved filters" one day, "employee list: column picker" the next). Never repeat a catch-all such as "worked on the employee list" or "review feedback" day after day. Look at the notes already logged for the days before, and don't reuse their wording.
- **Meetings name who and what:** "meeting with Sam and Alex about the import flow".
- Group related commits into one item within a kind (3 commits + 1 merged PR about auth → "implemented OAuth login"), also when the work spans repos (a design-system change and the app change that uses it).
- Count each piece of work once: a PR's commits and the PR itself are the same work.
- Use the verb that matches the item's kind from step 8, in plain words ("improved the login form after review", not "addressed review feedback on PR 812").
- Mention a package or dependency upgrade with its version number only when the upgrade is the item itself.

**Example output:**

```
Improved the OAuth login after review, built CSV export for reports, fixed the pagination on the dashboard
```

#### Match the user's own notes

Notes should read as if the user wrote them. The project's `style` field in `projects.json` holds how they write: language, length, wording habits, and a few of their own notes as examples.

```json
"style": {
  "language": "nl",
  "rules": ["One short sentence per entry", "Name the integration or feature, never the PR"],
  "examples": ["Entity mapping documentatie uitgewerkt, besproken met het team en geupdate."]
}
```

When `style` is missing and earlier notes can be read (Zoho's `List_all_Time_Entries`), learn it once: read the oldest entries of the project, or the period the user names as their own writing, since later entries may have been written by this skill. Take from them the language, the typical length, how items are joined, which details they do and don't mention, and how the work is split over tasks. Save that as `style`, with three to five verbatim notes as `examples`, and tell the user in one line what was learned. When the user corrects the wording of a note, update `style` so the correction holds for later runs.

### 10. Deliver

Skip this step if the summary was empty (step 7 found nothing either).

**Zoho** (the project's `output` is `zoho` and the Zoho MCP is available): check for existing entries, confirm the hours per day, log the entries and finish with the project's timesheet URL, as described under "Writing entries" in [zoho.md](zoho.md). Don't offer the clipboard.

**Clipboard** (every other case): after printing the summary line, use `AskUserQuestion` to offer copying it to the macOS clipboard. Default to "Yes" — most callers want to paste into a timesheet.

- Question: `Copy summary to clipboard?`
- Options: `Yes, copy it` / `No, leave it`

If the user picks "Yes", pipe the exact summary line to `pbcopy`:

```bash
printf %s "<summary line>" | pbcopy
```

Confirm with a single line (e.g. `Copied.`).
