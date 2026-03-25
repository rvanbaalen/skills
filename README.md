# Skills

Public Claude Code skills by Robin van Baalen.

## Setup

```
/plugin marketplace add rvanbaalen/skills
```

## Install individual skills

```
/plugin install commit@rvanbaalen
/plugin install lottie-animator@rvanbaalen
/plugin install make-issue@rvanbaalen
/plugin install ocr-document-processor@rvanbaalen
/plugin install svg-precision@rvanbaalen
/plugin install time-registration@rvanbaalen
/plugin install version-bump@rvanbaalen
/plugin install driverjs-guide@rvanbaalen
/plugin install cofounder@rvanbaalen
/plugin install pm@rvanbaalen
```

## Skills

| Skill | Description | Invoke |
|-------|-------------|--------|
| `commit` | Micro-commit with conventional commit messages | `/rvanbaalen:commit` |
| `driverjs-guide` | Driver.js product tours, onboarding flows, and element highlighting | auto-triggered |
| `lottie-animator` | Generate professional Lottie animations from static SVGs | `/rvanbaalen:lottie-animator` |
| `make-issue` | Create a GitHub issue with template, type, and label selection | `/rvanbaalen:make-issue` |
| `ocr-document-processor` | Extract text from images and scanned PDFs using OCR | `/rvanbaalen:ocr-document-processor` |
| `svg-precision` | Deterministic SVG generation, validation, and rendering | `/rvanbaalen:svg-precision` |
| `time-registration` | Git-based time registration summaries | `/rvanbaalen:time-registration` |
| `version-bump` | Auto-suggest semver version bumps for changed plugins before pushing | `/rvanbaalen:version-bump` |

## Cofounder

A critical-thinking business co-founder agent that enforces prioritization, challenges assumptions, and becomes smarter the more you use it. Includes onboarding, check-in cadences, idea sparring, action briefs, and progress review.

```
/plugin install cofounder@rvanbaalen
```

Then type `/cofounder` to start. First run triggers onboarding automatically.

| Skill | Description | Invoke |
|-------|-------------|--------|
| `cofounder` | Orchestrator — entry point, spawns the agent | `/cofounder:cofounder` |
| `setup` | Onboarding and reconfiguration | `/cofounder:setup` |
| `check-in` | Daily, weekly, monthly, quarterly cadences | `/cofounder:check-in` |
| `spar` | Stress-test ideas through the business filter | `/cofounder:spar` |
| `action-brief` | Create scoped action briefs | `/cofounder:action-brief` |
| `review` | Review state, progress, and priorities | `/cofounder:review` |

## PM

A delivery-focused project manager agent that enforces deadlines, tracks estimates vs. actuals, detects anti-patterns (scope creep, gold plating, yak shaving, etc.), and holds you accountable. Adapts tone based on timeline pressure — supportive when there's slack, blunt when you're overdue.

```
/plugin install pm@rvanbaalen
```

Then type `/pm` to start. First run triggers project setup automatically.

| Skill | Description | Invoke |
|-------|-------------|--------|
| `pm` | Orchestrator — entry point, spawns the agent | `/pm:pm` |
| `setup` | Project onboarding and reconfiguration | `/pm:setup` |
| `plan` | Define milestones, tasks, and estimates | `/pm:plan` |
| `session-start` | Beginning-of-session check-in | `/pm:session-start` |
| `session-end` | End-of-session wrap-up with estimate tracking | `/pm:session-end` |
| `review` | Progress analysis, estimation accuracy, overrule tracking | `/pm:review` |
| `reprioritize` | Reshuffle tasks to protect deadlines | `/pm:reprioritize` |
| `status-report` | Export-ready status for clients, teams, or personal logs | `/pm:status-report` |
