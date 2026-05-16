#!/usr/bin/env zsh
#
# 维护注释：本脚本是 NSApplication shared-application isolated actual
# accessor call probe。
# Truth: actual accessor call 只发生在本 isolated native probe 中，并且只在
# 已存在 NSApplication singleton 时执行；否则输出 fail-closed classification。
# Stop-line: 不创建或激活 application，不改变 activation policy，不启动 AppKit
# loop / pump，不创建 window、drawable 或 renderer resource，不写 runtime artifact。
set -euo pipefail

OUTPUT_DIR="$(mktemp -d /tmp/cjgui-nsapp-shared-application-isolated-actual-accessor-call-XXXXXX)"
PROBE_SOURCE="$OUTPUT_DIR/isolated_actual_accessor_call_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/isolated_actual_accessor_call_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge NSApplication shared-application isolated actual accessor call probe: macOS is required" >&2
  exit 2
fi

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge NSApplication shared-application isolated actual accessor call probe: clang not found" >&2
  exit 5
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge NSApplication shared-application isolated actual accessor call probe: SDKROOT not found" >&2
  exit 6
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NSAPP_SHARED_APPLICATION_ISOLATED_ACTUAL_ACCESSOR_CALL_PROBE'
#import <AppKit/AppKit.h>
#import <stdbool.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>

static void print_bool(const char *name, bool value) {
    printf("cjgui native bridge NSApplication shared-application isolated actual accessor call probe: %s=%s\n",
        name,
        value ? "true" : "false");
}

static void print_int(const char *name, int value) {
    printf("cjgui native bridge NSApplication shared-application isolated actual accessor call probe: %s=%d\n",
        name,
        value);
}

static void print_text(const char *name, const char *value) {
    printf("cjgui native bridge NSApplication shared-application isolated actual accessor call probe: %s=%s\n",
        name,
        value);
}

int main(void) {
    const char *allow_call =
        getenv("CJGUI_NSAPP_SHARED_APPLICATION_ISOLATED_PROBE_ALLOW_ACTUAL_CALL");
    bool actual_call_allowed = allow_call == NULL || strcmp(allow_call, "0") != 0;
    bool main_thread = [NSThread isMainThread];
    NSApplication *before_application = NSApp;
    bool preexisting_application_present = before_application != nil;
    bool accessor_call_attempted = false;
    bool accessor_returned_nonnull = false;
    bool application_created = false;
    bool main_thread_gate_preserved = main_thread;
    int classification = -240;
    const char *side_effect_classification =
        "fail_closed_preexisting_application_missing";

    print_bool("requested", true);
    print_bool("actual_call_allowed", actual_call_allowed);
    print_bool("main_thread_gate_preserved", main_thread_gate_preserved);
    print_bool("preexisting_application_present", preexisting_application_present);

    if (!main_thread) {
        classification = -101;
        side_effect_classification = "fail_closed_not_main_thread";
        print_bool("accessor_call_attempted", false);
        print_bool("accessor_returned_nonnull", false);
        print_bool("application_created", false);
        print_int("classification", classification);
        print_text("side_effect_classification", side_effect_classification);
        print_bool("integer_classification_only", true);
        print_bool("dehydrated_facts_only", true);
        print_bool("probe_success", false);
        return 1;
    }

    if (!actual_call_allowed) {
        classification = -102;
        side_effect_classification = "fail_closed_actual_call_disabled";
        print_bool("accessor_call_attempted", false);
        print_bool("accessor_returned_nonnull", false);
        print_bool("application_created", false);
        print_int("classification", classification);
        print_text("side_effect_classification", side_effect_classification);
        print_bool("integer_classification_only", true);
        print_bool("dehydrated_facts_only", true);
        print_bool("probe_success", false);
        return 1;
    }

    if (!preexisting_application_present) {
        print_bool("accessor_call_attempted", false);
        print_bool("accessor_returned_nonnull", false);
        print_bool("application_created", false);
        print_int("classification", classification);
        print_text("side_effect_classification", side_effect_classification);
        print_bool("integer_classification_only", true);
        print_bool("dehydrated_facts_only", true);
        print_bool("probe_success", true);
        return 0;
    }

    accessor_call_attempted = true;
    NSApplication *observed_application = [NSApplication sharedApplication];
    NSApplication *after_application = NSApp;
    accessor_returned_nonnull = observed_application != nil;
    application_created = before_application == nil && after_application != nil;

    if (application_created) {
        classification = -201;
        side_effect_classification = "fail_closed_singleton_created";
    } else if (!accessor_returned_nonnull) {
        classification = -202;
        side_effect_classification = "fail_closed_nil_accessor_return";
    } else if (observed_application != before_application) {
        classification = -203;
        side_effect_classification = "fail_closed_singleton_changed";
    } else {
        classification = 240;
        side_effect_classification = "called_preexisting_singleton_no_creation";
    }

    print_bool("accessor_call_attempted", accessor_call_attempted);
    print_bool("accessor_returned_nonnull", accessor_returned_nonnull);
    print_bool("application_created", application_created);
    print_int("classification", classification);
    print_text("side_effect_classification", side_effect_classification);
    print_bool("integer_classification_only", true);
    print_bool("dehydrated_facts_only", true);
    print_bool("activation_policy_mutated", false);
    print_bool("activation_called", false);
    print_bool("appkit_loop_started", false);
    print_bool("window_created", false);
    print_bool("drawable_acquired", false);
    print_bool("render_executed", false);
    print_bool("artifact_publication", false);
    print_bool("public_api_modified", false);
    print_bool("production_public_c_abi_added", false);
    print_bool("runtime_state_write", false);
    print_bool("cjpm_toml_change", false);
    print_bool("pointer_returned", false);
    print_bool("probe_success", classification == 240);
    return classification == 240 ? 0 : 1;
}
CJGUI_NSAPP_SHARED_APPLICATION_ISOLATED_ACTUAL_ACCESSOR_CALL_PROBE

echo "cjgui native bridge NSApplication shared-application isolated actual accessor call probe: output=$OUTPUT_DIR"
echo "cjgui native bridge NSApplication shared-application isolated actual accessor call probe: sdkroot=$CJ_GUI_SDKROOT"
"$CLANG_BIN" \
  -fobjc-arc \
  -isysroot "$CJ_GUI_SDKROOT" \
  "$PROBE_SOURCE" \
  -framework AppKit \
  -framework Foundation \
  -o "$PROBE_EXECUTABLE"
"$PROBE_EXECUTABLE"
