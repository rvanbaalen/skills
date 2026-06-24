---
name: disk-cleanup
description: >-
  Multi-step macOS disk-space cleanup that runs identify → propose → execute. Manual-only: invoke
  explicitly via /disk-cleanup. Frees space without losing data — covers caches, dev tooling (Docker,
  Node/nvm, Xcode & iOS simulators, Android SDK, Gradle, package managers), VMs, Ollama models,
  orphaned data from uninstalled apps, and full app uninstalls. Categorizes every candidate by safety
  tier, confirms anything that isn't pure cache, and thins Time Machine local snapshots last so the
  freed space is actually realized.
disable-model-invocation: true
argument-hint: "[scope | help — e.g. docker, xcode, node, apps, all; 'help' lists all scopes]"
---

# Disk Cleanup (macOS)

Free up disk space in three phases — **Identify → Propose → Execute** — without losing anything that
matters. The whole point of this skill is to be *aggressive about regenerable junk* and *careful about
real data*. Never delete in bulk; categorize first, confirm anything that isn't pure cache, and finish
by realizing the space (snapshots — see Phase 3).

## Scopes

`$ARGUMENTS` selects what to clean. With **no argument**, run the full `all` flow. If the argument is
`help`, `list`, `scopes`, `?`, or `--help`, **print this table and stop — do not scan**:

| Scope | Cleans |
|---|---|
| `all` (default) | everything below — full identify → propose → execute |
| `caches` | `~/Library/Caches`, `~/.cache`, package-manager caches |
| `docker` | unused images, build cache, dangling volumes |
| `node` | nvm Node versions + npm / yarn / bun caches |
| `xcode` | DerivedData, iOS DeviceSupport, simulators, old runtimes |
| `android` | SDK (NDK / system-images / build-tools), AVDs, Gradle caches |
| `ollama` | local LLM models |
| `jetbrains` | old per-version IDE config + caches |
| `vms` | Parallels / VirtualBox / Vagrant |
| `apps` | biggest apps, orphaned app data, full uninstalls |
| `snapshots` | thin Time Machine local snapshots (realize freed space) |

For a named scope, run the identify pass for just that area, then propose and execute scoped to it.
For an **unrecognized** argument, show this table and ask which they meant rather than guessing.

## Principles (internalize these — they prevent the two classic failures)

1. **Measure real free space, not `df /`.** `/` is the sealed read-only system volume and always looks
   ~full/empty. The number that matters is the **Data** volume: `df -h /System/Volumes/Data`.
2. **Time Machine local snapshots hide reclaimed space.** When you delete files that exist in a local
   snapshot, macOS keeps the bytes until the snapshot is purged. So you can delete 100 GB and watch
   free space *not move* — or even drop, if something else downloaded in the meantime. **Always thin
   snapshots LAST** (`scripts/thin-snapshots.sh`) and re-measure. This is usually the single biggest win.
3. **Look before you delete.** Inspect a target before removing it. If what you find contradicts how it
   was described — "leftover Parallels folder" turns out to be a 36 GB Windows VM with the user's files
   inside — stop and surface it instead of proceeding. You didn't create it; treat it as theirs.
4. **Tier everything by safety, and confirm anything above tier 1** (see Phase 2). Pure regenerable
   cache can go freely. Data is irreversible — get explicit buy-in.
5. **Prefer tool-native cleaners over `rm`.** `brew cleanup`, `docker system prune`, `npm cache clean`,
   `uv cache clean`, `xcrun simctl delete`, `ollama rm` — they remove the right things and keep their
   own bookkeeping consistent. Raw `rm` is the fallback, not the default.
6. **Report honestly.** Show before/after free space. If space didn't move, investigate (snapshots? a
   background download?) rather than claiming success.

## Phase 1 — Identify (read-only)

Run the scan scripts. They make no changes.

```bash
bash scripts/scan.sh                  # real free space, snapshot count, home + known targets, big apps
bash scripts/find-orphan-app-data.sh  # ~/Library data for apps that are no longer installed
```

Then drill into whatever's big and ambiguous with `du -shx <dir>` / `du -hx -d 1 <dir> | sort -rh`.
For multi-GB items you don't recognize, look *inside* before proposing deletion (principle 3).

