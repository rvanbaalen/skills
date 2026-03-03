---
name: commit
description: Commit changes using micro commits with conventional commit messages. Analyzes git diff, groups related files, and proposes commits for approval. Use when the user wants to commit their changes.
---

# Commit Changes

Commit the current changes using micro commits with conventional commit messages.

## Process

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
- All user decisions go through `AskUserQuestion` — never wait for freeform input
