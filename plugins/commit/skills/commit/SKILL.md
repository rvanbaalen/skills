---
name: commit
description: Commit changes using micro commits with conventional commit messages. Analyzes git diff, groups related files, and proposes commits for approval. Use when the user wants to commit their changes.
disable-model-invocation: true
---

# Commit Changes

Commit the current changes using micro commits with conventional commit messages.

## Process

### 1. Analyze changes

Run `git diff` and `git status` to see all staged and unstaged changes.

### 2. Group related files

Analyze the changes and group files that belong together in a single commit. Each group should represent one logical change.

### 3. Propose each commit

For each group, use the `AskUserQuestion` tool to present:

**Question**: "Commit these changes?"

**Options include the details in the description**:
- **Approve** — files, summary, and the proposed conventional commit message
- **Modify** — adjust the commit message or grouping
- **Skip** — skip this group for now

### 4. Execute approved commits

For each approved group:

```bash
git add <files>
git commit -m "<conventional-commit-message>"
```

### 5. Push

After all commits are made, use `AskUserQuestion` to ask if the user wants to push the branch.

## Commit message format

Always use conventional commits with scopes where applicable:

- `feat(scope): add new feature`
- `fix(scope): resolve bug`
- `refactor(scope): restructure code`
- `test(scope): add or update tests`
- `docs(scope): update documentation`
- `chore(scope): maintenance task`

## Rules

- Never add signatures to commit messages (no "Co-authored-by", no "Generated with")
- Never skip git hooks (no `--no-verify`)
- All user decisions go through `AskUserQuestion` — never wait for freeform input
