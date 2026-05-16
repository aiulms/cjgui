#!/usr/bin/env zsh
#
# 维护注释：本脚本是 NSApplication shared-application throwaway creation
# isolated native probe。
# Truth: 仅本 isolated probe 允许调用 NSApplication.sharedApplication，并允许
# 无 preexisting singleton 时出现 throwaway singleton creation；只输出 integer
# classification 与 dehydrated facts，不形成 production singleton ownership truth。
# Stop-line: 不调用 activation policy mutation / activation / AppKit loop /
# app lifecycle shutdown，不创建 window / view / layer，不 visible order，不取 drawable，不
# 创建 command queue / buffer / encoder，不 render / commit / present / GPU
# submission，不写 artifact / diagnostics publication。
set -euo pipefail

OUTPUT_DIR="$(mktemp -d /tmp/cjgui-nsapp-shared-application-throwaway-creation-probe-XXXXXX)"
PROBE_SOURCE="$OUTPUT_DIR/throwaway_creation_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/throwaway_creation_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge NSApplication shared-application throwaway creation probe: macOS is required" >&2
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
  echo "cjgui native bridge NSApplication shared-application throwaway creation probe: clang not found" >&2
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
  echo "cjgui native bridge NSApplication shared-application throwaway creation probe: SDKROOT not found" >&2
  exit 6
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NSAPP_SHARED_APPLICATION_THROWAWAY_CREATION_PROBE'
#import <AppKit/AppKit.h>
#import <stdbool.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>

static void print_bool(const char *name, bool value) {
    printf("cjgui native bridge NSApplication shared-application throwaway creation probe: %s=%s\n",
        name,
        value ? "true" : "false");
}

static void print_int(const char *name, int value) {
    printf("cjgui native bridge NSApplication shared-application throwaway creation probe: %s=%d\n",
        name,
        value);
}

static void print_text(const char *name, const char *value) {
    printf("cjgui native bridge NSApplication shared-application throwaway creation probe: %s=%s\n",
        name,
        value);
}

int main(void) {
    const char *allow_call =
        getenv("CJGUI_NSAPP_SHARED_APPLICATION_THROWAWAY_PROBE_ALLOW_ACTUAL_CALL");
    bool actual_call_allowed = allow_call == NULL || strcmp(allow_call, "0") != 0;
    bool main_thread_confined = [NSThread isMainThread];
    NSApplication *before_application = NSApp;
    bool preexisting_application_present = before_application != nil;
    bool accessor_call_attempted = false;
    bool accessor_returned_nonnull = false;
    bool singleton_exists_after = false;
    bool throwaway_application_created = false;
    int classification = -260;
    const char *side_effect_classification = "fail_closed_not_attempted";

    print_bool("requested", true);
    print_bool("actual_call_allowed", actual_call_allowed);
    print_bool("main_thread_confined", main_thread_confined);
    print_bool("preexisting_application_present", preexisting_application_present);

    if (!main_thread_confined) {
        classification = -101;
        side_effect_classification = "fail_closed_not_main_thread";
        print_bool("accessor_call_attempted", false);
        print_bool("accessor_returned_nonnull", false);
        print_bool("singleton_exists_after", false);
        print_bool("throwaway_application_created", false);
        print_int("classification", classification);
        print_text("side_effect_classification", side_effect_classification);
        print_bool("throwaway_creation_evidence", false);
        print_bool("production_singleton_ownership_truth", false);
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
        print_bool("singleton_exists_after", false);
        print_bool("throwaway_application_created", false);
        print_int("classification", classification);
        print_text("side_effect_classification", side_effect_classification);
        print_bool("throwaway_creation_evidence", false);
        print_bool("production_singleton_ownership_truth", false);
        print_bool("integer_classification_only", true);
        print_bool("dehydrated_facts_only", true);
        print_bool("probe_success", false);
        return 1;
    }

    accessor_call_attempted = true;

    @autoreleasepool {
        @try {
            NSApplication *observed_application = [NSApplication sharedApplication];
            NSApplication *after_application = NSApp;
            accessor_returned_nonnull = observed_application != nil;
            singleton_exists_after = after_application != nil;
            throwaway_application_created =
                before_application == nil && after_application != nil;

            if (!accessor_returned_nonnull || !singleton_exists_after) {
                classification = -202;
                side_effect_classification = "fail_closed_nil_accessor_return";
            } else if (preexisting_application_present &&
                observed_application == before_application) {
                classification = 240;
                side_effect_classification =
                    "preexisting_singleton_observed_no_creation";
            } else if (throwaway_application_created) {
                classification = 241;
                side_effect_classification =
                    "throwaway_singleton_created_by_accessor";
            } else {
                classification = -203;
                side_effect_classification =
                    "fail_closed_singleton_identity_unexpected";
            }
        } @catch (NSException *exception) {
            classification = -204;
            side_effect_classification = "fail_closed_accessor_exception";
        }
    }

    print_bool("accessor_call_attempted", accessor_call_attempted);
    print_bool("accessor_returned_nonnull", accessor_returned_nonnull);
    print_bool("singleton_exists_after", singleton_exists_after);
    print_bool("throwaway_application_created", throwaway_application_created);
    print_int("classification", classification);
    print_text("side_effect_classification", side_effect_classification);
    print_bool("throwaway_creation_evidence", classification == 241);
    print_bool("production_singleton_ownership_truth", false);
    print_bool("integer_classification_only", true);
    print_bool("dehydrated_facts_only", true);
    print_bool("activation_policy_mutated", false);
    print_bool("activation_called", false);
    print_bool("app_lifecycle_control_called", false);
    print_bool("window_view_layer_created", false);
    print_bool("visible_ordered", false);
    print_bool("drawable_acquired", false);
    print_bool("command_queue_buffer_encoder_created", false);
    print_bool("render_commit_present_gpu_submission", false);
    print_bool("artifact_or_diagnostics_publication", false);
    print_bool("public_api_modified", false);
    print_bool("production_public_c_abi_added", false);
    print_bool("runtime_state_write", false);
    print_bool("cjpm_toml_change", false);
    print_bool("renderer_state_write", false);
    print_bool("backend_ready_truth", false);
    print_bool("pointer_returned", false);
    print_bool("probe_success", classification == 240 || classification == 241);
    return classification == 240 || classification == 241 ? 0 : 1;
}
CJGUI_NSAPP_SHARED_APPLICATION_THROWAWAY_CREATION_PROBE

"$CLANG_BIN" \
  -fobjc-arc \
  -isysroot "$CJ_GUI_SDKROOT" \
  "$PROBE_SOURCE" \
  -framework AppKit \
  -framework Foundation \
  -o "$PROBE_EXECUTABLE"
"$PROBE_EXECUTABLE"
