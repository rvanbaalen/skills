---
name: commit
description: Commit changes using micro commits with conventional commit messages. Analyzes git diff, groups related files, and proposes commits for approval. Supports interactive and non-interactive (background) modes. Use when the user wants to commit their changes.
argument-hint: "[i|ni]"
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git push *)
---

# Commit Changes

Commit the current changes using micro commits with conventional commit messages.

## Mode Selection (MUST be first — no git commands before this)

**Do NOT run any git commands, read any files, or spawn any agents before the mode is selected.** The very first action in this skill is always mode selection — nothing else.

Check `$ARGUMENTS` first:
- If `$ARGUMENTS` is `i` → use **Interactive** mode
- If `$ARGUMENTS` is `ni` → use **Non-interactive** mode
- Otherwise, use `AskUserQuestion` to ask the user:

**Question:** "How would you like to commit?"

**Options:**
- **Interactive** — propose each commit for approval
- **Non-interactive** — commit in the background (you can keep working)

## Session-scoping (runs in BOTH modes, before anything else)

The point of this skill is to commit *the work we just did together*, not whatever else happens to be dirty in the working tree (a half-edited file from before the session, a stray local config tweak, etc.). Always scope to session-touched files first, then explicitly opt extras in.

Do this in the parent conversation **before** dispatching any background agent — the parent is the only one with the session context needed to know which files were touched.

### 1. Build the session-touched set

From the current conversation, list every file path that was modified in this session via:

- `Edit`, `Write`, `NotebookEdit` tool calls
- `Bash` commands that wrote to files (e.g., `mv`, `cp` into a tracked path, code generators, `npm install` for lockfiles, formatters that ran on specific paths)

Normalize paths to be relative to the repo root. Call this set `SESSION_FILES`.

If `SESSION_FILES` is empty (e.g., the user invoked `/commit` without any prior edits this session), skip straight to step 3 and treat *all* dirty files as "extras" requiring explicit confirmation.

### 2. Diff against git state

Run `git status --porcelain` to get the full set of dirty paths (`DIRTY_FILES`: modified, staged, and untracked).

Compute:
- `IN_SCOPE = SESSION_FILES ∩ DIRTY_FILES` — what we'll commit
- `EXTRAS  = DIRTY_FILES − SESSION_FILES` — pre-existing dirt the session did not touch
- `MISSING = SESSION_FILES − DIRTY_FILES` — session-touched files that have no diff (already committed mid-session, or reverted) — just ignore these

### 3. Confirm extras (if any)

If `EXTRAS` is non-empty, use `AskUserQuestion`. Put the actual file list in the question text so the user can see what they're deciding on:

**Question text:** "Found N file(s) changed outside this session: `<path1>`, `<path2>`, … . Include them in the commits?"

**Options:**
- **Session only** — commit just the files this session touched (default-safe)
- **Include all** — also commit the extras
- **Pick files** — list each extra and ask per-file (use a follow-up `AskUserQuestion` with one option per file: include / skip)

Update `IN_SCOPE` based on the answer. If `IN_SCOPE` ends up empty, tell the user there's nothing to commit and stop.

### 4. Hand off to the chosen mode

Pass `IN_SCOPE` (the explicit file list) into Interactive or Non-interactive mode. From this point on, **never use `git add .`, `git add -A`, or `git add -u`** — only stage paths from `IN_SCOPE`.

## Interactive Mode

Run the workflow below (analyze, group, propose, commit, push) but restrict every `git diff` / `git add` to paths in `IN_SCOPE`. When grouping, only consider files in `IN_SCOPE`.

## Non-interactive Mode

Spawn a background Agent (use `model: "sonnet"` and `run_in_background: true`). The prompt MUST include the explicit `IN_SCOPE` file list and instruct the agent to operate only on those paths.

Prompt the agent to:

