---
name: cpr
description: "User-invokable only via /cpr. Commit, Push, and Release in one command. Commits all changes as non-interactive micro-commits (conventional commits), pushes to remote, then handles the full release-please cycle: waits for the PR, merges it, and monitors the release workflow to completion. Do NOT auto-trigger this skill."
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git push *) Bash(gh pr *) Bash(gh run *)
---

# CPR — Commit, Push, and Release

Fire-and-forget workflow: commit -> push -> release-please. The entire pipeline runs in the background so you can keep working.

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

### Step 3: Release-please (conditional)

**Gate check — both conditions must be true to proceed:**
1. The current branch is `main` or `master`
2. The repo uses release-please — verify by checking for ANY of:
   - `.release-please-manifest.json` exists
   - `release-please-config.json` exists
   - Any `.github/workflows/*.yml` file contains the string "release-please"

If either condition is false, skip to Step 4.

#### 3a. Wait for the release-please PR

The push to main triggers a GitHub Actions workflow that creates (or updates) a release-please PR. Poll for it:

```bash
gh pr list --label "autorelease: pending" --json number,title,url --limit 1
```

Check every 15 seconds for up to 5 minutes. If the PR already exists when you first check, proceed immediately.

If no PR appears after 5 minutes, report "release-please did not create a PR — commits may not contain releasable changes (check conventional commit prefixes)" and skip to Step 4.

#### 3b. Merge the release-please PR

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

#### 3c. Monitor the release workflow

After the release-please PR merges, release-please runs again to create the actual GitHub release. Monitor the workflow:

```bash
gh run list --branch main --limit 1 --json status,conclusion,url,name
```

Poll every 15 seconds for up to 10 minutes. Wait until `status` is `completed`. Report the `conclusion` (success/failure) and the run URL.

### Step 4: Summary

Report everything that happened:

- **Commits**: how many, with their messages (or "no changes to commit")
- **Push**: branch name, success/failure
- **Release-please**: one of:
  - "PR #N merged, release workflow succeeded" (with URL)
  - "PR #N merged, release workflow failed" (with URL and error details)
  - "No releasable changes detected"
  - "Not applicable (not on main, or release-please not configured)"
- **Errors**: any errors encountered along the way
