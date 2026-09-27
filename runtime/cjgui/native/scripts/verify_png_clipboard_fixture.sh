#!/usr/bin/env zsh
# Headless producer check on a private named pasteboard. No UI or user
# clipboard is involved; payload bytes are read from fixture files verbatim.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
OUTPUT_DIR="${CJGUI_PNG_FIXTURE_TMPDIR:-/private/tmp/cjgui-png-fixture}/$RUN_TAG"
mkdir -p "$OUTPUT_DIR"
GUARD="$OUTPUT_DIR/cjgui_clipboard_guard"
LOG="$OUTPUT_DIR/result.log"
: > "$LOG"
say() { print -r -- "$*" | tee -a "$LOG"; }
fail() { say "FAIL $*"; exit 1; }

clang -fobjc-arc -framework AppKit "$RUNTIME_DIR/native/tests/clipboard_guard.m" -o "$GUARD" \
  2>"$OUTPUT_DIR/guard-build.log" || fail "clipboard guard compile failed"
PB="cjgui-png-fixture-$RUN_TAG"
guard() { "$GUARD" "$@" --pb "$PB"; }
FIXTURE_HELPER="$RUNTIME_DIR/native/tests/png_fixture.py"

for kind in valid near-limit invalid oversized; do
  png="$OUTPUT_DIR/$kind.png"
  evidence="$(python3 "$FIXTURE_HELPER" "$kind" "$png")" \
    || fail "could not generate $kind fixture"
  bytes="$(wc -c < "$png" | tr -d ' ')"
  sha="$(shasum -a 256 "$png" | awk '{print $1}')"
  say "fixture kind=$kind source_bytes=$bytes source_sha256=$sha evidence=$evidence"

  original="$OUTPUT_DIR/$kind-original.plist"
  expected="$OUTPUT_DIR/$kind-expected.plist"
  guard start-png "$original" "$expected" "$png" \
    || fail "$kind standard PNG pasteboard write failed"
  guard is-current "$expected" \
    || fail "$kind pasteboard image did not match the original fixture bytes and changeCount"
  say "producer kind=$kind type=public.png metadata=none raw_bytes_match=true change_count_match=true"
  guard restore-if-current "$original" "$expected" >> "$LOG" 2>&1 \
    || fail "$kind conditional restore failed"
  guard status "$original" >/dev/null \
    || fail "$kind original private pasteboard image was not restored"
  say "restore kind=$kind state=original-restored"
done

# A later independent write changes the pasteboard generation. The guard must
# preserve it instead of restoring the saved fixture-era image over it.
png="$OUTPUT_DIR/valid.png"
python3 "$FIXTURE_HELPER" valid "$png" >/dev/null
original="$OUTPUT_DIR/foreign-original.plist"
expected="$OUTPUT_DIR/foreign-expected.plist"
guard start-png "$original" "$expected" "$png" || fail "foreign branch PNG write failed"
guard write-text "PNG-FOREIGN-COPY" || fail "foreign branch write failed"
guard restore-if-current "$original" "$expected" >> "$LOG" 2>&1 \
  || fail "foreign branch restore command failed"
if guard status "$original" >/dev/null 2>&1; then
  fail "foreign copy was overwritten by fixture restore"
fi
grep -q 'restored=false state=foreign' "$LOG" || fail "foreign copy refusal was not reported"
say "restore_foreign_copy=preserved"
say "PASSED png clipboard fixture producer output=$OUTPUT_DIR"
