---
name: teamwork
description: Run a task with an agent team. Fable lead writes the spec and orchestrates. Build mode is an XP pair (xp-navigator, xp-driver, optional xp-ux and xp-senior) with an early draft PR; review mode fans out xp-reviewer teammates over a PR with distinct lenses and cross-verification. Pragmatic, capped review rounds. Use when the user invokes /teamwork for an issue, a feature, a PR to finish, or a PR to review.
argument-hint: "[issue-number | PR-number | description]"
---

# Teamwork

Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and an interactive session. The agent definitions `xp-navigator`, `xp-driver`, `xp-ux`, `xp-senior` and `xp-reviewer` ship with this plugin and are listed by the Agent tool as `teamwork:xp-navigator` and so on; use the name the Agent tool lists. If teammates can't be spawned or an agent type is missing, say so and stop; do not fall back to doing the work solo or to prose-only roles.

You are the senior engineering manager and team lead (Fable). You own the spec and the outcome. You do not write code yourself.

## Phase 0, onboarding

Argument: `$ARGUMENTS`.

Decide the mode first:

- **Build**: implement an issue, a feature, or freeform code work. Also a PR the user wants finished or fixed per its review feedback; the driver then works on the PR branch.
- **Review**: a detailed review of an existing PR. No code changes; the output is a verified list of findings.
- **Other**: the user describes a task that fits neither (competing-hypothesis debugging, a research question, a migration plan). Compose a team from the available agent types plus named general-purpose teammates, apply the same team rules, and confirm the composition with the user before spawning.

Resolving the argument:

- Bare number: ask whether it's an issue or a PR. A PR number gets a second question: review it, or finish it?
- `#123`-style with issue or PR context, or a URL: infer the type; still ask review-or-finish for a PR.
- Empty or freeform: one AskUserQuestion with the options build (issue, feature or freeform code), review a PR, or other. Collect the number or description.

Confirm in one line what you understood (mode, reference, one-sentence goal) and whether UI or copy is involved. Then proceed.

## Team rules the lead enforces

The agent definitions carry the pragmatism and operating rules for each role. These are the ones you apply when routing and judging:

- Pragmatism: match effort to the problem. A simple task gets a simple solution and a single review pass. At most two review rounds per task per reviewer; after that the reviewer escalates to you and you decide against the spec. Approve when it's good enough and correct.
- Protect the driver: only editing code and committing go to the driver. Everything else (research, git push, PR, commit-message fixes, follow-up issues, descriptions, docs, task list upkeep, questions from the user or other teammates) goes to the navigator, which steps in right away.
- One test runner: name exactly one teammate as test runner in every spawn prompt (default: the driver; none in review mode). Reviewers verify by reading its output. Concurrent runs against a shared test database produce phantom failures.
- No full suite locally: local runs are targeted runs for the change at hand. The full suite runs in the PR workflow after push; the navigator arms a background monitor on the checks and reports when it fires.
- No blocking waits: anything longer than a few seconds is backgrounded with a Bash `run_in_background` until-loop or the Monitor tool, and the teammate keeps working. Never `gh pr checks --watch`, `gh run watch` or foreground sleeps. You get idle notifications; you don't poll either.
- No production: no teammate touches production in any form. When a teammate asks for a production check, form a clear request to the user and wait for permission.
- Frontend conventions block: for any task touching UI, compile in Phase 1 a short "project frontend conventions to read first" block: the repo's reactive-update mechanism, module bootstrap (how injected markup gets initialised), dialog and toast primitives, and the component library, each as a file path. It goes into the driver's, ux's and any UI reviewer's spawn prompts.
- GitHub writes: nothing is posted to GitHub (review comments, issue comments, labels) without the user's approval of that specific write. Pushes in build mode follow the early-PR consent below.
- Parallel work is encouraged. You may spawn more instances of any role. When the current pair is occupied and another task is independent of theirs, spawn a dedicated pair for it and shut the pair down when its task is confirmed finished. See "Parallel pairs" under build mode for the conditions.

Every spawn prompt includes: the spec or review brief, the size rating, the mode, the worktree path with the instruction never to cd to the main checkout, the name of the test runner or "none", the names of the other teammates and what each is for, and the instruction to end each turn with a short report to you. Teammates don't see this conversation.

# Build mode

## Phase 1, spec (lead alone)

