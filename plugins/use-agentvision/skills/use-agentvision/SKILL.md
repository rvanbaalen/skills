---
name: use-agentvision
description: >-
  Control the user's real macOS screen via the `agent-vision` CLI — session management, element
  targeting, and UI interaction on live windows. Triggers: user says "look at my screen", "use
  agent-vision", "the app/browser/simulator is open", "take a screenshot of my screen", "fill this
  form" (when app is already open), "check the UI", "watch the browser", "navigate to" (in an open
  app), "scroll through", "click on" (in a visible window), "I have X open", visual QA of running
  applications, iOS Simulator or Android emulator interaction, before/after visual comparison of
  live UI, or any task requiring real screen capture and control.
  NOT for: headless browser testing, Playwright/Puppeteer scripts, code-only reviews, file-based
  screenshots, or building screen capture features.
allowed-tools: Bash(agent-vision:*), Bash(sleep:*), Bash(osascript:*), Bash(which:*), Bash(jq:*)
---

# Agent Vision

Agent Vision is a macOS CLI that gives you eyes and hands on the user's screen. You can screenshot a selected region and control the mouse, keyboard, and UI elements within that region.

**Use it for**: visual feedback loops during UI development, navigating applications, filling forms, visual QA, testing mobile emulators, and any task that requires seeing and interacting with what's on screen.

> Reference files in this skill's directory:
> - `references/cli-reference.md` — full command syntax, flags, and error table
> - `references/app-tips.md` — per-app behaviors and shortcuts
> - `references/clipboard.md` — sharing files into apps via the macOS clipboard
> - `references/install.md` — install and permission setup

## Before You Start

Check that agent-vision is installed:

```bash
which agent-vision
```

If not found, read `references/install.md` and guide the user through it (`brew install rvanbaalen/tap/agent-vision` + Screen Recording + Accessibility permissions).

## Session Lifecycle

Every agent-vision interaction happens within a **session** that scopes all commands to a user-selected screen region.

### Starting a session

**Preferred — `open` when you know the app:**

```bash
agent-vision open Safari
# add --title "..." to disambiguate multiple windows of the same app
```

Launches (or activates) the app and automatically selects its window. No manual interaction required.

**Manual area selection — `start`:**

```bash
agent-vision start
```

Blocks until the user drags or clicks to select an area. Use this for custom regions or when `open` doesn't apply. Tell the user exactly what to select: "Please select the browser window showing the app" — not just "please select an area".

Both commands print:
- Line 1: the session UUID
- Line 2: area dimensions (e.g., `Area selected: 800x600 at (100, 200)`)

**Capture the UUID and pass it as `--session <uuid>` to every subsequent command.** Shell variables don't persist between separate Bash calls — either chain commands in a single call, or paste the literal UUID into each command.

### Ending a session

When done, confirm with the user before stopping:

```bash
agent-vision stop --session <uuid>
```

## Core Pattern: Scan, Act, Re-scan

Every UI interaction follows this loop:

1. **Scan** — `agent-vision elements --session <uuid>` to discover what's on screen
2. **Act** — click, type, scroll, or press keys on a discovered element
3. **Wait** — `sleep 0.5` (or longer for page loads) to let the UI update
4. **Re-scan** — run `elements` again before the next interaction

**Element indices change after every UI update. Never reuse indices from a previous scan.**

### Filtering large scans

Complex apps can return 80+ elements. Use `jq` to cut OCR noise and focus on interactive elements:

```bash
agent-vision elements --session <uuid> | jq -r '.elements[] | select(.source=="accessibility") | "\(.index): \(.role) - \"\(.label // "")\" @ (\(.center.x | floor),\(.center.y | floor))"'
```

## Element Targeting

Prefer `--element N` over `--at X,Y` whenever the target appears in the scan:

- **`--element N`** (preferred): Accessibility API. **Focus-free** — doesn't move the cursor or steal focus. The user can keep working in another window while you interact.
- **`--at X,Y`** (fallback): CGEvent. Moves the cursor and steals focus. Only use when the target genuinely isn't in the scan (canvas UIs, custom-drawn elements).

**OCR text vs interactive elements**: if the scan shows OCR `staticText`, look for a nearby accessibility element (button, link, group) that wraps that text. Click the interactive parent with `--element`, not the raw text coordinates.

**Coordinate verification when using `--at`**: always preview first.

```bash
agent-vision preview --session <uuid> --at 400,150
# Read the preview PNG — the green dot must land on the target before you click.
```

See `references/cli-reference.md` for the full syntax of `click`, `type`, `key`, `scroll`, and `drag`.

## Taking Screenshots

```bash
agent-vision capture --session <uuid> --output /tmp/screenshot.png
```

After capturing, **read the PNG with the Read tool** and describe what you see. This confirms you're looking at the right thing and builds shared understanding with the user.

Before/after comparisons:

```bash
agent-vision capture --session <uuid> --output /tmp/before.png
# ...make changes, wait for reload...
sleep 2
agent-vision capture --session <uuid> --output /tmp/after.png
```

## Sharing Files into Apps

When an app needs an image or file attachment, **don't navigate Finder via agent-vision** — it's unreliable and the dialogs are hard to target. Copy to clipboard with `osascript` and paste with `Cmd+V` instead. See `references/clipboard.md` for the full recipe.

