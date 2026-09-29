# Zoho Invoice time registration

Reference for the time-registration skill when a Zoho Invoice MCP server is connected. `SKILL.md` step 2 runs the setup, step 10 writes the entries.

## Detecting the MCP

Zoho is available when the session has a tool whose name ends in `ZohoInvoice_Log_a_Time_Entry` (the prefix depends on how the server is connected, e.g. `mcp__claude_ai_ZohoMCP__`). The tools may be deferred: search for `ZohoInvoice` with the tool-search tool to load them before calling. The tools used here all share that prefix:

- `ZohoInvoice_List_all_Organizations`
- `ZohoInvoice_Get_the_Current_User`
- `ZohoInvoice_List_all_Projects`
- `ZohoInvoice_List_all_Tasks_of_a_Project`
- `ZohoInvoice_List_all_Time_Entries`
- `ZohoInvoice_Log_a_Time_Entry`
- `ZohoInvoice_Update_a_Time_Entry`

Every call except `List_all_Organizations` needs the `X-com-zoho-invoice-organizationid` header.

## First-time setup

Run once per project, when Zoho is available and the project's entry in `projects.json` has no `output` yet. Every choice here belongs to that one project: another project gets its own setup, whatever was answered before. Ask each question with `AskUserQuestion`.

1. **Use Zoho?** `Log time for <project> in Zoho Invoice?` with `Yes, log to Zoho` / `No, just summarize`. On "No", save `"output": "clipboard"` and stop the setup. Future runs summarize and offer the clipboard without asking about Zoho again.
2. **Organization.** Call `List_all_Organizations`. With one organization, use it. With several, ask which, defaulting to the one with `is_default_org: true`.
3. **User.** Call `Get_the_Current_User` and keep `user.user_id`. Don't ask.
4. **Project.** Call `List_all_Projects` with `filter_by: Status.Active`. Score each Zoho project against the local project: its name, its repo folder names and its parent folder (e.g. local `celery` ↔ customer `Celery Payroll`). Match on `customer_name` as well as `project_name`. Among projects for the same customer, prefer `can_be_invoiced: true`, then the newest `created_time`: a client often has one current project per year or quarter, with older ones already invoiced. Offer the best match first, marked "(Recommended)", with up to three runners-up, as `<project_name> — <customer_name>`.
5. **Task.** Call `List_all_Tasks_of_a_Project` for the chosen project and ask which task to log under by default. Recommend the active task with the most logged hours (`log_time`).
6. **Tool approval.** See below. Only asked when the MCP's tool prefix isn't the one the skill pre-approves.

Save the answers on the project's entry in `projects.json` and confirm in one line (`Zoho: Freelance werk 2026 — Celery Payroll, task Development`):

```json
{
  "projects": {
    "acme": {
      "repos": ["/Users/me/Sites/acme/web-app"],
      "output": "zoho",
      "zoho": {
        "organization_id": "825391651",
        "user_id": "4405026000000078001",
        "project_id": "4405026000000477007",
        "project_name": "Freelance werk 2026",
        "customer_name": "Acme",
        "task_id": "4405026000000477027",
        "task_name": "Development",
        "tool_prefix": "mcp__claude_ai_ZohoMCP__"
      }
    }
  }
}
```

### Tool approval under another MCP name

