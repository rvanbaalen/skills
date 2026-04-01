# Installing Agent Vision

## Requirements

- macOS 14+ (Sonoma), Apple Silicon
- Xcode 16+ (builds from source via Homebrew)

## Install via Homebrew

```bash
brew tap rvanbaalen/agent-vision
brew install agent-vision
```

## Post-install: Grant Permissions

After installing, the user must grant two permissions in **System Settings > Privacy & Security**:

1. **Screen Recording** — allows agent-vision to capture screenshots
2. **Accessibility** — allows agent-vision to discover UI elements and send input

Without these, `capture` and `elements` commands will fail with permission errors.

## Verify Installation

```bash
agent-vision --help
```

If this prints the help text, the install succeeded.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `command not found: agent-vision` | Run `brew tap rvanbaalen/agent-vision && brew install agent-vision` |
| `Screen capture failed — no image returned` | Grant Screen Recording permission in System Settings |
| `Accessibility permission required` | Grant Accessibility permission in System Settings |
| Permissions granted but still failing | Restart the terminal / agent after granting permissions |