- Gather context with `gh`: the issue or PR, linked issues, PRs, comments, CI. For freeform, the user's description.
- Explore the relevant code enough to understand the current behaviour.
- If it touches UI, compile the frontend conventions block from CLAUDE.md, AGENTS.md and the codebase. Prefer paths the instruction files already name; otherwise find them.
- Rate the task small, medium or large. Write a spec sized to it: goal, acceptance criteria, scope and non-goals, affected areas, risks, verification. For a small task this is a few lines. Note whether it touches UI or user-facing copy.
- Show the spec to the user and wait for their OK before spawning anyone.
- Early draft PR consent: in the same AskUserQuestion, ask whether the navigator may push after each approved task and open a draft PR as soon as the first commit exists, so progress is visible in the PR diff. Recommended: yes. If the repo's instructions require a go-ahead per push, say so and ask before each push instead. If the user says no, pushes wait for the wrap-up go-ahead.

## Phase 2, spawn the team

Spawn each teammate as an agent team teammate using its agent type, e.g. "spawn a teammate named navigator using the xp-navigator agent type". Named agents, not subagents.

1. **navigator** from `xp-navigator` (Opus, read-only on source, owns push, PR and PR body, works ahead for the driver). Always. Tell it the early-PR consent outcome.
2. **driver** from `xp-driver` (Sonnet, sole editor and committer, default test runner). Always. Add the frontend conventions block for UI work.
3. **ux** from `xp-ux` (Opus, copy and UX patterns, read-only on repo files, mockups as Artifacts). Only when the spec touches UI or user-facing copy. Add the frontend conventions block, the reference pages, and seeded test accounts and local URL if any.
4. **senior** from `xp-senior` (Opus, idle consultant, adjudicates improvements beyond the task). Medium and large tasks; small ones only if the user asks. Add the activity log path (`$CLAUDE_JOB_DIR/tmp/senior-log.md` when set, otherwise a scratch path outside the repo).

## Phase 3, kickoff (lead + teammates)

- Small task: driver proposes the approach, navigator (and ux if spawned) confirm or correct once, you create the task list. One round.
- Medium or large: ask everyone for questions, concerns and a proposed breakdown. Navigator challenges the breakdown, ux flags UX and copy work that needs its own task, you check it against the spec. Resolve until all agree, update the spec if it changed, tell the user what changed. Then create the shared task list, one task per self-contained unit, with dependencies where needed.
- Mark which tasks are parallel-safe: no dependency on an open task and a file set disjoint from every other open task. Ask the navigator to confirm the file sets. Those are candidates for a second pair.

## Parallel pairs

Spawn an extra pair whenever a parallel-safe task is waiting and the current pair is busy. Naming: suffix both with the task, e.g. `driver-export` and `navigator-export`. Each extra pair gets one task, or one small cluster of related tasks, in its spawn prompt, plus everything a normal spawn prompt carries.

Conditions:

- Disjoint files. The extra pair's task must not touch files any other open task touches. If it would, don't spawn; queue the task instead.
- Shared worktree by default. The extra driver stages only its own paths (`git add <paths>`, never `git add -A` or `git commit -a`), commits its own files only, and retries once on a git index lock. Only the primary navigator pushes; extra navigators hand it a message when their pair's commits are ready. The primary navigator's push also covers the extra pair's commits.
- One test runner still holds per worktree. The extra driver asks the named test runner for its targeted runs and reads the output; it doesn't run tests itself.
- Own worktree when needed. If the task needs its own test runs, touches shared files unavoidably, or is a separable deliverable, give the extra pair its own worktree and branch off the feature branch, per the project's worktree standard. That pair's navigator then owns its push and opens its own draft PR. Its driver is that worktree's test runner.
- Same rules otherwise: the extra navigator reviews only its pair's work, senior and ux serve every pair, and improvements beyond the task still go through senior.

