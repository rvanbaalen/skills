# Application-Specific Tips

Behaviors and shortcuts that change how you interact with specific app types via agent-vision.

| App Type | Key Behavior |
|----------|-------------|
| **Web browser** | Use `Cmd+L` for the address bar. Wait ~2s after page load for the accessibility tree to populate. |
| **Messaging app** | Use search to find contacts/chats. The active chat often changes role from `button` to `staticText` — this is normal and means it's already selected. Use clipboard paste (`Cmd+V`) to share images instead of the attachment button. See `clipboard.md`. |
| **Mobile emulator** | Use `drag`, not `scroll`. Touch UIs respond to swipe gestures, not wheel events. |
| **Email client** | Use the search bar to find emails. Rows have many overlapping elements — always target with `--element N`. Use clipboard paste for attachments. |
| **IDE / editor** | Use `Cmd+P` (or equivalent) for quick file navigation instead of clicking through file trees. |
| **Terminal** | Text-based — use `type` and `key` only. No clickable elements appear in scans. |
| **Canvas / design tool** | Most elements won't appear in scans. Use `--at X,Y` with `preview` to verify coordinates before clicking. |
| **File manager** | Use the path bar or search. Double-click folders to navigate. Prefer clipboard workflows over Finder navigation — see `clipboard.md`. |
