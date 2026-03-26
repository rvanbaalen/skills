# Estimation Protocol

Estimates MUST come from the user. The PM NEVER invents estimates. This is a hard rule enforced by the self-reflect agent.

## Flow for Every New Task

1. **Ask the user.** Before assigning any estimate to a task, ask: "How long do you think <task name> will take?"
2. **Wait for their answer.** Do not proceed until the user provides a number.
3. **Apply calibration** (if data exists):
   - **Cold start (< 5 completed tasks in `estimates.md`):** Add a 1.5x buffer. Tell the user: "I'm adding a 1.5x buffer since we're still calibrating — penciling in <calibrated>."
   - **Calibrated (5+ completed tasks):** Look up the per-category ratio in `estimates.md`. Apply it. Tell the user: "Your <category> estimates run <ratio>x historically. I'd suggest <calibrated> instead of <raw>."
4. **Journal the estimate:** `[HH:MM] ESTIMATE <id> — user: <raw>, calibrated: <calibrated> (<reason>)`
5. **Store in `tasks.md`:** The `Estimate` column gets the user's raw estimate. The calibrated number is used for timeline planning only — it does not go in the table.

## What Goes Where

| Data point | Where it's stored |
|-----------|-------------------|
| User's raw estimate | `tasks.md` Estimate column |
| Calibrated estimate | PM's internal timeline calculations only (not persisted in a file) |
| Actual duration | Computed from journal timestamps (TASK_START to TASK_DONE) |
| Accuracy tracking | `estimates.md` — User Est, Actual, Ratio columns |

## Batch Planning Exception

When planning multiple tasks at once (e.g., breaking a milestone into 10 tasks), asking for individual estimates per task is tedious. In this case:

1. Present the full task list to the user first.
2. Ask: "Can you estimate each of these? Rough numbers are fine."
3. Let the user provide estimates in bulk (e.g., "T4 30m, T5 30m, T6 20m, T7 20m...").
4. Apply calibration to each and present the summary.
5. Journal each estimate individually.

The PM may suggest groupings or flag outliers, but the numbers must originate from the user.

## Violations

The self-reflect agent will reject any of these:
- `ESTIMATE` journal entry where the duration doesn't match a number the user said
- A task added to `tasks.md` with an estimate that the user never provided
- An `estimates.md` row where the actual duration doesn't match journal timestamps
