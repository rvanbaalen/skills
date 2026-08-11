# rvanbaalen / skills

Public Claude Code plugin marketplace by Robin van Baalen.

## Setup

```
/plugin marketplace add rvanbaalen/skills
```

Then install any plugin below with `/plugin install <name>@rvanbaalen`.

## Table of contents

- [Git &amp; GitHub workflow](#git--github-workflow)
  - [commit](#commit)
  - [cpr](#cpr)
  - [version-bump](#version-bump)
  - [make-issue](#make-issue)
  - [make-issue-comment](#make-issue-comment)
- [Planning &amp; process](#planning--process)
  - [pm](#pm)
  - [cofounder](#cofounder)
  - [drill-me](#drill-me)
  - [comment-conventions](#comment-conventions)
- [Productivity](#productivity)
  - [time-registration](#time-registration)
  - [open-markdown](#open-markdown)
- [Frontend &amp; UI](#frontend--ui)
  - [design-principles](#design-principles)
  - [react-query](#react-query)
  - [driverjs-guide](#driverjs-guide)
  - [lottie-animator](#lottie-animator)
  - [svg-precision](#svg-precision)
- [Specialized tools](#specialized-tools)
  - [browse](#browse)
  - [use-agentvision](#use-agentvision)
  - [hermes-tweet](#hermes-tweet)
  - [cloudflare-deploy](#cloudflare-deploy)
  - [disk-cleanup](#disk-cleanup)

---

## Git & GitHub workflow

### commit

Micro-commits with conventional commit messages. Analyzes the diff, groups related files, and proposes a series of focused commits for approval. Supports interactive and non-interactive (background) modes.

```
/plugin install commit@rvanbaalen
```

Invoke with `/commit:commit`.

### cpr

Commit, Push, and Release in one command. Runs non-interactive micro-commits, pushes to the remote, performs a review-and-fix loop on the pushed changes, then drives the full release-please cycle (waits for the PR, merges it, and monitors the release workflow to completion).

```
/plugin install cpr@rvanbaalen
```

Invoke with `/cpr` (this skill is user-triggered only).

### version-bump

Auto-suggests semver version bumps for changed plugins in this kind of marketplace repo before you push. Detects modified plugin/skill files, proposes the right bump (patch/minor/major), and updates `marketplace.json`.

```
/plugin install version-bump@rvanbaalen
```

Invoke with `/version-bump:version-bump`, or it triggers automatically when you ask to push and the working tree contains a `.claude-plugin/marketplace.json`.

### make-issue

Create a new GitHub issue with template, type, and label selection. Walks through the right template for the repo and fills in the structured fields.

```
/plugin install make-issue@rvanbaalen
```

Invoke with `/make-issue:make-issue`.

### make-issue-comment

Post a structured investigation/fix comment on the active GitHub PR, update progress, and mark resolved when done. Proactively proposes itself when an investigation lands on a root cause and fix plan.

```
/plugin install make-issue-comment@rvanbaalen
```

Invoke with `/make-issue-comment:make-issue-comment`.

---

## Planning & process

### pm

Delivery-focused project manager that enforces deadlines, tracks estimates vs. actuals, detects anti-patterns (scope creep, gold plating, yak shaving), and holds you accountable. Tone adapts to timeline pressure — supportive when there's slack, blunt when you're overdue.

```
/plugin install pm@rvanbaalen
```

Type `/pm` to start. First run triggers project setup automatically; existing v1.x projects migrate on first session.

| Skill | Purpose |
|-------|---------|
| `pm` | Orchestrator — entry point, spawns the agent |
| `setup` | Project onboarding and reconfiguration |
| `plan` | Define milestones, tasks, and estimates |
| `session-start` | Check-in with timeline health and journal logging |
| `session-end` | Journal-based reconciliation with background sub-agents |
| `review` | Progress analysis, estimation accuracy, time tracking |
| `reprioritize` | Reshuffle tasks to protect deadlines |
| `status-report` | Export-ready status for clients, teams, or personal logs |

### cofounder

A critical-thinking business co-founder agent that enforces prioritization, challenges assumptions, and becomes smarter the more you use it. Includes onboarding, check-in cadences, idea sparring, action briefs, and progress review.

```
/plugin install cofounder@rvanbaalen
```

Type `/cofounder` to start. First run triggers onboarding automatically.

| Skill | Purpose |
|-------|---------|
| `cofounder` | Orchestrator — entry point, spawns the agent |
| `setup` | Onboarding and reconfiguration |
| `onboard` | First-run profile capture |
| `check-in` | Daily, weekly, monthly, quarterly cadences |
| `spar` | Stress-test ideas through the business filter |
| `action-brief` | Create scoped action briefs |
| `review` | Review state, progress, and priorities |

### drill-me

Stress-test a plan before implementation. Walks the design tree one decision at a time, asks one opinionated question per turn with a recommended answer, and explores the codebase instead of asking when the answer is already there. Continues until shared understanding is reached.

```
/plugin install drill-me@rvanbaalen
```

Invoke with `/drill-me:drill-me`, or trigger naturally with phrases like "drill me", "stress test this", "poke holes in this", or "what am I missing".

### comment-conventions

Language-agnostic code commenting and docblock conventions: present-tense comments, dev-focused content, mandatory docblocks on new functions/methods/components, and a 3-source-line descending-length cap on docblock prose. Auto-fixes non-compliant docblocks on existing functions in the file being edited, leaving unusually long deliberate ones alone.

```
/plugin install comment-conventions@rvanbaalen
```

Auto-triggers whenever you author or edit code that contains comments or docblocks.

---

## Productivity

### time-registration

Git-based time registration summaries. Reviews recent commits, worktrees, and merged PRs to produce a clean work log for the period you specify (today, yesterday, last week, etc.).

```
/plugin install time-registration@rvanbaalen
```

Invoke with `/time-registration:time-registration [period]`.

### open-markdown

Offers to open markdown documents (plans, specs, design docs, RFCs) in `mdreader` for comfortable reading. Triggers automatically after substantive markdown files are written.

```
/plugin install open-markdown@rvanbaalen
```

Auto-triggers after writing plans/specs, or invoke with `/open-markdown:open-markdown`.

---

## Frontend & UI

### design-principles

Apple's eight core principles of design — Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight — as a working framework for reviewing, critiquing, and building interfaces. Surfaces the trade-off explicitly whenever honoring one principle costs another.

```
/plugin install design-principles@rvanbaalen
```

Auto-triggers when designing, reviewing, or critiquing a UI, screen, flow, or component.

### react-query

TanStack Query v5 (React Query) reviewer and coach. Three modes: code review for existing query/mutation code, v4→v5 migration assistance, and coding guidance while writing new v5 code. Grounded in the official v5 docs.

```
/plugin install react-query@rvanbaalen
```

Auto-triggers on files importing from `@tanstack/react-query`.

### driverjs-guide

Driver.js product tours, onboarding flows, and element highlighting reference. Use when building or debugging user-onboarding tours.

```
/plugin install driverjs-guide@rvanbaalen
```

Auto-triggers when working with Driver.js.

### lottie-animator

Generate professional Lottie animations from static SVGs — a workflow alternative to After Effects for motion graphics on the web.

```
/plugin install lottie-animator@rvanbaalen
```

Invoke with `/lottie-animator:lottie-animator`.

### svg-precision

Deterministic SVG generation, validation, and rendering. Use for icons, diagrams, charts, UI mockups, or technical drawings that require structural correctness and cross-viewer compatibility.

```
/plugin install svg-precision@rvanbaalen
```

Invoke with `/svg-precision:svg-precision`.

---

## Specialized tools

### browse

Fast persistent headless browser CLI for QA testing and site dogfooding: snapshots with `@e` refs, before/after diffs, annotated and responsive screenshots, form/dialog/upload testing, local HTML rasterization, headed mode with a bundled sidebar extension, and user handoff for CAPTCHAs. Standalone extraction of the `browse` skill from [gstack](https://github.com/garrytan/gstack) by Garry Tan (MIT).

```
/plugin install browse@rvanbaalen
```

Auto-triggers on phrases like "open in browser", "test the site", "take a screenshot", or "dogfood this".

### use-agentvision

See and interact with the user's real screen via the `agent-vision` CLI: screenshots, element discovery, clicks, form filling, and visual QA on live windows (browsers, simulators, native apps).

```
/plugin install use-agentvision@rvanbaalen
```

Auto-triggers on phrases like "look at my screen", "the app is open", or "fill this form" when an app is already running.

### hermes-tweet

Hermes Agent X/Twitter plugin guidance for Xquik workflows. Use it to install and operate Hermes Tweet with read-first endpoint discovery, `tweet_read` for safe reads, and `tweet_action` only after explicit approval.

```
/plugin install hermes-tweet@rvanbaalen
```

Invoke with `/hermes-tweet:hermes-tweet`.

### cloudflare-deploy

Deploy Astro sites to Cloudflare Workers with custom domains — initial setup, `wrangler` config, DNS records, and post-deploy verification.

```
/plugin install cloudflare-deploy@rvanbaalen
```

Invoke with `/cloudflare-deploy:cloudflare-deploy`.

### disk-cleanup

Multi-step macOS disk-space cleanup that runs identify → propose → execute. Covers caches, dev tooling (Docker, Node/nvm, Xcode & iOS simulators, Android SDK, Gradle, package managers), VMs, Ollama models, orphaned app data, and full app uninstalls. Every candidate is categorized by safety tier, anything that isn't pure cache is confirmed first, and Time Machine local snapshots are thinned last so the freed space is actually realized.

```
/plugin install disk-cleanup@rvanbaalen
```

Invoke with `/disk-cleanup [scope]` (manual only). Pass `help` to list all scopes.