Reach for `references/cleanup-targets.md` — a catalog of every common target with its location, safety
tier, the exact cleaner command, and what re-downloading/rebuilding costs. Use it to interpret the scan
and to copy the right command in Phase 3.

## Phase 2 — Propose (categorize, then ask)

Group findings into safety tiers and present a compact table (size · what it is · tier · recovery cost).

- **Tier 1 — Safe / regenerable.** Caches, build artifacts, package-manager downloads, old tool
  versions, dangling Docker images/build cache, stale snapshots. Delete freely; you may batch these.
- **Tier 2 — Confirm: recreatable but costly or opinionated.** Whole SDKs, all simulators/AVDs, Docker
  volumes (dev databases), Ollama models, full app uninstalls. Recreatable, but the user should choose
  scope. Use `AskUserQuestion` with clear options (orphaned-only / latest-kept / everything).
- **Tier 3 — Data: never delete without explicit, specific confirmation.** VMs (Parallels/VirtualBox)
  whose disk may hold files, crypto-wallet data, messaging history (Signal/WhatsApp), Postman
  collections, screenshots/recordings, user media, anything irreplaceable. Surface what's inside; if in
  doubt, recommend keeping.

Rules for proposing:
- **Never bulk-delete Tier 2/3.** One confirmation per meaningful decision.
- **For version stacks, keep the current + latest and respect project pins.** Before pruning Node
  versions check `.nvmrc` files; before pruning NDK/build-tools check what projects pin; keep the
  default and the newest of each major line.
- **Cross-reference orphans against reality.** A folder named like an app you removed is a candidate,
  but verify with `mdfind -name "<App>.app"` before deleting — names don't always map cleanly.
- Lead with the biggest safe wins. Call out the snapshot situation up front if free space looks tight.

## Phase 3 — Execute (tool-native, confirm-gated, then realize the space)

Run the approved deletions, preferring the native cleaner for each target (full command list in
`references/cleanup-targets.md`). A few that matter:

```bash
brew cleanup -s                                   # Homebrew downloads
npm cache clean --force && rm -rf ~/.npm/_npx     # npm cache + npx installs
uv cache clean; yarn cache clean                  # uv / Yarn
docker system prune -a -f && docker volume prune -a -f   # images+cache, THEN named volumes (Tier 2 — confirm)
xcrun simctl delete unavailable                   # simulators for runtimes you no longer have
xcrun simctl runtime delete <id>                  # old iOS runtimes (keep the current one)
ollama rm <model>                                 # specific local LLM models
```

Then the parts with walls and the finale:

- **Version stacks** (Node, JetBrains per-version config, NDK, iOS runtimes): delete all but the
  current + latest you confirmed keeping.
- **Permission walls** — explain and hand off rather than fight them:
  - **Root-owned apps** in `/Applications` → the user runs `sudo rm -rf "/Applications/<App>.app"`
    (suggest they paste it with a leading `! ` so it runs in-session).
  - **`~/Library/Containers/*`** are TCC-protected → even `sudo` fails without **Full Disk Access** on
    the terminal. Offer Finder (drag to Trash — has the entitlement) or granting FDA then re-running
    (FDA only applies after the terminal is fully quit and reopened).
- **THE FINALE — realize the space.** After deletions, thin local snapshots and re-measure:

  ```bash
  bash scripts/thin-snapshots.sh
  ```

  Report before/after free space on the Data volume. If it didn't move as expected, investigate
  (lingering snapshots, a background download like a media/cloud sync) — don't claim a win you can't see.

For a complete, end-to-end app uninstall (e.g. Microsoft Office) including system daemons/helpers and
the FDA-gated containers, see the "Full app uninstall" section of `references/cleanup-targets.md`.

## Safety guardrails (always)

- Confirm before anything Tier 2/3. When unsure which tier, treat it as higher.
- Don't touch `com.apple.*` system folders, the Office *shared* containers while other MS apps remain,
  or `~/Library/Containers/com.microsoft.VSCode`-style data for apps the user is keeping.
- Quote paths with spaces; on a no-match glob in zsh, run scripts via `bash` (the bundled scripts already do).
- Never propose disabling SIP or `commit.gpgsign`-style settings to "make deletion easier."
