#!/bin/bash
# Flag ~/Library/Application Support and ~/Library/Containers folders whose owning app
# is no longer installed. Read-only. Apple system folders (com.apple.*) are never flagged.
set -uo pipefail
H="$HOME"
idx=$(mktemp)

# Index of installed app names + bundle identifiers (lowercased).
for dir in /Applications /Applications/Utilities /System/Applications \
           /System/Applications/Utilities "$H/Applications"; do
  [ -d "$dir" ] || continue
  for app in "$dir"/*.app; do
    [ -e "$app" ] || continue
    basename "$app" .app | tr 'A-Z' 'a-z' >> "$idx"
    bid=$(/usr/bin/defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || true)
    [ -n "$bid" ] && echo "$bid" | tr 'A-Z' 'a-z' >> "$idx"
  done
done
sort -u "$idx" -o "$idx"

scan_dir() {
  local base="$1"
  [ -d "$base" ] || return
  printf '\n=== %s — folders with NO matching installed app (size | modified | name) ===\n' "${base/#$H/~}"
  {
    for d in "$base"/*; do
      [ -e "$d" ] || continue
      name=$(basename "$d")
      key=$(echo "$name" | tr 'A-Z' 'a-z')
      # never flag Apple system data (com.apple.* and well-known unprefixed system folders)
      case "$key" in
        com.apple.*|apple|crashreporter|syncservices|sesstorage|networkserviceproxy|\
        mobilesync|clouddocs|addressbook|knowledge|caches|callhistory*|com.microsoft.vscode*) continue;;
      esac
      grep -qiF -- "$key" "$idx" && continue
      tail="${key##*.}"                                    # com.foo.Bar -> bar
      [ "$tail" != "$key" ] && grep -qiF -- "$tail" "$idx" && continue
      sz=$(du -shx "$d" 2>/dev/null | cut -f1)
      mod=$(stat -f '%Sm' -t '%Y-%m-%d' "$d" 2>/dev/null)
      printf '%-8s %s  %s\n' "$sz" "$mod" "$name"
    done
  } | sort -rh
}

scan_dir "$H/Library/Application Support"
scan_dir "$H/Library/Containers"
rm -f "$idx"

cat <<'EOF'

HEURISTIC — folder names don't always map to app names, so VERIFY before deleting:
  mdfind -name "<Name>.app"      # is the app really gone?
KEEP unless the user explicitly confirms: crypto wallets, messaging apps (Signal/WhatsApp),
note/email apps, screenshot/recording tools, and anything that may hold the only copy of user data.
~/Library/Containers/* are TCC-protected — deletion needs Full Disk Access or Finder.
EOF
