#!/bin/bash
# validate-after-edit.sh
#
# PostToolUse hook for Edit/Write: runs the docblock validator against the
# file that was just modified. If it finds Rule 4 violations (more than 3
# prose lines or non-descending line lengths), the violations are fed back
# to Claude via stderr + exit 2 so it knows to rewrite the docblock.
#
# Only validates source files in languages the validator parses (JSDoc
# /** ... */ form). Anything else exits 0 silently.

set -euo pipefail

input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

if [[ -z "$file_path" ]]; then
  exit 0
fi

case "$tool_name" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.php|*.java|*.kt|*.kts|*.swift|*.cs|*.cpp|*.cc|*.cxx|*.hpp|*.h|*.c|*.rs) ;;
  *) exit 0 ;;
esac

if [[ ! -r "$file_path" ]]; then
  exit 0
fi

if ! command -v node >/dev/null 2>&1; then
  exit 0
fi

validator="${CLAUDE_PLUGIN_ROOT}/skills/comment-conventions/scripts/validate-docblocks.mjs"
if [[ ! -f "$validator" ]]; then
  exit 0
fi

output=$(node "$validator" "$file_path" 2>&1) || rc=$?
rc=${rc:-0}

if [[ "$rc" -eq 0 ]]; then
  exit 0
fi

printf 'comment-conventions: Rule 4 violations in %s — rewrite the docblock so each prose line is strictly shorter than the previous one, and the prose stays within 3 source lines. Pack lines as full as the column width allows; choose wrap points (not sentence breaks) to create the descending shape.\n\n%s\n' "$file_path" "$output" >&2
exit 2
