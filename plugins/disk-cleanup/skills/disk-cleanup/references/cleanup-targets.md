# Cleanup Targets Catalog (macOS)

Per-target reference: where it lives, its safety tier, the cleaner command, and recovery cost. Tiers
match SKILL.md — **T1** safe/regenerable, **T2** confirm (recreatable but costly/opinionated),
**T3** data (never delete without specific confirmation).

## Contents
- [Caches](#caches)
- [Package managers](#package-managers)
- [Docker](#docker)
- [Node / nvm](#node--nvm)
- [Xcode & iOS Simulators](#xcode--ios-simulators)
- [Android (SDK, AVDs, Gradle)](#android-sdk-avds-gradle)
- [Ollama models](#ollama-models)
- [JetBrains IDEs](#jetbrains-ides)
- [Virtual machines](#virtual-machines)
- [Orphaned app data](#orphaned-app-data)
- [Applications](#applications)
- [Time Machine local snapshots](#time-machine-local-snapshots)
- [Full app uninstall (e.g. Microsoft Office)](#full-app-uninstall)

---

## Caches

`~/Library/Caches` (**T1**) — per-app caches; disposable by definition, cost = slower next launch.
Prefer native cleaners where they exist, else `rm -rf` the subfolder. Quit the app first for browsers.

| Subfolder | Cleaner |
|---|---|
| `Homebrew` | `brew cleanup -s` |
| `com.spotify.client`, `Google/*` (quit Chrome) | `rm -rf` |
| `JetBrains` | in-IDE *Invalidate Caches*, or `rm -rf` while IDEs closed |
| `ms-playwright`, `Cypress`, `node-gyp`, `pip`, `typescript` | `rm -rf` (re-downloads on next use) |

`~/.cache` (**T1**) — XDG cache grab-bag (uv, puppeteer, github-copilot, codex-runtimes…). Run
`uv cache clean` first if present, then remove the rest. Entire dir is regenerable.

`~/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches` (**T1**) — downloaded
dynamic/aerial wallpaper videos, often several GB. Re-downloads on demand.

## Package managers

All **T1** (regenerable download caches):

```bash
npm cache clean --force && rm -rf ~/.npm/_npx     # _npx accumulates one install per `npx pkg`
yarn cache clean                                  # or rm -rf ~/.yarn/berry/cache
uv cache clean
rm -rf ~/.cocoapods/repos/* ~/Library/Caches/CocoaPods   # re-fetched on pod install
rm -rf ~/Library/Caches/composer                  # PHP
rm -rf ~/.m2/repository                            # Maven (re-resolves)
rm -rf ~/.bun/install/cache
```

## Docker

`~/Library/Containers/com.docker.docker` — one big VM disk. **Never `rm` it**; prune from inside.

```bash
docker system df                          # see reclaimable: images / volumes / build cache
docker system prune -a -f                 # T1: stopped containers, unused images, networks, build cache
docker volume prune -a -f                 # T2: named volumes too — newer Docker's --volumes only does anonymous
```

⚠️ **Volumes are T2/T3.** Dangling volumes are usually dev-project **databases** (Laravel Sail
mysql/pgsql, etc.). They reappear + reseed on the next `compose up`, but confirm the user treats them
as disposable before pruning. After pruning, Docker Desktop usually auto-compacts `Docker.raw`; if the
host file didn't shrink, mention it may need a Docker Desktop restart.

## Node / nvm

`~/.nvm/versions/node/*` (**T2**). Keep the **default/active** (`cat ~/.nvm/alias/default`) and the
**newest of each major line** projects pin. Check pins first:

```bash
find ~/Sites -maxdepth 3 -name .nvmrc -not -path '*/node_modules/*' -exec sh -c 'echo "$(cat "$1")  $1"' _ {} \;
```

`.nvmrc` values like `20`/`22`/`24` resolve to the newest installed of that major — keep those, delete
older point releases (`rm -rf ~/.nvm/versions/node/vX.Y.Z`). Verify `node -v` still works after.

## Xcode & iOS Simulators

| Target | Tier | Action |
|---|---|---|
| `~/Library/Developer/Xcode/DerivedData` | T1 | `rm -rf` — build caches/indexes, rebuild on next compile |
| `~/Library/Developer/Xcode/iOS DeviceSupport/*` | T1 | per-device debug symbols; re-cached when you reconnect a device |
| `~/Library/Developer/CoreSimulator/Devices` | T2 | `xcrun simctl delete unavailable` (safe), or `xcrun simctl erase all` / `delete all` |
| `/Library/Developer` iOS **runtimes** | T2 | `xcrun simctl runtime list` then `xcrun simctl runtime delete <id>` — keep the current iOS, drop old ones |

System runtimes show as mounted volumes in `df` and live outside your home folder — that's why a
"home is only 191 GB but disk shows 516 GB used" gap can appear.

## Android (SDK, AVDs, Gradle)

| Target | Tier | Action |
|---|---|---|
| `~/.gradle/caches` | T1 | `rm -rf` (don't delete while a build/daemon runs); re-downloads deps |
| `~/.android/avd/*.avd` (+ `.ini`) | T2 | emulators; delete the `.avd` dir **and** its `.ini`. System images live in the SDK, so recreating is quick |
| `~/Library/Android/sdk/ndk/*` | T2 | multiple NDK versions; keep what projects pin (`grep -r ndkVersion`) |
| `~/Library/Android/sdk/system-images`, `build-tools/*` | T2 | keep current; old point releases are redundant |
| whole `~/Library/Android/sdk` | T2 | only if done with Android dev — Android Studio re-downloads on next open |

## Ollama models

`~/.ollama/models` (**T2**). List with `ollama list`; remove specific models with `ollama rm <name>`
(it keeps blobs still shared by other models). Re-pull with `ollama pull`. Watch for redundant
quantizations of the same base model.

## JetBrains IDEs

`~/Library/Application Support/JetBrains/<Product><Version>` (**T1** for old versions). Settings migrate
forward on upgrade, so per-version folders for **non-current** versions are dead weight. Confirm the
installed version (`defaults read /Applications/PhpStorm.app/Contents/Info CFBundleShortVersionString`)
and `rm -rf` the older ones. `~/Library/Caches/JetBrains` is also T1 (forces a re-index).

## Virtual machines

`~/Parallels/*.pvm`, `~/VirtualBox VMs/*`, `~/.vagrant.d/boxes` (**T3** unless confirmed disposable).
A `.pvm`/VM disk can contain an entire OS install with the user's files. **Look inside and confirm
before deleting.**

- VirtualBox: `VBoxManage list vms` — folders **not** in that list are orphaned (left by a failed
  `vagrant destroy`) and safe to `rm -rf`. Registered VMs are live; remove via
  `VBoxManage unregistervm <name> --delete` or `vagrant destroy`.
- Vagrant/Homestead dev boxes are usually reprovisionable (`vagrant up`) but that's the user's call.

## Orphaned app data

`scripts/find-orphan-app-data.sh` flags `~/Library/Application Support` and `~/Library/Containers`
folders with no matching installed app (excludes `com.apple.*`). **T2/T3 — verify and confirm:**

- Confirm the app is truly gone: `mdfind -name "<App>.app"`.
- **Keep** crypto wallets (Atomic, MyCrypto, Ledger Live…), messaging (Signal/WhatsApp), email/notes,
  Postman (saved collections), screenshot/recording tools — these hold real, often irreplaceable data.
- `~/Library/Containers/*` are TCC-protected; deletion needs Full Disk Access or Finder (see below).

## Applications

`/Applications` (**T2/T3**). Biggest offenders are usually games and creative apps. Apps are often
**root-owned** → `sudo rm -rf "/Applications/<App>.app"`, or drag to Trash in Finder (prompts for
admin). Confirm before removing anything with a license or local project data.

## Time Machine local snapshots

**The finale, and usually the biggest single win.** `scripts/thin-snapshots.sh` lists and deletes
local snapshots so previously-deleted bytes return to free space. These are *local* restore points
only — real Time Machine backups on the backup destination are untouched, and macOS recreates hourly
snapshots afterward. If free space looks wrong after a big cleanup, this is almost always why.

```bash
tmutil listlocalsnapshots /                       # how many are holding space
bash scripts/thin-snapshots.sh                    # delete them, report before/after free space
# manual single: tmutil deletelocalsnapshots <YYYY-MM-DD-HHMMSS>   (sudo if needed)
```

## Full app uninstall

For a complete uninstall (apps + all data + system daemons/helpers), Microsoft Office is the worked
example — same shape applies to other multi-component suites.

1. **Map the footprint** by bundle-id, excluding apps you keep (e.g. VS Code = `com.microsoft.VSCode`):
   ```bash
   for app in /Applications/*.app; do
     bid=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null)
     case "$bid" in com.microsoft.*) echo "$bid  $app";; esac
   done
   find ~/Library/{Containers,Group\ Containers,Caches,Preferences} -maxdepth 1 \
        -iname 'com.microsoft.*' ! -iname '*vscode*' 2>/dev/null
   ```
2. **Remove what you can without elevation:** Group Containers, Caches, Application Support, Preferences
   (always exclude the kept app, e.g. `! -iname '*vscode*'`). **Do not** delete the *shared* Office
   group container or auth (`UBF8T346G9.oneauth`) if any MS app remains — it forces re-login for the rest.
3. **Hand off the permission-gated core** as one pasteable `sudo` block (hardcode `/Users/<user>`, not
   `~`, since `$HOME` flips under sudo). It removes root-owned `.app`s, `~/Library/Containers/*`
   (needs **Full Disk Access** on the terminal — grant it, then fully quit + reopen the terminal),
   `launchctl bootout` + delete `/Library/LaunchDaemons|LaunchAgents/com.microsoft.*` and
   `/Library/PrivilegedHelperTools/com.microsoft.*`, and `/Library/Application Support/Microsoft/MAU2.0`.
   `rm -rf` deletes container *contents* even when the protected top folder + its
   `.com.apple.containermanagerd.metadata.plist` can't be removed — so what's left is empty KB-sized
   husks the user can drag to Trash. Optionally clear "Microsoft Office Identities" from Keychain Access.

> The TCC wall on `~/Library/Containers` is the recurring gotcha: even root can't delete the metadata
> plist without Full Disk Access. Finder (drag to Trash) is the reliable no-setup path.
