#!/usr/bin/env zsh
#
# 维护注释：本脚本执行 bounded AppKit visible-order smoke first slice。
# Truth: 只在临时 probe 内触发 NSApplication / NSWindow / NSView /
# visible order / bounded run loop / auto-close cleanup；不接 Metal，不请求
# drawable，不创建 encoder/draw/commit/present，不输出 production truth。
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui stage134 visible order smoke probe: macOS is required" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-stage134-visible-order-smoke.XXXXXX")"
PROBE_SOURCE="$OUTPUT_DIR/visible_order_smoke_probe.m"
PROBE_BINARY="$OUTPUT_DIR/visible_order_smoke_probe"
CLANG_CACHE_DIR="$OUTPUT_DIR/clang-cache"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

cleanup() {
  rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT
mkdir -p "$CLANG_CACHE_DIR"

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui stage134 visible order smoke probe: clang not found" >&2
  exit 3
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui stage134 visible order smoke probe: SDKROOT not found" >&2
  exit 4
fi

cat > "$PROBE_SOURCE" <<'OBJC'
#import <AppKit/AppKit.h>
#include <stdio.h>

static void print_bool(const char *key, int value) {
  printf("%s=%s\n", key, value ? "true" : "false");
}

static void pump_bounded_run_loop(NSTimeInterval seconds) {
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:seconds];
  while ([deadline timeIntervalSinceNow] > 0.0) {
    @autoreleasepool {
      NSDate *slice = [NSDate dateWithTimeIntervalSinceNow:0.01];
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:slice];
    }
  }
}

int main(void) {
  int ok = 1;
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    int app_observed = app != nil;
    int activation_policy_set = 0;
    if (app != nil) {
      [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
      activation_policy_set = 1;
    }

    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(120.0, 120.0, 180.0, 120.0)
                  styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                    backing:NSBackingStoreBuffered
                      defer:NO];
    NSView *view =
        [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 180.0, 120.0)];
    int window_created = window != nil;
    int view_created = view != nil;
    int content_view_attached = 0;
    int visible_order_called = 0;
    int visible_order_observed = 0;
    int auto_close_cleanup_observed = 0;

    if (window != nil && view != nil) {
      [window setTitle:@"cjgui visible order smoke"];
      [window setReleasedWhenClosed:NO];
      [window setContentView:view];
      content_view_attached = window.contentView == view;
      [window makeKeyAndOrderFront:nil];
      visible_order_called = 1;
      [window displayIfNeeded];
      [view displayIfNeeded];
      pump_bounded_run_loop(0.20);
      visible_order_observed = [window isVisible] ? 1 : 0;
      [window orderOut:nil];
      [window close];
      pump_bounded_run_loop(0.05);
      auto_close_cleanup_observed = [window isVisible] ? 0 : 1;
    }

    ok = app_observed && activation_policy_set && window_created &&
      view_created && content_view_attached && visible_order_called &&
      visible_order_observed && auto_close_cleanup_observed;

    print_bool("nsapplication_shared_application_observed", app_observed);
    print_bool("activation_policy_set", activation_policy_set);
    print_bool("nswindow_created", window_created);
    print_bool("nsview_created", view_created);
    print_bool("nsview_content_view_attached", content_view_attached);
    print_bool("visible_order_smoke_called", visible_order_called);
    print_bool("visible_order_smoke_observed", visible_order_observed);
    print_bool("visible_order_auto_close_cleanup_observed", auto_close_cleanup_observed);
    print_bool("metal_device_required", 0);
    print_bool("drawable_requested", 0);
    print_bool("render_command_encoder_created", 0);
    print_bool("draw_called", 0);
    print_bool("commit_called", 0);
    print_bool("present_called", 0);
    print_bool("first_frame_observed", 0);
    print_bool("renderer_state_write", 0);
    print_bool("runtime_state_write", 0);
    printf("visible_order_smoke_failure_domain=%s\n", ok ? "none" : "appkit_visible_order_unavailable");
    printf("visible_order_smoke_probe=%s\n", ok ? "passed" : "classified_host_or_session_limit");
  }
  return ok ? 0 : 20;
}
OBJC

if ! "$CLANG_BIN" -fobjc-arc \
  -isysroot "$CJ_GUI_SDKROOT" \
  -fmodules \
  -fmodules-cache-path="$CLANG_CACHE_DIR" \
  "$PROBE_SOURCE" \
  -framework AppKit \
  -o "$PROBE_BINARY"; then
  echo "cjgui stage134 visible order smoke probe: compile failed" >&2
  exit 5
fi

"$PROBE_BINARY"
