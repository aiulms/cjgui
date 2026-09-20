#!/usr/bin/env zsh
# Fast, GUI-free check of the framework preview export's byte identity and
# fingerprint. It runs the SAME checker the export chain uses
# (native/scripts/export_fingerprint.py), so a changed path list or a drifted
# export is caught without re-running the whole desktop chain.
#
# Usage: verify_export_fingerprint.sh [export-root]
#   default export-root: the newest "$CJGUI_PREVIEW_CHAIN_TMPDIR"/cjgui preview */export
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPOSITORY_ROOT="$(cd "$RUNTIME_DIR/../.." && pwd)"
EXPORT_PARENT="${CJGUI_PREVIEW_CHAIN_TMPDIR:-/private/tmp/cjgui-preview-chains}"

export_root="${1:-}"
if [[ -z "$export_root" ]]; then
  export_root="$(print -r -- "$EXPORT_PARENT"/cjgui\ preview\ */export(Nom[1]) 2>/dev/null || true)"
fi
[[ -n "$export_root" && -d "$export_root" ]] || {
  print -r -- "FAIL no export root to check (pass one explicitly)" >&2
  exit 1
}

print -r -- "checking export_root='$export_root'"
report="$(python3 "$SCRIPT_DIR/export_fingerprint.py" "$export_root" "$RUNTIME_DIR" "$REPOSITORY_ROOT")"
rc=$?
if (( rc != 0 )); then
  print -r -- "FAIL export fingerprint check failed for '$export_root'" >&2
  exit 1
fi
summary="$(print -r -- "$report" | head -1)"
files="$(print -r -- "$summary" | sed -n 's/^files=\([0-9]*\).*/\1/p')"
hashed_lines="$(print -r -- "$report" | tail -n +2 | grep -c '^file ' || true)"
if [[ "$files" != "$hashed_lines" ]]; then
  print -r -- "FAIL fingerprint file count $files != hashed input lines $hashed_lines" >&2
  exit 1
fi
print -r -- "$report"
print -r -- "PASSED export fingerprint (files=$files matches $hashed_lines per-file hash inputs)"
exit 0
