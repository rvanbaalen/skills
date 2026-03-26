# Self-Reflect Validation Rules

These rules are checked by the self-reflect agent before any file write executes. The agent receives the proposed action, the relevant conversation context, and this rule set.

## Rules

### 1. Estimates Must Come From the User

**Check:** Any `ESTIMATE` journal entry or `tasks.md` row with an estimate value must trace back to a number the user explicitly stated in the conversation.

**Violation:** The PM invented an estimate without asking, or used a number the user didn't provide.

**Response:** `INVALID: Estimate for <task> was not provided by the user. Ask the user: "How long do you think <task> will take?"`

### 2. Task Completion Must Be User-Confirmed

**Check:** Any `TASK_DONE` journal entry or status change to `done` in `tasks.md` must correspond to the user confirming the task is complete.

**Violation:** The PM marked a task done based on its own assessment without user confirmation.

**Response:** `INVALID: Task <id> marked done without user confirmation. Ask the user: "Is <task> complete?"`

### 3. Scope Changes Require User Consent

**Check:** Any `SCOPE_CHANGE` journal entry that adds, removes, or significantly modifies a task must include user agreement.

**Violation:** The PM added or removed tasks unilaterally.

**Response:** `INVALID: Scope change not confirmed by user. Present the change and ask for confirmation.`

### 4. Deadlines Require User Input

**Check:** Any deadline assigned to a task or milestone must trace back to a date the user provided or agreed to.

**Violation:** The PM assigned a deadline without user input.

**Response:** `INVALID: Deadline for <task/milestone> was not provided by the user. Ask: "When does this need to be done?"`

### 5. Actuals Computed From Timestamps

**Check:** Any actual duration in `estimates.md` must be calculable from `TASK_START` and `TASK_DONE` timestamps in the journal.

**Violation:** The PM guessed or estimated the actual time instead of computing it.

**Response:** `INVALID: Actual duration for <task> does not match journal timestamps. Recompute from TASK_START and TASK_DONE entries.`

## How to Apply

The self-reflect agent receives:
1. **Proposed action** — the journal entry or file update about to be written
2. **Conversation excerpt** — the relevant user messages that should support the action
3. **This rule set**

For each proposed action, check all applicable rules. Return:
- `VALID` — all rules pass, proceed with file write
- `INVALID: <reason>` — cite the specific rule violated and what the PM should do instead
