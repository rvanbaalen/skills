---
name: use-agentvision
description: >-
  Control the user's real macOS screen via the `agent-vision` CLI. This skill contains the complete
  command reference and required workflows — without it you will not know the correct session management
  protocol, element targeting API, or interaction patterns. MUST be consulted before using agent-vision.
  Triggers: user says "look at my screen", "use agent-vision", "the app/browser/simulator is open",
  "take a screenshot of my screen", "fill this form" (when app is already open), "check the UI", "watch
  the browser", "navigate to" (in an open app), "scroll through", "click on" (in a visible window),
  "I have X open", visual QA of running applications, iOS Simulator or Android emulator interaction,
  before/after visual comparison of live UI, or any task requiring real screen capture and control.
  NOT for: headless browser testing, Playwright/Puppeteer scripts, code-only reviews, file-based
  screenshots, or building screen capture features.
---

# Agent Vision

Agent Vision is a macOS CLI tool that gives you eyes and hands on the user's screen. You can screenshot a selected region and control the mouse, keyboard, and UI elements within that region.

**Use it for**: visual feedback loops during UI development, navigating applications, filling forms, visual QA, testing mobile emulators, and any task that requires seeing and interacting with what's on screen.

> For the full CLI command reference, read `references/cli-reference.md` in this skill's directory.
> For installation instructions, read `references/install.md` in this skill's directory.

## Before You Start

Check that agent-vision is installed:

```bash
which agent-vision
```

If not found, read `references/install.md` for installation instructions and guide the user through it. The install is a simple `brew tap rvanbaalen/agent-vision && brew install agent-vision`. After install, the user needs to grant Screen Recording and Accessibility permissions in System Settings.

## Session Lifecycle

Every agent-vision interaction happens within a **session**. The session scopes all commands to a user-selected screen region.

### Starting a Session

**Preferred: Use `open` when you know which app to target:**

```bash
agent-vision open Safari
```

This launches (or activates) the app and automatically selects its window — no manual interaction needed. Use `--title "..."` to filter by window title when the app has multiple windows.

**For manual area selection:**

```bash
agent-vision start
```

This blocks until the user selects an area (via drag or window click) on the floating toolbar. Use when you need a custom region or `open` doesn't apply.

Both commands print:
- Line 1: the session UUID
- Line 2: area dimensions (e.g., `Area selected: 800x600 at (100, 200)`)

**Capture the UUID and pass it as `--session <uuid>` to every subsequent command.** Shell variables don't persist between separate Bash calls, so either store the UUID in a variable within a single chained command, or copy the literal UUID string into each command.

When using `start`, ask the user to select the area they want you to interact with. Be specific:
- "Please select the browser window showing the app"
- "Please select the area of the form you'd like me to fill out"
- "Please select the simulator window"

### Ending a Session

When done, ask the user if they'd like to stop the session before running:

```bash
agent-vision stop --session <uuid>
```

## Core Pattern: Scan, Act, Re-scan

This is the fundamental interaction loop. Every UI interaction follows it:

1. **Scan** — `agent-vision elements --session <uuid>` to discover what's on screen
2. **Act** — click, type, scroll, or press keys on the discovered elements
3. **Wait** — `sleep 0.5` (or longer for page loads) to let the UI update
4. **Re-scan** — run `elements` again because indices are now stale

Element indices change after every UI update. Never reuse indices from a previous scan.

**Filtering large scans**: Complex apps can return 80+ elements. Use `jq` to filter:

```bash
# Show only accessibility-sourced elements (skip OCR noise)
agent-vision elements --session <uuid> | jq -r '.elements[] | select(.source=="accessibility") | "\(.index): \(.role) - \"\(.label // "")\" @ (\(.center.x | floor),\(.center.y | floor))"'
```

This cuts noise dramatically and makes it easier to find the element you need.

## Element Targeting

Prefer `--element N` over `--at X,Y` in all cases where the target appears in the element scan:

- **`--element N`** (preferred): Uses the Accessibility API. Focus-free — doesn't move the cursor or steal focus from the user's active window. The user can keep working while you interact.
- **`--at X,Y`** (fallback only): Uses CGEvent. Moves the cursor and steals focus. Only use when the target genuinely isn't in the scan (canvas UIs, custom-drawn elements).

**OCR text vs interactive elements**: When the scan shows OCR `staticText`, look for a nearby accessibility element (button, link, group) that wraps that text. Click the interactive parent with `--element`, not the raw text coordinates.

