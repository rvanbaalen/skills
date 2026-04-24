---
name: make-issue-comment
description: Post a structured investigation/fix comment on the active GitHub PR capturing current findings, root cause, proposed fix, and a progress checklist — and later update progress or mark the comment resolved. Invoke when the user fires `/make-issue-comment`, or says things like "post this as a PR comment", "file these findings on the PR", "update the PR comment", or "mark that comment as resolved".
disable-model-invocation: true
argument-hint: "[new <topic> | update <notes> | resolve]"
allowed-tools: Bash, Read, AskUserQuestion
---

Post (or update) a structured investigation comment on a GitHub PR. The comment captures what was debugged, what the root cause is, the proposed fix, verification, and a live progress checklist — so the user or the next engineer can reopen it later and rebuild context fast.

This is **not** `/make-issue` (which opens a new GitHub issue). This skill only creates/updates **comments on existing PRs**.

## Interpreting `$ARGUMENTS`

Decide intent from the argument, then from the conversation if the argument is empty:

- empty, `new`, or a short topic (e.g. `"swipe edit dead zone"`) → **Create** a new comment.
- `update` / `update <notes>` / `progress` → **Update** an existing comment (tick boxes, refresh sections, add follow-ups).
- `resolve` / `mark resolved` / `done` → **Resolve** an existing comment (tick every remaining box, append `[ ✅ **resolved** ]` to the H2).

If the conversation already contains clear "I fixed it" signals and the user runs this without arguments, ask which action they want with `AskUserQuestion`.

## 1. Identify the target PR

Try in order, stopping at the first that succeeds:

1. If the user named a PR number or URL in the arguments or recent conversation, use that.
2. Otherwise check the current branch: `gh pr view --json number,url,headRefName,title,baseRefName`
3. If no PR exists for the current branch: `gh pr list --state open --json number,title,headRefName,url --limit 20` and use `AskUserQuestion` to let the user pick. Include the branch name in each option label so mis-clicks are unlikely.

Record `owner/repo` (from `gh repo view --json owner,name`) and the PR number — every subsequent `gh` call needs them.

## 2. Gather the context

The authoritative source is **the current conversation**. Extract:

- the symptom the user was debugging (exact error text / warning / UX description — quote it verbatim)
- what you investigated (commands run, files grepped, hypotheses ruled out)
- the root cause you identified (file, line, version, package — be specific)
- the proposed fix (exact change, command, or diff)
- how the fix will be / was verified (test name, manual steps, log evidence)
- any follow-ups that are out of scope for this comment

If a piece is thin, fill it in before drafting:

- Commit SHAs: `git log --oneline -20`
- Precise line references: re-read the file with the `Read` tool (never eyeball)
- Package versions: check `package.json` / `yarn.lock` / equivalent for the actual installed version
- Exact error text: pull it from the logs or reproduction output, don't paraphrase

Concrete evidence is the whole point of this comment. Vague summaries waste everyone's time.

## 3. Draft the comment body

Follow this structure exactly. Reference samples to calibrate tone:

- https://github.com/celery-payroll/employee-app/pull/65#issuecomment-4314957773
- https://github.com/celery-payroll/employee-app/pull/65#issuecomment-4314168742

```markdown
## <short descriptive title>

### Issue

<1–2 paragraphs. Quote the error/warning verbatim with a blockquote if there is one. Describe the observed vs expected behavior.>

### Investigation

<What was actually run: grep commands, log excerpts, tables of tap-x vs event, files inspected. Prefer concrete evidence over prose.>

### Root cause

<The smoking gun. Bold the offending package@version or the specific file:line. One paragraph explaining why it breaks.>

### Fix

<Exact change needed. Commands, diffs, or a numbered list of edits with file paths. If no source changes are required (e.g. lockfile bump only), say so explicitly.>

### Verification

<The regression test that fails before and passes after, or the manual reproduction steps with expected output. Include test file paths.>

### Progress

- [ ] <concrete step 1>
- [ ] <concrete step 2>
...
```

Optional `### Follow-ups (out of scope here)` section — use it when you surfaced related issues that should not block this fix. Keep follow-ups as a short bulleted list.

Formatting conventions from the reference samples:

- H3 headings may carry a qualifier in parentheses (e.g. `### Fix (minimal)`, `### Verification (Android emulator)`) when it clarifies scope.
- Use fenced code blocks with language tags for commands and code (```bash```, ```js```, ```json```).
- Use tables when the data is tabular (e.g. input → observed event).
- Use blockquotes for quoted errors, warnings, or docs.
- Bold the part of a sentence that carries the load (`**package@version**`, `**not**`).
- Reference commits inline with short SHAs in backticks: `` `2390573` ``.
- Keep the tone terse and technical, written for someone who will reopen this comment in three months.

Skip a section only if it is structurally impossible to fill (e.g. root cause still unknown). When skipping, keep the heading and write `TBD` under it — later updates will slot in cleanly.

## 4. Confirm before posting

Use `AskUserQuestion` to show the draft:

- **Post comment** — submit it
- **Edit** — take feedback and redraft

Do not post without approval.

## 5. Post the comment

Write the body to a temp file first so heredoc quoting and backticks don't get mangled:

```bash
BODY_FILE=$(mktemp -t pr-comment.XXXXXX.md)
cat > "$BODY_FILE" <<'EOF'
## <title>

### Issue
...
EOF

gh pr comment <pr-number> --repo <owner>/<repo> --body-file "$BODY_FILE"
rm "$BODY_FILE"
```

Print the returned comment URL back to the user.

## Updating an existing comment (`update` / `resolve`)

### a. Find the comment

Get the current user's login and list their comments on the PR, filtered to ones that match our format signature (body starts with `## ` and contains `### Progress`):

```bash
VIEWER=$(gh api user --jq .login)

gh api "repos/<owner>/<repo>/issues/<pr-number>/comments" \
  --paginate \
  --jq ".[] | select(.user.login == \"$VIEWER\") | select(.body | startswith(\"## \")) | select(.body | contains(\"### Progress\")) | {id, html_url, body}"
```

If multiple matches come back, use `AskUserQuestion` with each candidate's H2 title as the label. If the user named a comment URL or ID in the arguments, match that directly instead.

### b. Rewrite the body

Read the existing body, then:

- **update** — flip the `- [ ]` boxes the user has actually completed to `- [x]`. Add new progress lines for work done since the comment was created. Refresh `### Verification` or `### Fix` if anything material changed. Preserve all other content verbatim.
- **resolve** — everything in `update`, plus:
  - tick every remaining `- [ ]` that the user confirms is done (ask with `AskUserQuestion` if any are ambiguous — do not silently check boxes)
  - change the top line from `## <title>` to `## <title> [ ✅ **resolved** ]`
  - if the title already ends with the resolved marker, leave it as-is (idempotent)

### c. Push the update

```bash
BODY_FILE=$(mktemp -t pr-comment.XXXXXX.md)
cat > "$BODY_FILE" <<'EOF'
<new body>
EOF

gh api -X PATCH "repos/<owner>/<repo>/issues/comments/<comment-id>" \
  --field body=@"$BODY_FILE"
rm "$BODY_FILE"
```

Print the comment URL again so the user can click through and eyeball the diff.

## Guardrails

- Never post or update a comment without explicit user approval for the draft.
- Never fabricate commit SHAs, file paths, line numbers, or test names — if you don't have them, leave them out or ask.
- Never silently tick a progress box the user hasn't confirmed is done.
- If `gh auth status` shows you're logged in as a bot or a different account than the user expects, stop and flag it — posting under the wrong identity is hard to undo.
