# Sharing Files and Images via Clipboard

When you need to send a file (image, screenshot, document) into an app, **never navigate Finder**. Finder windows are difficult to control via agent-vision and frequently cause hangs. Instead, copy the file to the macOS clipboard with `osascript` and paste it directly with `Cmd+V`.

> This is the only approved use of `osascript` in this skill. All UI interaction still goes through `agent-vision`.

## Sending an image (PNG/JPEG)

Copy the image data to the clipboard, then paste into the target app:

```bash
osascript -e 'set the clipboard to (read (POSIX file "/tmp/screenshot.png") as «class PNGf»)'
agent-vision control key --session <uuid> --key "cmd+v"
```

Works in WhatsApp, Slack, email composers, Notion, iMessage, and most apps with rich-text input. After pasting, the app typically shows a preview/confirm dialog — scan elements and click the **Send** or **Submit** button.

## Sending other file types

For non-image files (PDFs, videos, archives), copy a file reference instead of raw data:

```bash
osascript -e 'set the clipboard to (POSIX file "/path/to/file.pdf")'
agent-vision control key --session <uuid> --key "cmd+v"
```

## Why avoid the attachment button

Clicking "Share media", "+", or paperclip icons opens a Finder dialog in a separate window with complex navigation. The clipboard approach:

- Bypasses Finder entirely
- Is faster and more reliable
- Doesn't leave stray Finder windows open behind your target app
- Works consistently across apps