## Taking Screenshots

```bash
agent-vision capture --session <uuid> --output /tmp/screenshot.png
```

After capturing, **read the PNG with the Read tool** to see what's on screen. Always describe what you see — this confirms you're looking at the right thing and builds shared understanding with the user.

For before/after comparisons:
```bash
agent-vision capture --session <uuid> --output /tmp/before.png
# ... make changes, wait for reload ...
sleep 2
agent-vision capture --session <uuid> --output /tmp/after.png
```

## Interacting with the UI

### Clicking

```bash
agent-vision elements --session <uuid>
# Find target by label/role in the JSON output
agent-vision control click --session <uuid> --element 3
```

### Typing into Fields

```bash
# Focus-free: set field value directly (replaces entire value)
agent-vision control type --session <uuid> --text "hello" --element 2

# Keystroke mode: type at cursor (requires prior focus via click)
agent-vision control type --session <uuid> --text "hello"
```

### Keyboard Shortcuts

```bash
agent-vision control key --session <uuid> --key "cmd+a"
agent-vision control key --session <uuid> --key enter
agent-vision control key --session <uuid> --key tab
```

### Scrolling

Desktop apps:
```bash
agent-vision control scroll --session <uuid> --delta 0,-300  # down
agent-vision control scroll --session <uuid> --delta 0,300   # up
```

Mobile emulators/simulators — use drag instead (touch interfaces need swipe gestures):
```bash
agent-vision control drag --session <uuid> --from 200,500 --to 200,200  # scroll down
agent-vision control drag --session <uuid> --from 200,200 --to 200,500  # scroll up
```

### Coordinate Verification (Fallback)

When you must use `--at X,Y`, verify first with `preview`:
```bash
agent-vision preview --session <uuid> --at 400,150
# Read the preview image — green dot must be ON the target
# Only then:
agent-vision control click --session <uuid> --at 400,150
```

## Delegating Execution to Subagents

For multi-step interaction sequences (form filling, multi-page navigation, repetitive UI tasks), delegate the execution to a **sonnet subagent**. This keeps the main conversation lean and lets the subagent focus on the scan-act-re-scan loop.

When delegating, provide the subagent with:
- The session UUID
- The specific goal (what to accomplish, not how to click)
- Any context about the application type
- The path to this skill's `references/cli-reference.md` for the full command reference

**Example: Delegating form filling**

```
Agent tool prompt:
"You have access to agent-vision. Use the session UUID <uuid> to fill out a form.

Read <skill-path>/references/cli-reference.md for the full CLI reference.

Your task: Fill the contact form with:
- Name: John Doe
- Email: john@example.com
- Message: Hello, I'd like to discuss pricing.

Then click Submit and capture a screenshot of the result to /tmp/form-result.png.

Follow the scan → act → re-scan pattern: run `agent-vision elements --session <uuid>` before every interaction,
and re-scan after every click or type action. Use `--element N` targeting (not --at X,Y).
After submitting, wait 1 second, capture the screen, and read the screenshot to confirm success."
```

Use `model: "sonnet"` for these subagents — they're executing a clear plan, not making architectural decisions.

**Good candidates for subagent delegation:**
- Filling forms with known data
- Navigating a multi-step wizard
- Scrolling through a list and capturing multiple screenshots
- Repetitive click-and-verify sequences
- Running the same visual check across multiple pages

**Keep in the main conversation:**
- Deciding *what* to do (strategy, interpretation)
- Analyzing screenshots for design feedback
- Communicating with the user about what you see
- Handling errors or unexpected UI states

## Sharing Files and Images via Clipboard

When you need to send a file (image, screenshot, document) into an app, **never navigate Finder**. Finder windows are difficult to control via agent-vision and frequently cause hangs. Instead, copy the file to the macOS clipboard and paste it directly:

### Sending an image (PNG/JPEG)

```bash
# Copy image to clipboard
osascript -e 'set the clipboard to (read (POSIX file "/tmp/screenshot.png") as «class PNGf»)'

# Then paste into the target app
agent-vision control key --session <uuid> --key "cmd+v"
```

This works in most apps: WhatsApp, Slack, email composers, Notion, etc. After pasting, the app will typically show a preview dialog — scan for a "Send" or "Submit" button and click it.

### Sending other file types

For non-image files, copy the file reference to the clipboard:

```bash
osascript -e 'set the clipboard to (POSIX file "/path/to/file.pdf")'
agent-vision control key --session <uuid> --key "cmd+v"
```