## Delegating Long Flows to Background Subagents

For multi-step sequences (form filling, multi-page navigation, repetitive UI tasks), dispatch a sonnet subagent with `run_in_background: true` and stream its progress with the **Monitor** tool. This keeps the main conversation lean, lets the user see what the subagent is doing in real time, and frees the main thread to handle other work.

**Pattern:**

1. Spawn the subagent with `subagent_type: "general-purpose"`, `model: "sonnet"`, `run_in_background: true`.
2. Instruct it to emit one-line progress markers with `echo` after each milestone:
   - `echo "scanned 42 elements"`
   - `echo "clicked Submit"`
   - `echo "captured /tmp/result.png"`
3. Use `Monitor` on the returned agent ID — each echo becomes a notification you can surface to the user.

**Example Agent prompt for a background form-filler:**

```
You have access to agent-vision. Use session UUID <uuid> to fill and submit a contact form.

Read <skill-path>/references/cli-reference.md for the full CLI.

Task:
- Name: John Doe
- Email: john@example.com
- Message: Hello, I'd like to discuss pricing.

Rules:
- Follow scan → act → re-scan. Run `agent-vision elements --session <uuid>` before every interaction.
- Use `--element N` targeting, not `--at X,Y`.
- After every step, echo a one-line progress marker (e.g., `echo "typed into Name field"`) so the
  parent agent can stream your progress via Monitor.
- After submitting, `sleep 1`, capture `/tmp/form-result.png`, and Read it to confirm success.
- Echo "done" as your final line.
```

**Do not use Monitor** to replace the `sleep` calls inside the scan-act-re-scan loop — those are timed UI settle waits with no stream for Monitor to consume.

### When to delegate vs keep in main

**Delegate (background subagent + Monitor):**
- Filling forms with known data
- Navigating a multi-step wizard
- Scrolling through a list and capturing multiple screenshots
- Repetitive click-and-verify sequences
- Running the same visual check across multiple pages

**Keep in main:**
- Deciding *what* to do (strategy, interpretation)
- Analyzing screenshots for design feedback
- Communicating with the user about what you see
- Handling errors or unexpected UI states

## Application-Specific Tips

See `references/app-tips.md` for per-app behaviors (browsers, messaging apps, mobile emulators, IDEs, terminals, canvas tools, file managers).

## Ground Rules

- **Use agent-vision for UI interaction.** Don't drive the UI with `open`, Puppeteer, Playwright, or other automation tools. `osascript` is allowed *only* for the clipboard recipes in `references/clipboard.md`.
- **Do not resize, move, or rearrange windows.** Work within the selected area as-is.
- **Stay inside the selected area.** If you need something outside it, ask the user to adjust.
- **Always describe what you see** after capturing a screenshot.
- **Verify focus before typing** when not using `--element`. Never send blind keystrokes.
- **Verify outcomes visually**, not through shell commands. After form submits, downloads, or navigation, capture and check the screen.
- **Use the app's built-in features** — search bars, menus, keyboard shortcuts — instead of brute-force scrolling.

## Common Workflows

### UI Development Feedback Loop

1. Capture reference state (`before.png`)
2. Make code changes
3. Wait for hot reload / refresh
4. Capture result (`after.png`)
5. Read both to compare, iterate

### Visual QA

1. Start session, ask user to select the app
2. Capture the full view
3. Scan elements to verify interactive controls exist
4. Click through key flows (navigation, forms, buttons)
5. Report findings — screenshots + descriptions

### Form Filling

1. Scan elements to discover fields
2. Type into each with `--element N`
3. Click submit
4. Capture and verify success state

### Navigating an Application

1. Scan elements to see what's available
2. Click the target (link, button, menu item)
3. Wait, re-scan, verify you arrived at the right place
4. Repeat until you reach the destination

### Sending Messages (WhatsApp, Slack, etc.)

1. `agent-vision open WhatsApp`
2. Scan and find the target conversation (use search if not visible)
3. Click the conversation to open it
4. Type into the `textField` with `--element N`
5. Press `enter` to send
6. To attach an image: see `references/clipboard.md`

### Multi-Page Screenshots

Delegate to a background subagent (see Delegating Long Flows):
1. Capture current view
2. Scroll down by a fixed amount
3. Capture again
4. Echo progress; repeat until content stops changing

## Error Handling

See the error table in `references/cli-reference.md` for the full list. Most common:

- **Session not running** — run `agent-vision start` and have the user select an area
- **Permission errors** — ask user to grant Screen Recording / Accessibility in System Settings
- **Stale elements** — re-run `elements` before every interaction
- **Element not found** — UI changed since the last scan; re-scan
- **`elements` times out waiting for focus** — run `agent-vision focus --session <uuid> --timeout 10` explicitly. Can happen right after `open` if the app is still settling.
- **Session area misaligned** — if element `x` values start well inside the area (e.g., window bounds at x=400 when the area is 1046 wide), the captured area is offset from the window. Stop the session and re-run `agent-vision open <app>` for a fresh alignment.
- **OCR noise from background windows** — element scans can pick up OCR `staticText` from windows behind the target app. Filter by `source: "accessibility"` for reliable targeting. Unrelated OCR results will have coordinates outside the target app's bounds.

When stuck, capture a screenshot, describe what you see, and ask the user for help rather than guessing.
