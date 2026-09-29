# A2 isolated normal TextInput blink run

- Date: 2026-09-29 12:02 local
- Process: PID 22030, executable `/private/tmp/cjgui-caret-blink-consumer-build/text_caret_geometry_probe`; launcher/wrapper PID 22003.
- Invocation: `CJGUI_TEST_CARET_BLINK_DIAGNOSTICS=1 DYLD_LIBRARY_PATH=/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/runtime/lib/darwin_aarch64_cjnative /private/tmp/cjgui-caret-blink-consumer-build/text_caret_geometry_probe --blink-only`
- Result: process exit 0; its only window self-closed. No unrelated app/window was touched.
- Evidence: `run-diagnostics.log`.

At `focus_exit` and each clock action, the snapshot had `key=1 visible=1 mini=0 app_active=1 responder=1 editable=1 marked=0 selection=5:0`; active identity `32:1:32:5:1` matched the accepted overlay node and Metal-view node, the node pointers were identical, and `target_is_overlay=1`. This run did not reproduce the preceding target-eligibility failure.

The actual drawable sample for the caret rectangle changed from white while stopped/hidden (`255,255,255`) to blue while visible (`0,34,175`), then returned to blue on the next visible phase. The public byte-17 accepted geometry stayed `x=125.507812,y=6,w=1.5,h=18`. All six body work measurements remained constant: raster `1 count / 122880 bytes / 585 us`; upload `1 count / 122880 bytes / 31 us`.

The native logs show focus at frame 1, hidden transition submitted at frame 2, visible start at frame 3, hidden tick at frame 4, visible tick at frame 5, and cleanup by frame 6. This proves drawable phase changes and stable body work for this normal field. This run did not exercise focus loss or prove timer cancellation after defocus.
