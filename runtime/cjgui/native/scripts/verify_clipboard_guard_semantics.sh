#!/usr/bin/env zsh
# Headless acceptance for the general-pasteboard guard contract.
#
# Every branch runs on a PRIVATE named pasteboard, so this script is safe to
# run while the user is working and never reads or writes the general
# clipboard. It fixes the semantics the isolation driver relies on:
#
#   1. snapshot -> own write -> conditional restore restores the original;
#   2. a foreign value written after ours is preserved (restore refuses);
#   3. fixture recovery restores the saved original only while the live value
#      is still exactly this harness's fixture text, and refuses anything else;
#   4. `status` compares every advertised type and raw byte payload, so a
#      text-only comparison cannot pass for a different clipboard image.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_CLIPBOARD_GUARD_TMPDIR:-/private/tmp/cjgui-clipboard-guard}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
RESULT_LOG="$WORK/result.log"
: > "$RESULT_LOG"
say() { print -r -- "$*" >> "$RESULT_LOG"; }
fail() { say "FAIL $*"; cat "$RESULT_LOG"; exit 1; }

GUARD="$WORK/cjgui_clipboard_guard"
clang -fobjc-arc -framework AppKit "$RUNTIME_DIR/native/tests/clipboard_guard.m" -o "$GUARD" 2>"$WORK/guard-build.log" \
  || fail "guard build failed"
PB="cjgui-clipboard-guard-$RUN_TAG"
guard() { "$GUARD" "$@" --pb "$PB"; }

ORIGINAL="$WORK/original.plist"
EXPECTED="$WORK/expected.plist"

# --- 1. own write + conditional restore ------------------------------------
guard start-text "$ORIGINAL" "$EXPECTED" || fail "start-text failed"
guard is-current "$EXPECTED" >/dev/null || fail "own write did not become current"
guard restore-if-current "$ORIGINAL" "$EXPECTED" >> "$WORK/guard.log" 2>&1 || fail "conditional restore failed"
guard status "$ORIGINAL" >/dev/null || fail "conditional restore did not restore the original"
say "guard_ok own_write_conditional_restore"

# --- 2. foreign value after ours is preserved ------------------------------
guard start-text "$ORIGINAL" "$EXPECTED" || fail "start-text (foreign branch) failed"
guard write-text "PB-FOREIGN" || fail "foreign write failed"
guard restore-if-current "$ORIGINAL" "$EXPECTED" >> "$WORK/guard.log" 2>&1 || true
if guard status "$EXPECTED" >/dev/null 2>&1; then
  fail "foreign branch: our expected value survived the restore attempt"
fi
if guard status "$ORIGINAL" >/dev/null 2>&1; then
  fail "foreign branch: restore overwrote the foreign value with the original"
fi
grep -q "restored=false state=foreign" "$WORK/guard.log" || fail "foreign branch: guard did not report foreign"
say "guard_ok foreign_value_preserved"

# --- 3. fixture recovery only for our own leaked fixture -------------------
guard start-text "$ORIGINAL" "$EXPECTED" || fail "start-text (fixture branch) failed"
guard write-text "FIXTURE-LEAK" || fail "fixture write failed"
guard restore-fixture "$ORIGINAL" "FIXTURE-LEAK" >> "$WORK/guard.log" 2>&1 || fail "fixture recovery failed"
guard status "$ORIGINAL" >/dev/null || fail "fixture recovery did not restore the original"
say "guard_ok own_fixture_recovered"

guard start-text "$ORIGINAL" "$EXPECTED" || fail "start-text (fixture refusal) failed"
guard write-text "FOREIGN-AFTER-LEAK" || fail "foreign write (fixture refusal) failed"
guard restore-fixture "$ORIGINAL" "FIXTURE-LEAK" >> "$WORK/guard.log" 2>&1 || true
guard status "$ORIGINAL" >/dev/null 2>&1 && fail "fixture recovery overwrote a foreign value"
guard is-current "$EXPECTED" >/dev/null 2>&1 && guard status "$EXPECTED" >/dev/null 2>&1
guard status "$EXPECTED" >/dev/null 2>&1 && fail "fixture refusal: expected value unexpectedly current"
grep -q "fixture_restore=false state=foreign" "$WORK/guard.log" || fail "fixture refusal was not reported as foreign"
say "guard_ok foreign_value_not_overwritten_by_fixture_recovery"

# --- 4. status is a full-type/raw-byte comparison --------------------------
# The same plain string with one additional advertised type must not compare
# equal to a text-only snapshot.
guard start-text "$ORIGINAL" "$EXPECTED" || fail "start-text (type comparison) failed"
guard write-text-with-extra-type "external-text" "org.cangjie.cjgui.test.extra" \
  || fail "typed fixture write failed"
guard status "$EXPECTED" >/dev/null 2>&1 && fail "full-type status matched a different pasteboard image"
say "guard_ok status_compares_all_types_and_bytes"

say "PASSED clipboard guard semantics"
cat "$RESULT_LOG"
exit 0