1. Treat the provided file list as the **complete and exclusive** scope. Never run `git add .` / `-A` / `-u`. If `git status` shows other dirty files, leave them alone.
2. Run scoped analysis: `git diff -- <IN_SCOPE>`, `git diff --cached -- <IN_SCOPE>`, `git log --oneline -10` for style.
3. Group related files (from `IN_SCOPE` only) using the grouping heuristics below.
4. Auto-approve sensible commits and skip anything ambiguous or risky (partial changes that may break something).
5. Execute commits using the commit message format and rules below, staging files by explicit path.
6. Try to push — push if the branch already tracks a remote; if on an untracked branch, push with `-u origin <branch>`; if on `main`/`master`, do NOT push and mention it in the result.

After dispatching the agent, use the `Monitor` tool on the background agent to stream its progress events (each stdout line arrives as a notification). Surface meaningful milestones — e.g., "staged 3 files", "committed: feat(auth): …", "pushed to origin" — as they happen, without polling or sleeping.

Then inform the user: "Committing N session file(s) in the background — I'll report progress as it commits." Do not block the conversation; continue with other work between monitor notifications.

When the background agent completes, summarize what it committed (and whether it pushed). If Monitor surfaced errors mid-run (failed hook, push rejected, ambiguous group skipped), include those in the summary.

## Process (Interactive Mode)

### 1. Analyze changes

Scope every diff to `IN_SCOPE` (computed during session-scoping). Run these in parallel:

- `git status -- <IN_SCOPE>` — state of the in-scope files
- `git diff -- <IN_SCOPE>` — unstaged changes
- `git diff --cached -- <IN_SCOPE>` — already-staged changes
- `git log --oneline -10` — recent commit style for this repo

If `IN_SCOPE` is empty, tell the user there's nothing to commit and stop.

### 2. Group related files

Analyze the changes and group files that belong together in a single commit. Each group should represent one logical change.

Grouping heuristics:
- Test files go with the source code they test
- Config/migration changes that accompany a feature belong in the same commit
- Pure formatting or whitespace changes get their own commit
- Lockfiles (composer.lock, package-lock.json) go with their manifest (composer.json, package.json)
- Unrelated changes in the same file may warrant splitting — mention this to the user rather than silently including everything

### 3. Propose each commit

For each group, use the `AskUserQuestion` tool. Put the details in the question text itself so the user can read them clearly:

**Question text** should include:
- The list of files
- A one-line summary of what changed
- The proposed commit message

**Options**:
- **Approve** — commit as proposed
- **Modify** — adjust the message or grouping
- **Skip** — skip this group for now

### 4. Execute approved commits

For each approved group, stage only the specific files and commit:

```bash
git add <files>
git commit -m "<conventional-commit-message>"
```

For changes that need a longer explanation, use a commit body via heredoc:

```bash
git commit -m "$(cat <<'EOF'
feat(auth): add OAuth2 login flow

Adds Google and GitHub OAuth providers. Session tokens are stored
in encrypted cookies with a 24h TTL.
EOF
)"
```

Use a body when the "why" isn't obvious from the title alone — e.g., non-trivial refactors, workarounds, or architectural decisions. Most commits only need a title.

### 5. Push

After all commits are made, use `AskUserQuestion` to ask if the user wants to push the branch.

## Commit message format

Use conventional commits with scopes where applicable:

- `feat(scope): add new feature`
- `fix(scope): resolve bug`
- `refactor(scope): restructure code`
- `test(scope): add or update tests`
- `docs(scope): update documentation`
- `chore(scope): maintenance task`

Match the scope style and conventions visible in the repo's recent git log. If the repo doesn't use scopes, omit them.

## Rules

- Never add signatures to commit messages (no "Co-authored-by", no "Generated with")
- Never skip git hooks (no `--no-verify`)
- Never use `git add .`, `git add -A`, or `git add -u` — always stage explicit paths from `IN_SCOPE`
- In interactive mode, all user decisions go through `AskUserQuestion` — never wait for freeform input
- In non-interactive mode, never commit files that look like secrets (.env, credentials, tokens)
- In non-interactive mode, do NOT push to `main` or `master` — only push feature/topic branches
