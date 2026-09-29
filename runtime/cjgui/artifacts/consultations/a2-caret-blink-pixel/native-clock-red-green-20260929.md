# A2 native caret clock RED/GREEN

Date: 2026-09-29 (local)

## Scope

Focused native `CJGUI_INTERNAL_TESTING` seam coverage for two A2 failures. No product source, window routing, or STATUS file was edited. Existing normal TextInput drawable evidence remains in `normal-consumer-run.md` and `run-diagnostics.log`.

## RED

Command: `CJGUI_CARET_BLINK_TMPDIR=/private/tmp/cjgui-caret-a2-native-red zsh runtime/cjgui/native/scripts/verify_composable_caret_blink_clock.sh`

The test compiled, then exited 1 with both assertions:

- `withdrawing absent visual caret stopped active source blink`
- `late accepted-node caret declaration did not install and schedule paint-only present rect=0.00,0.00,0.00,0.00 declared=0 presents=0 accepted=7 body=0`

This establishes that the public native declaration path stopped the still-eligible TextInput blink, while a post-accept declaration only stored state and neither attached it to the accepted node nor scheduled presentation.

Raw build/test output: `native-clock-red-20260929.log` (SHA-256 `f6ed6bb2fe991dcebe9ab9db00254b06aac27949f6ac4599af6a138ae0304c6c`).

## GREEN

After the focused native change, the same command exited 0. The seam verifies that source withdrawal retains caret phase/deadline and geometry; the due phase paints hidden while preserving geometry. Late visual declaration installs the expected node-local rect `(252.7,87,1.5,21)` onto accepted node 41, schedules exactly one paint-only present, keeps accepted projection version 7 unchanged, and leaves text body generation unchanged.

Raw build/test output: `native-clock-green-20260929.log` (SHA-256 `f30ee568350a6c183af79bb4e1c47d5b721a3cc4cc4ee50f0666261a30759647`). The script compiles the production renderer and native bridge with `clang` and runs the deterministic Objective-C test; it does not activate a desktop window.

## Foreground boundary

One attempted real-window RED exited 91 because the macOS session was locked: native snapshot `key=0 app_active=0 responder=1`, accepted active identity and overlay ID both `32:1:32:5:1`, but blink target was null; drawable readback was unavailable. CUA then confirmed the locked session. This is environment-invalid and not a product RED. The process self-closed its own window and exited; no probe process remains. Raw output: `window-red-locked-20260929.log` (SHA-256 `d34dbd212ec43a878d4930a1f9d132ff9227559f0c44644c3fb22616ac90c12f`).

The parent was subsequently notified that the desktop was unlocked; the root task elected to use its persistent Pharos window for final source/visual pixel and workload verification, so this task did not repeat foreground activation.

## Source identity at GREEN

- `runtime/cjgui/native/cjgui_internal_renderer.m`: SHA-256 `ff1347e4f32dee52dfda6708f2409c64259479592eafaa3bf1e49bb701ac505f`
- `runtime/cjgui/native/tests/composable_caret_blink_clock_test.m`: SHA-256 `6772c42494433368d38df9cc0e5a3e1209ce5ddd18d5f6ac87d2d3f91f123a80`

`git diff --check` passed. No commit or staging performed.