**Why not use the attachment button?** Clicking "Share media", "+", or attachment buttons opens a Finder dialog, which is a separate window with complex navigation. The clipboard approach bypasses this entirely and is faster, more reliable, and doesn't leave stray Finder windows open.

## Application-Specific Tips

| App Type | Key Behavior |
|----------|-------------|
| **Web browser** | Use Cmd+L for the address bar. Wait ~2s after page load for accessibility tree. |
| **Messaging app** | Use search to find contacts/chats. The active chat often changes role from `button` to `staticText` — this is normal and means it's already selected. Use clipboard paste (Cmd+V) to share images instead of the attachment button. |
| **Mobile emulator** | Use `drag` not `scroll`. Touch UIs respond to swipe gestures. |
| **Email client** | Use search bar to find emails. Rows have many overlapping elements — always use `--element`. Use clipboard paste for attachments. |
| **IDE / editor** | Use Cmd+P for quick file nav. |
| **Terminal** | Text-based — use `type` and `key` only. No clickable elements. |
| **Canvas / design tool** | Most elements won't appear in scan. Must use `--at X,Y` with `preview`. |
| **File manager** | Use path bar or search. Double-click folders to navigate. |

## Ground Rules

- **Only use agent-vision CLI commands** to interact with the UI. Do not use `open`, `osascript`, Puppeteer, Playwright, or other automation tools.
- **Do not resize, move, or rearrange windows.** Work within the selected area as-is.
- **Stay inside the selected area.** If you need something outside it, ask the user to adjust.
- **Always describe what you see** after capturing a screenshot.
- **Verify focus before typing.** Never send keystrokes without confirming the target field is focused.
- **Verify outcomes visually**, not through shell commands. After form submits, downloads, or navigation, capture and check the screen.
- **Use the application's built-in features** — search bars, menus, keyboard shortcuts — instead of brute-force scrolling.

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
3. Scan elements to check interactive controls exist
4. Click through key flows (navigation, forms, buttons)
5. Report what you find — screenshots + descriptions

### Form Filling

1. Scan elements to discover fields
2. Type into each field using `--element N`
3. Click submit
4. Capture and verify success state

### Navigating an Application

1. Scan elements to see what's available
2. Click the target (link, button, menu item)
3. Wait, re-scan, verify you arrived at the right place
4. Repeat until you reach the destination

### Sending Messages (WhatsApp, Slack, etc.)

1. Open the app with `agent-vision open WhatsApp`
2. Scan elements and find the target conversation (use search if not visible)
3. Click the conversation to open it
4. Find the `textField` element (e.g., "Compose message") and type into it with `--element N`
5. Press `enter` to send
6. To attach an image: copy to clipboard with `osascript`, then `cmd+v` to paste, then click Send in the preview dialog

### Multi-Page Screenshots

Delegate to a sonnet subagent:
1. Capture current view
2. Scroll down by a fixed amount
3. Capture again
4. Repeat until the content stops changing

## Error Handling

If a command fails, check `references/cli-reference.md` for the error reference table. Common issues:

- **Session not running** — run `agent-vision start` and have the user select an area
- **Permission errors** — ask user to grant Screen Recording / Accessibility in System Settings
- **Stale elements** — re-run `elements` before every interaction
- **Element not found** — the UI changed since the last scan, re-scan
- **`elements` command times out waiting for focus** — run `agent-vision focus --session <uuid> --timeout 10` explicitly before scanning. This can happen right after `open` if the app takes a moment to settle.
- **Session area is misaligned** — if elements have `x` values that start well inside the area (e.g., window bounds at x=400 when the area is 1046 wide), the captured area is offset from the actual window. The conversation pane or key UI regions may be cut off on the right. Fix: stop the session and re-run `agent-vision open <app>` to get a fresh, correctly aligned session.
- **OCR noise from background windows** — element scans can pick up OCR `staticText` from windows behind the target app. When filtering elements, prefer `source: "accessibility"` over `source: "ocr"` for reliable targeting. OCR results from unrelated windows will have coordinates outside the target app's bounds.

**Diagnosing alignment issues**: After starting a session, verify the area covers the full window by comparing the area dimensions against the window's accessibility bounds (element with `role: "unknown"` and the app name as label). If the window bounds extend beyond the area width, the session is misaligned.

When stuck, capture a screenshot and describe what you see to the user. Ask for their help rather than guessing wildly.
