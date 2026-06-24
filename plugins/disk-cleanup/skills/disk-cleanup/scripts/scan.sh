#!/bin/bash
# Read-only disk-space identification scan for macOS.
# Makes NO changes. Output feeds the "Propose" phase of the disk-cleanup skill.
set -uo pipefail
H="$HOME"

hr() { printf '\n=== %s ===\n' "$1"; }

hr "REAL FREE SPACE (the Data volume — NOT 'df /', which is the sealed read-only system volume)"
df -h /System/Volumes/Data | awk 'NR==1 || /Data$/'
purge=$(diskutil info /System/Volumes/Data 2>/dev/null | awk -F'[()]' '/Purgeable/ {print $2; exit}')
[ -n "${purge:-}" ] && echo "Purgeable (reclaimable, usually snapshot-held): $purge"

hr "TIME MACHINE LOCAL SNAPSHOTS (the #1 reason deletions don't free space)"
n=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c '\.local' || true)
echo "local snapshot count: ${n:-0}"
if [ "${n:-0}" -gt 0 ]; then
  echo "NOTE: these retain previously-deleted data. After deleting things, run scripts/thin-snapshots.sh"
  echo "      LAST to actually release the space. Without this, free space barely moves."
fi

hr "HOME — biggest top-level items"
du -hx -d 1 "$H" 2>/dev/null | sort -rh | head -25

hr "KNOWN DEV / CACHE / VM TARGETS (only ones present, largest first)"
targets=(
  "$H/Library/Caches|app & tool caches (regenerable)"
  "$H/Library/Developer/Xcode|Xcode DerivedData + iOS DeviceSupport"
  "$H/Library/Developer/CoreSimulator|iOS Simulator devices"
  "$H/Library/Containers/com.docker.docker|Docker VM disk (prune, don't rm)"
  "$H/Library/Application Support|app data (MIXED — run find-orphan-app-data.sh)"
  "$H/Library/Android/sdk|Android SDK (NDK/system-images/build-tools)"
  "$H/.android|Android emulators (AVDs)"
  "$H/.gradle|Gradle caches"
  "$H/.ollama|Ollama local LLM models"
  "$H/.cache|generic XDG caches (uv, puppeteer, etc.)"
  "$H/.npm|npm cache + _npx"
  "$H/.nvm|installed Node versions"
  "$H/.yarn|Yarn cache"
  "$H/.bun|Bun cache"
  "$H/.m2|Maven cache"
  "$H/.cocoapods|CocoaPods cache"
  "$H/.vagrant.d|Vagrant boxes"
  "$H/VirtualBox VMs|VirtualBox VMs (⚠ may hold data)"
  "$H/Parallels|Parallels VMs (⚠ may hold data)"
  "/Library/Developer|system iOS Simulator runtimes"
)
{
  for t in "${targets[@]}"; do
    p="${t%%|*}"; d="${t#*|}"
    [ -e "$p" ] && printf '%-8s %-45s %s\n' "$(du -shx "$p" 2>/dev/null | cut -f1)" "${p/#$H/~}" "$d"
  done
} | sort -rh

hr "BIGGEST APPS in /Applications"
du -shx /Applications/* 2>/dev/null | sort -rh | head -12

printf '\nScan complete — nothing was deleted. Next: categorize by safety tier and propose (see SKILL.md).\n'
