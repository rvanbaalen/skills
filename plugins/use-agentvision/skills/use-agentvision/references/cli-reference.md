# Agent Vision CLI Reference

## Table of Contents

- [Session Management](#session-management)
- [Screenshots](#screenshots)
- [Element Discovery](#element-discovery)
- [Control Commands](#control-commands)
- [Coordinate System](#coordinate-system)
- [Error Reference](#error-reference)

---

## Session Management

### `agent-vision open <application> [--title TITLE] [--timeout N]`

**Preferred way to start a session.** Opens (or activates) an application by name and starts a session with its window automatically selected. No manual interaction required. Use `--title` to filter by window title substring (case-insensitive) when the app has multiple windows. Default timeout: 60s. Output format is the same as `start`.

```
a1b2c3d4-e5f6-7890-abcd-ef1234567890
Area selected: 1200x800 at (0, 38)
```

### `agent-vision start [--timeout N]`

Creates a session and launches the GUI. Blocks until the user manually selects an area. Prints session UUID (first line) and area dimensions (second line). Default timeout: 60s. Use this when you need manual area selection or `open` doesn't apply.

```
a1b2c3d4-e5f6-7890-abcd-ef1234567890
Area selected: 800x600 at (100, 200)
```

### `agent-vision list`

Lists active sessions.

### `agent-vision focus --session <uuid> [--timeout N]`

Waits for the session window to have keyboard focus. Polls with exponential backoff. Still available for explicit use, but control commands now auto-wait for focus so this is rarely needed.

### `agent-vision stop --session <uuid>`

Stops the session and cleans up state.

---

## Screenshots

### `agent-vision capture --session <uuid> [--output PATH]`

Captures the selected area as PNG. Prints absolute file path to stdout. Saves to temp file if `--output` not specified.

### `agent-vision calibrate --session <uuid> [--output PATH]`

Captures with four crosshair markers at known coordinates. Fallback for when element discovery doesn't work.

### `agent-vision preview --session <uuid> --at X,Y [--output PATH]`

Captures with a green crosshair drawn at X,Y without clicking. Use to verify coordinates before executing a click.

---

## Element Discovery

### `agent-vision elements --session <uuid> [--annotated] [--output PATH]`

Discovers interactive elements using the macOS Accessibility API and Vision OCR. Prints JSON to stdout.

**`--annotated`** flag saves a screenshot with numbered badges on each element (blue = accessibility-sourced, orange = OCR-sourced). Screenshot path is printed to stderr.

Output format:
```json
{
  "area": { "x": 100, "y": 200, "width": 800, "height": 600 },
  "elementCount": 5,
  "elements": [
    {
      "index": 1,
      "source": "accessibility",
      "role": "button",
      "label": "Submit",
      "center": { "x": 400, "y": 150 },
      "bounds": { "x": 350, "y": 130, "width": 100, "height": 40 }
    }
  ]
}
```

---

## Control Commands

**Auto-wait for focus:** CGEvent control commands (`--at`, `type` without `--element`, `key`, `scroll`, `drag`) auto-wait for the window to have keyboard focus before executing. Default timeout: 120s, overridable with `--focus-timeout N`. Element-based actions (`--element N`) are focus-free and execute immediately.

### `agent-vision control click --session <uuid> [--element N | --at X,Y] [--focus-timeout N]`

Left-click. Two targeting modes:
- **`--element N`** (preferred): Uses Accessibility API directly. Focus-free — does not move the cursor or steal focus.
- **`--at X,Y`** (fallback): Uses CGEvent. Moves cursor and steals focus. Only use when the element isn't in the scan.

### `agent-vision control type --session <uuid> --text TEXT [--element N]`

Type text into a field.
- **With `--element N`**: Sets the field value directly via Accessibility API. Focus-free. Replaces the entire field value (does not append).
- **Without `--element`**: Types individual keystrokes at the current cursor position. Requires prior focus via click.

### `agent-vision control key --session <uuid> --key KEY`

Press a key or combination.
- Named keys: `enter`, `tab`, `escape`, `space`, `delete`, `backspace`, `up`, `down`, `left`, `right`, `home`, `end`
- Modifiers: `cmd+`, `shift+`, `alt+`, `ctrl+` (combinable: `cmd+shift+a`)
- Single characters: a-z, 0-9

### `agent-vision control scroll --session <uuid> --delta DX,DY [--at X,Y]`

Scroll by pixel delta. Negative Y = scroll down, positive Y = scroll up. Position defaults to center of area if `--at` not specified.

### `agent-vision control drag --session <uuid> --from X,Y --to X,Y`

Click-and-drag between two points. Use for mobile simulator swipe gestures (touch interfaces don't respond to scroll events).

---

## Coordinate System

- All positions are relative to the **top-left** of the selected area
- `(0, 0)` = top-left corner; `(width-1, height-1)` = bottom-right corner
- Screenshot pixels map 1:1 to click coordinates
- All coordinates are bounds-checked; out-of-bounds actions are rejected

---

## Error Reference

| Error | What To Do |
|-------|-----------|
| `No element scan found` | Run `elements` before using `--element` |
| `Element N not found` | Index out of range — re-run `elements` |
| `Stale scan: capture area changed` | Area was reselected — re-run `elements` |
| `Specify either --at or --element, not both` | Use one targeting mode |
| `coordinates are outside the selected area` | Check X,Y against area dimensions |
| `Accessibility permission required` | Grant Accessibility permission in System Settings |
| `Screen capture failed — no image returned` | Grant Screen Recording permission in System Settings |
| `action timed out` | GUI may not be responding — ask user to check |
| `Session is not running` | Run `agent-vision start` first |
| `No area selected` | Run `agent-vision start` — blocks until area selected |
| `Invalid session ID` | Check UUID format — use exact output from `start` |
| `Session not found` | Session was stopped or expired — run `start` again |
| `unknown key` | Check supported key names above |
