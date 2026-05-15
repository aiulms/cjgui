#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-nswindow-harness.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

BRIDGE_SOURCE="${NATIVE_DIR}/cjgui_native_bridge.m"
BRIDGE_HEADER="${NATIVE_DIR}/cjgui_native_bridge.h"
PROBE_SOURCE="${TMP_DIR}/nswindow_harness_probe.m"
PROBE_BINARY="${TMP_DIR}/nswindow_harness_probe"

required_symbols=(
  "cjgui_native_bridge_nswindow_harness_table_capacity"
  "cjgui_native_bridge_nswindow_harness_table_enabled"
  "cjgui_native_bridge_nswindow_harness_table_occupied_count"
  "cjgui_native_bridge_nswindow_harness_create"
  "cjgui_native_bridge_nswindow_harness_destroy"
  "cjgui_native_bridge_nswindow_harness_token_classify"
  "cjgui_native_bridge_nswindow_harness_double_destroy_classify"
  "cjgui_native_bridge_nswindow_harness_create_requires_main_thread"
  "cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread"
  "cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked"
  "cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked"
  "cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked"
  "cjgui_native_bridge_nswindow_harness_present_still_blocked"
)

for symbol in "${required_symbols[@]}"; do
  if ! grep -q "${symbol}" "$BRIDGE_HEADER" || ! grep -q "${symbol}" "$BRIDGE_SOURCE"; then
    echo "missing required NSWindow harness symbol: ${symbol}" >&2
    exit 1
  fi
done

forbidden_runtime_calls=(
  "nextDrawable"
  "renderCommandEncoder"
  "presentDrawable"
  " present]"
  " commit]"
  "drawPrimitives"
  "setRenderPipelineState"
  "setVertexBuffer"
)

for token in "${forbidden_runtime_calls[@]}"; do
  if grep -vE '^[[:space:]]*\*' "$BRIDGE_SOURCE" | grep -q "$token"; then
    echo "forbidden render/runtime submission call still present: ${token}" >&2
    exit 1
  fi
done

if grep -E 'uintptr_t|__bridge|CFBridging|NSValue[[:space:]]+valueWithPointer|pointerValue' "$BRIDGE_SOURCE" >/dev/null; then
  echo "native bridge must not expose or smuggle pointer-backed tokens" >&2
  exit 1
fi

cat >"$PROBE_SOURCE" <<'OBJC'
#import <Foundation/Foundation.h>
#import <pthread.h>
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"

static int background_create_status = 0;
static int background_destroy_status = 0;
static uint64_t background_destroy_token = 0;

static void *create_from_background(void *ctx) {
  (void)ctx;
  uint64_t token = 0;
  background_create_status = cjgui_native_bridge_nswindow_harness_create(&token);
  return NULL;
}

static void *destroy_from_background(void *ctx) {
  (void)ctx;
  background_destroy_status = cjgui_native_bridge_nswindow_harness_destroy(background_destroy_token);
  return NULL;
}

static int require_equal_i32(const char *label, int32_t actual, int32_t expected) {
  if (actual != expected) {
    fprintf(stderr, "%s expected %d but got %d\n", label, expected, actual);
    return 1;
  }
  printf("%s=%d\n", label, actual);
  return 0;
}

static int require_equal_u32(const char *label, uint32_t actual, uint32_t expected) {
  if (actual != expected) {
    fprintf(stderr, "%s expected %u but got %u\n", label, expected, actual);
    return 1;
  }
  printf("%s=%u\n", label, actual);
  return 0;
}

