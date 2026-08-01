# browse

Fast persistent headless browser CLI for QA testing and site dogfooding, packaged as a standalone Claude Code plugin.

## Credits

This plugin is a standalone extraction of the **browse** skill from [gstack](https://github.com/garrytan/gstack) by **Garry Tan**, redistributed under the MIT license (see [LICENSE](./LICENSE)). All browser engine code (`src/`, `bin/`, `extension/`, `scripts/`) is Garry Tan's work from gstack v1.60.1 (one added extension-path candidate for the plugin layout). The packaging (plugin manifest, setup script, SKILL.md adaptation) strips the gstack-specific preamble (telemetry, config, upgrade checks) so the skill runs on its own.

If you want the full suite — QA workflows, design review, ship pipeline, and more — install [gstack](https://github.com/garrytan/gstack) itself.

## What it does

- Persistent headless Chromium daemon: first call ~3s, then ~100ms per command
- Accessibility-tree snapshots with `@e` refs for clicking/filling without brittle selectors
- Before/after snapshot diffs, annotated screenshots, responsive screenshots
- Form filling, uploads, dialogs, iframes, tabs, cookies, storage
- Local HTML rasterization (`load-html`, `js --out`) for cards, diagrams, og-images
- Headed mode (`connect`, with bundled sidebar extension) and handoff to the user for CAPTCHAs and MFA, resuming with full state
- SOCKS5/HTTP proxy support with a local auth bridge

## Setup

Requires [bun](https://bun.sh). One-time build:

```bash
./setup
```

This installs dependencies, ensures Playwright Chromium is present, and compiles the CLI to `dist/browse`. The skill prompts for this automatically on first use.
