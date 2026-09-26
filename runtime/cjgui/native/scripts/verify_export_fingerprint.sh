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

# Negative controls: the checks above are only meaningful if a mutated payload is
# really caught. Each case copies the export and mutates ONE path.
#
#  * an author-identical file must make the checker FAIL (exported bytes no longer
#    equal the author original) - covering paths that were previously outside the
#    list (the framework package cjpm.toml, a consumer launcher);
#  * a missing rewritten entry must make it FAIL (existence);
#  * a rewritten entry has no author counterpart, so a mutation is caught by its
#    EFFECT: the aggregate fingerprint must change, which proves the entry's final
#    content and relative path really are part of the hashed payload.
NEGATIVE_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-fingerprint-negative.XXXXXX")"
cleanup() { rm -rf "$NEGATIVE_PARENT"; }
trap cleanup EXIT HUP INT TERM
BASELINE_SHA="$(print -r -- "$summary" | sed -n 's/.*sha256=\([0-9a-f]\{64\}\).*/\1/p')"
[[ -n "$BASELINE_SHA" ]] || {
  print -r -- "FAIL could not read the baseline aggregate fingerprint" >&2
  exit 1
}

copy_export_for_case() { # copy_export_for_case <label> -> path on stdout
  local case_root="$NEGATIVE_PARENT/$1"
  rm -rf "$case_root"
  cp -R "$export_root" "$case_root" || return 1
  print -r -- "$case_root"
}

expect_mutation_rejected() { # expect_mutation_rejected <label> <relative> <append|delete>
  local label="$1" relative="$2" mode="$3" case_root
  case_root="$(copy_export_for_case "$label")" || {
    print -r -- "FAIL negative case $label could not copy the export" >&2
    exit 1
  }
  if [[ "$mode" == "delete" ]]; then
    rm -f "$case_root/$relative"
  elif [[ "$mode" == "add" ]]; then
    print -r -- "# file that nobody declared in the payload list" > "$case_root/$relative"
  else
    print -r -- "# fingerprint negative mutation" >> "$case_root/$relative"
  fi
  if python3 "$SCRIPT_DIR/export_fingerprint.py" "$case_root" "$RUNTIME_DIR" "$REPOSITORY_ROOT" \
      > /dev/null 2>&1; then
    print -r -- "FAIL fingerprint accepted a mutated payload: $label ($relative)" >&2
    exit 1
  fi
  print -r -- "negative_ok case=$label mutation=$mode path=$relative rejected=true"
}

expect_rewrite_change_hashed() { # expect_rewrite_change_hashed <label> <relative>
  local label="$1" relative="$2" case_root case_summary case_sha
  case_root="$(copy_export_for_case "$label")" || {
    print -r -- "FAIL negative case $label could not copy the export" >&2
    exit 1
  }
  print -r -- "# fingerprint negative mutation" >> "$case_root/$relative"
  case_summary="$(python3 "$SCRIPT_DIR/export_fingerprint.py" \
    "$case_root" "$RUNTIME_DIR" "$REPOSITORY_ROOT" | head -1)" || {
    print -r -- "FAIL negative case $label did not produce a fingerprint" >&2
    exit 1
  }
  case_sha="$(print -r -- "$case_summary" | sed -n 's/.*sha256=\([0-9a-f]\{64\}\).*/\1/p')"
  if [[ "$case_sha" == "$BASELINE_SHA" ]]; then
    print -r -- "FAIL rewritten entry $relative is not part of the hashed payload" >&2
    exit 1
  fi
  print -r -- "negative_ok case=$label mutation=append path=$relative aggregate_changed=true"
}

expect_mutation_rejected framework_cjpm_toml framework/cjgui/cjpm.toml append
expect_mutation_rejected consumer_launcher consumers/rule_set_window_app/cjgui_macos_app.sh append
expect_mutation_rejected missing_manifest preview-manifest.md delete
# Set reconciliation: a file the export really carries but nobody declared must
# be discovered instead of quietly shrinking/expanding the payload.
expect_mutation_rejected undeclared_new_file framework/cjgui/src/undeclared_extra.cj add
expect_rewrite_change_hashed rewritten_consumer_cjpm consumers/rule_set_window_app/cjpm.toml
expect_rewrite_change_hashed rewritten_manifest preview-manifest.md
print -r -- "PASSED fingerprint negative controls (4 mutations rejected, 2 rewrites hashed)"
exit 0