int main(void) {
  int failures = 0;

  failures += require_equal_u32("table_enabled", cjgui_native_bridge_nswindow_harness_table_enabled(), 1u);
  failures += require_equal_u32("occupied_before", cjgui_native_bridge_nswindow_harness_table_occupied_count(), 0u);
  failures += require_equal_i32("create_requires_main_thread", cjgui_native_bridge_nswindow_harness_create_requires_main_thread(), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CREATE_MAIN_THREAD_REQUIRED);
  failures += require_equal_i32("destroy_requires_main_thread", cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread(), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DESTROY_MAIN_THREAD_REQUIRED);

  uint64_t token = 0;
  int32_t create_status = cjgui_native_bridge_nswindow_harness_create(&token);
  failures += require_equal_i32("create_status", create_status, CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK);
  if (token == 0) {
    fprintf(stderr, "created token must be nonzero\n");
    failures += 1;
  } else {
    printf("token_nonzero=true\n");
  }

  failures += require_equal_u32("occupied_after_create", cjgui_native_bridge_nswindow_harness_table_occupied_count(), 1u);
  failures += require_equal_i32("classify_bound", cjgui_native_bridge_nswindow_harness_token_classify(token), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_BOUND);
  failures += require_equal_i32("destroy_invalid_zero", cjgui_native_bridge_nswindow_harness_destroy(0), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_INVALID_TOKEN_DENIED);
  failures += require_equal_i32("next_drawable_still_blocked", cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked(), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_NEXT_DRAWABLE_STILL_BLOCKED);
  failures += require_equal_i32("command_buffer_still_blocked", cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked(), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_COMMAND_BUFFER_STILL_BLOCKED);
  failures += require_equal_i32("render_encoder_still_blocked", cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked(), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_RENDER_ENCODER_STILL_BLOCKED);
  failures += require_equal_i32("present_still_blocked", cjgui_native_bridge_nswindow_harness_present_still_blocked(), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_PRESENT_STILL_BLOCKED);

  pthread_t create_thread;
  if (pthread_create(&create_thread, NULL, create_from_background, NULL) == 0) {
    pthread_join(create_thread, NULL);
    failures += require_equal_i32("background_create_status", background_create_status, CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_CREATE_MAIN_THREAD_REQUIRED);
  } else {
    fprintf(stderr, "failed to start create background thread\n");
    failures += 1;
  }

  background_destroy_token = token;
  pthread_t destroy_thread;
  if (pthread_create(&destroy_thread, NULL, destroy_from_background, NULL) == 0) {
    pthread_join(destroy_thread, NULL);
    failures += require_equal_i32("background_destroy_status", background_destroy_status, CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DESTROY_MAIN_THREAD_REQUIRED);
  } else {
    fprintf(stderr, "failed to start destroy background thread\n");
    failures += 1;
  }

  failures += require_equal_i32("classify_after_background_destroy_denied", cjgui_native_bridge_nswindow_harness_token_classify(token), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_TOKEN_BOUND);
  failures += require_equal_i32("destroy_status", cjgui_native_bridge_nswindow_harness_destroy(token), CJGUI_NATIVE_BRIDGE_SKELETON_STATUS_OK);
  failures += require_equal_u32("occupied_after_destroy", cjgui_native_bridge_nswindow_harness_table_occupied_count(), 0u);
  failures += require_equal_i32("classify_after_destroy", cjgui_native_bridge_nswindow_harness_token_classify(token), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_STALE_TOKEN_DENIED);
  failures += require_equal_i32("double_destroy_classify", cjgui_native_bridge_nswindow_harness_double_destroy_classify(token), CJGUI_NATIVE_BRIDGE_NSWINDOW_HARNESS_DOUBLE_DESTROY_DENIED);

  printf("next_drawable_called=false\n");
  printf("command_buffer_created=false\n");
  printf("render_encoder_created=false\n");
  printf("present_called=false\n");
  printf("render_called=false\n");
  return failures == 0 ? 0 : 1;
}
OBJC

clang -fobjc-arc \
  -I"$NATIVE_DIR" \
  "$PROBE_SOURCE" \
  "$BRIDGE_SOURCE" \
  -framework Foundation \
  -framework AppKit \
  -framework QuartzCore \
  -framework Metal \
  -o "$PROBE_BINARY"

"$PROBE_BINARY"