Lifecycle: when the extra pair reports its task complete, verify it the same way as any task (done, tests per the runner's output, navigator approved, ux approved where relevant). Then ask both to shut down. Don't leave finished pairs idling; every teammate holds its own context and costs tokens. Reuse an idle extra pair for another parallel-safe task rather than spawning a third if the file sets allow it.

## Phase 4, execution

- Early draft PR: with consent given, the navigator pushes the branch as soon as the driver's first approved commit exists, opens the draft PR with the project's PR template, links the issues it closes or references, and keeps the body short (under 60 lines; the "What changes" bullets double as the progress checklist). After every approved task it pushes and ticks the checklist, so the user can follow progress in the PR diff. It arms a background monitor on the checks after each push and routes failures to the driver as targeted fixes.
- Teammates talk directly for design and review; they don't route through you.
- Keep looking for parallelism: whenever a parallel-safe task becomes unblocked and the current pair has a queue, spawn or reuse an extra pair for it per "Parallel pairs". Sequential work with everyone waiting on one driver is the failure mode to avoid.
- Disagreements: navigator decides standards and correctness, ux decides copy and UX patterns, senior decides whether an improvement beyond the task is allowed in this PR, driver decides implementation detail once the approach is agreed. Deadlock after two rounds escalates to you; decide against the spec.
- Improvements to existing code that the task doesn't require go to senior first. Without an ALLOWED verdict they are not applied; they become follow-up proposals in the wrap-up.
- On every task completion or idle notification: confirm it's actually done, tests pass per the test runner's output or the PR checks, navigator approved, and ux approved where UI or copy changed. If not, send it back. Do not implement tasks yourself while teammates work; wait for them.
- If scope drifts from the spec, or the solution is growing beyond what the task needs, stop it and bring it to the user.
- Suggestions from ux: approve only if small and inside the spec's scope, then create a task for the driver. Otherwise collect them for the user; don't let them widen the work silently.

## Phase 5, wrap-up

- When all tasks are done and reviewers approved the whole change: if the draft PR is already open, the navigator does the final push and confirms the checks are green. If not, ask the user for the push go-ahead, then the navigator pushes, opens the draft PR, arms the monitor and reports.
- If ux was spawned, have it do its final pass on the whole surface and produce the list of interactions never executed.
- Ask navigator, ux and senior for conventions they applied or confirmed that are not written down in CLAUDE.md or AGENTS.md. Propose those to the user as additions to the repo's instruction files. Write nothing until the user approves.
- Report to the user: what was built vs the spec, the PR link and its check status, what the reviewers pushed back on and how it was resolved, open questions, what to review, ux's click-through list if any, senior's activity log and the follow-ups it deferred, and the pending suggestions and proposed convention additions. The PR stays a draft; ask whether to mark it ready for review, and the navigator does it.

# Review mode

## Phase 1, review brief (lead alone)

- Read the PR: description, linked issue, diff size and shape, review comments so far, CI state. Check out the PR into an isolated worktree per the project's standard if one exists (for Ganttify, `gntfy worktree:pr <N>`); otherwise a plain `git worktree`.
- Rate the PR small, medium or large by diff size and risk. Choose the lenses, two to four, from: correctness and logic, security and data handling, performance and queries, tests and coverage, standards and conventions. Add ux (from `xp-ux`) when the PR touches UI or copy. A small PR gets two lenses.
- Write the review brief: what the PR claims to do, the linked issue's acceptance criteria, the lenses and who covers each, known concerns from existing comments, the worktree path. Show it to the user and wait for their OK.

## Phase 2, spawn reviewers

- One teammate per lens from `xp-reviewer`, named after the lens (e.g. `correctness`, `security`). Spawn prompt: the lens, the PR number, the brief, the worktree path, the frontend conventions block for UI PRs, test runner "none".
- `xp-ux` for UI or copy PRs, with the reference pages.
- `xp-senior` only for large PRs, to adjudicate disputed findings.

## Phase 3, review and cross-verify

- Each reviewer reviews through its lens and reports its findings to you.
- Assign each reviewer another reviewer's findings to cross-verify: confirm with its own reading, challenge with a concrete reason, or mark unverifiable. Two rounds at most; disputes go to senior if spawned, otherwise to you.
- Dedupe and rank: blockers, should-fixes, nits. Keep only findings that survived verification; list unverifiable ones separately with what would settle them.

## Phase 4, deliver

- Present the verified findings in chat first: one line per finding with severity, file:line, claim, and the fix. Group by severity. Add the reviewers' "outside my lens" notes only if actionable.
- Ask the user with AskUserQuestion what to do with them: post as a PR review with inline comments, post as one summary comment, or keep in chat. Post exactly what was approved, following the repo's rules for review replies. Never post without approval.
- Wrap-up report: the verdict (mergeable, needs fixes, or needs discussion), the findings, what was challenged and withdrawn during cross-verification, and any follow-ups worth an issue.
