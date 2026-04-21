---
name: cpr
description: "User-invokable only via /cpr. Commit, Push, and Release in one command. Commits all changes as non-interactive micro-commits (conventional commits), pushes to remote, runs a review-and-fix loop on the pushed changes, then handles the full release-please cycle: waits for the PR, merges it, and monitors the release workflow to completion. Do NOT auto-trigger this skill."
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git push *) Bash(git fetch *) Bash(git describe *) Bash(git rev-parse *) Bash(git merge-base *) Bash(gh pr *) Bash(gh run *) Bash(gh repo *) Edit Read Grep Glob Agent
---

# CPR — Commit, Push, and Release

Fire-and-forget workflow: commit -> push -> review -> release-please. The entire pipeline runs in the background so you can keep working.

## Execution

Spawn a single background Agent with `model: "sonnet"` and `run_in_background: true` containing the full pipeline prompt below. After spawning, tell the user:

> "CPR running in the background — you'll be notified when it's done."

Then stop. Do not block the conversation.

When the agent completes, relay its summary to the user.

## Pipeline prompt for the background agent

Provide all of the following as the agent's prompt. Fill in the current branch name before dispatching.

---

You are running the CPR (Commit, Push, Release) pipeline. Execute each step sequentially. If a step fails, report the error and stop — do not continue to the next step.

### Step 1: Commit

Run these four commands in parallel to understand the repo state:
- `git status`
- `git diff`
- `git diff --cached`
- `git log --oneline -10`

If there are no changes at all (nothing unstaged, staged, or untracked), skip to Step 2 — there may still be unpushed commits.

Otherwise, group related files into logical commits:
- Test files go with the source code they test
- Config/migration changes go with the feature they support
- Lockfiles go with their manifest (package-lock.json with package.json, etc.)
- Pure formatting or whitespace changes get their own commit

For each group, stage the specific files and commit with a conventional commit message that matches the style visible in `git log`:
- `feat(scope): description` for new features
- `fix(scope): description` for bug fixes
- `refactor(scope): description` for restructuring
- `chore(scope): description` for maintenance
- Match scope conventions from the repo's recent history; omit scope if the repo doesn't use them

Rules:
- Never commit files that look like secrets (.env, credentials, tokens, private keys)
- Never use `--no-verify` — always let git hooks run
- Never add signatures to commit messages (no Co-authored-by, no Generated-with)

### Step 2: Push

Determine the current branch and push:
- If the branch already tracks a remote: `git push`
- If it's an untracked branch: `git push -u origin <branch>`
- Pushing to main/master is allowed — do not skip or ask for confirmation

If push fails, report the error and stop.

### Step 3: Review & fix loop

Always runs, regardless of branch or release-please configuration. Bounded loop — **max 2 iterations**.

#### 3a. Determine the review range

Pick the diff range based on the branch:

- **Feature branch** (not main/master): diff against the remote base branch.
  ```bash
  git fetch origin
  BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
  RANGE="origin/${BASE}...HEAD"
  ```
- **main/master**: diff since the last release tag.
  ```bash
  git fetch --tags
  LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  RANGE="${LAST_TAG:+$LAST_TAG..}HEAD"
  ```
  If no tag exists, fall back to the last 20 commits: `RANGE="HEAD~20..HEAD"`.

Inspect the range:
```bash
git log --oneline "$RANGE"
git diff "$RANGE"
```

If the diff is empty, skip to Step 4.

#### 3b. Spawn the review sub-agent

Spawn foreground (blocking), review-only — **do not let the sub-agent edit files**:

- `subagent_type`: `general-purpose`
- `description`: "Review pushed changes"
- `prompt`: give the sub-agent the branch name, the range, and the diff output. Ask it to return a structured summary with three lists:
  - `blockers` — correctness bugs, security issues, data-loss risks, clearly broken code
  - `warnings` — risky patterns, missing tests for critical paths, questionable design
  - `nits` — style, naming, minor polish
  Each item must include `file:line` and a one-line description. End with an explicit line: `VERDICT: PASS` (no blockers) or `VERDICT: FIX_REQUIRED` (one or more blockers).

#### 3c. Act on the verdict

- **`PASS`**: record the verdict and any warnings/nits, then proceed to Step 4.
- **`FIX_REQUIRED`**:
  1. Fix only the `blockers`. Do not touch warnings or nits — they go in the final summary.
  2. Group fixes and commit with conventional messages (typically `fix(review): <short description>`). Same grouping rules as Step 1. Using `fix:` also ensures release-please picks them up on main.
  3. `git push`. On main, this updates the release-please PR automatically; on a feature branch, it updates the open PR (if any).
  4. Recompute the diff for the same `RANGE` and re-run the sub-agent review.
  5. After **2 review passes total**, stop the loop even if blockers remain. Record the outstanding blockers — they will gate Step 4.

### Step 4: Release-please (conditional)

**Gate check — all three conditions must be true to proceed:**
1. The current branch is `main` or `master`
2. The repo uses release-please — verify by checking for ANY of:
   - `.release-please-manifest.json` exists
   - `release-please-config.json` exists
   - Any `.github/workflows/*.yml` file contains the string "release-please"
3. Step 3 ended with no outstanding blockers. If blockers remain after the review loop, **do not merge** — skip to Step 5 and report them.

If any condition fails, skip to Step 5.

#### 4a. Wait for the release-please PR

The push to main triggers a GitHub Actions workflow that creates (or updates) a release-please PR. Poll for it:

```bash
gh pr list --label "autorelease: pending" --json number,title,url --limit 1
```

Check every 15 seconds for up to 5 minutes. If the PR already exists when you first check, proceed immediately.

If no PR appears after 5 minutes, report "release-please did not create a PR — commits may not contain releasable changes (check conventional commit prefixes)" and skip to Step 5.

#### 4b. Merge the release-please PR

First try a direct merge:
```bash
gh pr merge <number> --merge
```

If that fails because checks haven't passed yet, enable auto-merge:
```bash
gh pr merge <number> --merge --auto
```

Then poll until the PR is actually merged:
```bash
gh pr view <number> --json state --jq '.state'
```

Check every 15 seconds for up to 10 minutes. If it doesn't merge in time, report the timeout and stop.

#### 4c. Monitor the release workflow

After the release-please PR merges, release-please runs again to create the actual GitHub release. Monitor the workflow:

```bash
gh run list --branch main --limit 1 --json status,conclusion,url,name
```

Poll every 15 seconds for up to 10 minutes. Wait until `status` is `completed`. Report the `conclusion` (success/failure) and the run URL.

### Step 5: Summary

Report everything that happened:

- **Commits**: how many, with their messages (or "no changes to commit")
- **Push**: branch name, success/failure
- **Review**: verdict per iteration, blockers found, fixes applied (commit SHAs), and any outstanding warnings/nits worth surfacing. If blockers remained after 2 iterations, say so explicitly.
- **Release-please**: one of:
  - "PR #N merged, release workflow succeeded" (with URL)
  - "PR #N merged, release workflow failed" (with URL and error details)
  - "Skipped — blockers still present after review loop" (with the blocker list)
  - "No releasable changes detected"
  - "Not applicable (not on main, or release-please not configured)"
- **Errors**: any errors encountered along the way