The skill's `allowed-tools` pre-approve the read tools under the prefix `mcp__claude_ai_ZohoMCP__` only. Someone who connected Zoho under another name (e.g. `mcp__zoho__`) gets a permission prompt on every read. Take the prefix from the detected `…ZohoInvoice_Log_a_Time_Entry` tool name and save it as `tool_prefix`. If it differs from `mcp__claude_ai_ZohoMCP__`, ask once: `Pre-approve Zoho's read-only tools for this project?` with `Yes, pre-approve` / `No, keep asking`.

On "Yes", add these five names with the detected prefix to `permissions.allow` in `.claude/settings.local.json` of every repo in the project (personal settings, not checked in), merging into what is already there rather than overwriting:

- `<prefix>ZohoInvoice_List_all_Organizations`
- `<prefix>ZohoInvoice_Get_the_Current_User`
- `<prefix>ZohoInvoice_List_all_Projects`
- `<prefix>ZohoInvoice_List_all_Tasks_of_a_Project`
- `<prefix>ZohoInvoice_List_all_Time_Entries`

Never pre-approve `Log_a_Time_Entry` or `Update_a_Time_Entry`: writes keep their prompt. Save `"tool_approval": "done"` or `"declined"` next to `tool_prefix` so the question isn't asked again. If a later run detects a prefix other than the saved `tool_prefix` (Zoho reconnected under a new name), update `tool_prefix` and ask again. A repo added to the project later gets the same entries without asking when `tool_approval` is `done`.

### Changing the setup

When the user later asks to change the Zoho project or task, or to stop or start logging to Zoho, update these fields. When a new period's project replaces the saved one (e.g. a new year's project for the same client), the setup's project question can be rerun on request.

## Writing entries

Zoho gets one time entry per day with work. For a multi-day period, summarize each day separately (`SKILL.md` steps 8–9, per day) and log each day as its own entry. Days with no work get no entry.

### 1. Check for existing entries

Call `List_all_Time_Entries` with the project, `user_id`, `filter_by: Date.CustomDate`, `from_date` and `to_date` spanning the window. For a day that already has an entry, ask: `Update the existing entry`, `Add a second entry` or `Skip this day`. Show the existing note and hours so the user can decide.

### 2. Estimate hours and confirm

Zoho needs a duration; git doesn't record one. Estimate per day from the span between the first and last activity timestamps found in steps 5–7 (commit author dates, reflog entries, session prompts), leaving out gaps longer than an hour, rounded to the nearest half hour. It is a starting point, not a fact: always let the user set the hours.

Show a preview per day, then ask with `AskUserQuestion`:

```
2026-09-28 · Development · Freelance werk 2026
Addressed review feedback on OAuth login, implemented CSV export for reports
```

- Question: `Hours for 2026-09-28?`
- Options: the estimate (e.g. `6:00 (estimated)`), estimate + 1h, estimate − 1h (not below 0:30), and `Skip this day`. "Other" takes any other duration or a different task.

With several days, ask about up to four days in one `AskUserQuestion` call.

### 3. Log

Call `Log_a_Time_Entry` (or `Update_a_Time_Entry` with the existing `time_entry_id` when the user chose to update):

- `project_id`, `task_id`, `user_id` from the saved config
- `log_date` as `YYYY-MM-DD`. The tool's description says `yyyy-dd-mm`; that's wrong, and existing entries use `YYYY-MM-DD`.
- `log_time` as `HH:mm` (`6:30` → `06:30`)
- `notes`: that day's summary line, at most 500 characters. Shorten by merging items rather than cutting mid-sentence.
- `is_billable`: leave it out, so the project's default applies

Don't retry a refused write with different arguments; report the error.

### 4. Finish with the timesheet link

End the run with one line per logged day (`Logged 06:00 on 2026-09-28.`) and the project's timesheet URL, built from the saved IDs:

```
https://invoice.zoho.com/app/<organization_id>#/timesheet/projects/<project_id>/timesheet?filter_by=Status.All%2CDate.<range>
```

Pick `<range>` from the month of the logged days, compared to today: `ThisMonth` for this month, `PreviousMonth` for last month, `All` for anything older. When the logged days span more than one of these (e.g. Sep 30 and Oct 1, logged on Oct 1), give one link per range, so every logged entry is visible behind a link.

Don't offer the clipboard in Zoho mode.

If Zoho isn't available in a later run but the project's `output` is `zoho` (server disconnected), say so, and fall back to the clipboard offer without changing the saved choice.
