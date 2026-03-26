# Journal Protocol

The journal is a running log of PM-relevant events, written in real-time during sessions. It is the PM's short-term memory and the source of truth for session reconciliation.

## File Location

`<data-path>/sessions/YYYY-MM-DD-journal.md`

Use today's date. If the file already exists (multiple sessions in one day), append to it.

## Timestamp Format

Every entry starts with a wall-clock timestamp in `[HH:MM]` format. Obtain the current time by running:

```
date +%H:%M
```

## Event Types

| Prefix | When to write | Format |
|--------|--------------|--------|
| `SESSION_START` | Session begins, after context bootstrap completes | `[HH:MM] SESSION_START — intent: <what user plans to do>` |
| `SESSION_END` | Session wrapping up | `[HH:MM] SESSION_END — completed: <list>. Incomplete: <list>.` |
| `TASK_START` | User begins working on a task | `[HH:MM] TASK_START <id> — <task name>` |
| `TASK_DONE` | User confirms a task is complete | `[HH:MM] TASK_DONE <id> — <task name>` |
| `ESTIMATE` | User provides a time estimate | `[HH:MM] ESTIMATE <id> — user: <duration>, calibrated: <duration> (<reason>)` |
| `BLOCKER` | A blocker is identified | `[HH:MM] BLOCKER — <description>, blocks: <task id or "general">` |
| `BLOCKER_RESOLVED` | A blocker is resolved | `[HH:MM] BLOCKER_RESOLVED — <description>` |
| `SCOPE_CHANGE` | Tasks added, removed, or modified outside original plan | `[HH:MM] SCOPE_CHANGE — <what changed> (user accepted/rejected)` |
| `ANTI_PATTERN` | PM detects an anti-pattern | `[HH:MM] ANTI_PATTERN — <pattern_name>: <description>` |
| `OVERRULE` | User overrides PM recommendation | `[HH:MM] OVERRULE — PM recommended: <X>, user decided: <Y>` |
| `MILESTONE_UPDATE` | Milestone status changes | `[HH:MM] MILESTONE_UPDATE <id> — status: <new status>, reason: <why>` |
| `WRITE_FAILED` | A background file write failed | `[HH:MM] WRITE_FAILED — <file>: <reason>` |

## Rules

1. **Append-only.** Never rewrite, edit, or delete earlier entries during a session.
2. **Write immediately.** Do not batch entries or defer them. When an event happens, append to the journal before continuing the conversation.
3. **Every skill writes.** Any skill that changes project state must write to the journal. This is not optional.
4. **Use Edit tool to append.** Read the file first if it exists, then use Edit to append new entries at the end. If the file doesn't exist, use Write to create it with the first entry.

## Duration Calculation

To compute actual duration for a task:
- Find the `TASK_START <id>` entry timestamp
- Find the `TASK_DONE <id>` entry timestamp
- The difference is the actual duration

If a task spans multiple sessions (started one day, completed another), note this in the estimates log as "multi-session."
