---
name: commit
description: Commit changes using micro commits with conventional commit messages. Analyzes git diff, groups related files, and proposes commits for approval. Supports interactive and non-interactive (background) modes. Use when the user wants to commit their changes.
---

# Commit Changes

Commit the current changes using micro commits with conventional commit messages.

## Mode Selection

Before doing anything else, use `AskUserQuestion` to ask the user which mode to use:

**Question:** "How would you like to commit?"

**Options:**
- **Interactive** — propose each commit for approval
- **Non-interactive** — commit in the background (you can keep working)

## Interactive Mode

Run the full interactive workflow described below (analyze, group, propose, commit, push).

## Non-interactive Mode

Spawn a background Agent (use `model: "sonnet"` and `run_in_background: true`) with a prompt that instructs it to:

1. Run the same analysis steps (git status, git diff, git diff --cached, git log)
2. Group related files using the grouping heuristics below
3. Auto-approve sensible commits and skip anything ambiguous or risky (e.g., files that look unrelated, partial changes that may break something)
4. Execute commits using the commit message format and rules below
5. Try to push — push if the branch already tracks a remote; if on an untracked branch, push with `-u origin <branch>`; if on `main`/`master`, do NOT push and mention it in the result

After dispatching the agent, inform the user: "Committing in the background — you'll be notified when it's done." Then stop — do not block the conversation.

When the background agent completes, summarize what it committed (and whether it pushed) to the user.

## Process (Interactive Mode)

### 1. Analyze changes

Run these in parallel to get the full picture:

- `git status` — see untracked files and overall state
- `git diff` — unstaged changes to tracked files
- `git diff --cached` — already staged changes
- `git log --oneline -10` — recent commit style for this repo

If there are no changes (nothing unstaged, staged, or untracked), tell the user there's nothing to commit and stop.

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
- In interactive mode, all user decisions go through `AskUserQuestion` — never wait for freeform input
- In non-interactive mode, never commit files that look like secrets (.env, credentials, tokens)
- In non-interactive mode, do NOT push to `main` or `master` — only push feature/topic branches
