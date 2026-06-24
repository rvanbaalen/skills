#!/bin/bash
# Delete local Time Machine snapshots to release space held by previously-deleted files.
# These are LOCAL restore points only — real Time Machine backups on the backup
# destination are untouched. macOS recreates hourly snapshots afterward.
# Run this LAST, after deletions, or freed space won't show up in df.
set -uo pipefail

free_now() { df -h /System/Volumes/Data | awk '/Data$/{print $4" free, "$5" used"}'; }

echo "Before: $(free_now)"
snaps=$(tmutil listlocalsnapshots / 2>/dev/null | sed -n 's/.*TimeMachine\.\(.*\)\.local/\1/p')
if [ -z "$snaps" ]; then echo "No local snapshots to thin."; exit 0; fi

count=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  if tmutil deletelocalsnapshots "$s" >/dev/null 2>&1; then
    echo "deleted snapshot $s"; count=$((count + 1))
  else
    echo "could not delete $s — retry with: sudo tmutil deletelocalsnapshots $s"
  fi
done <<< "$snaps"

echo "Deleted $count snapshot(s)."
echo "After:  $(free_now)"
