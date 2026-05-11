#!/usr/bin/env zsh
#
# Owner: native bridge no-resource FFI call verification probe。
# Truth: 验证 runtime internal declaration owner、actual internal call owner source
# 与临时 package link probe 能观察 no-resource callable 返回事实。
# Stop-line: 不修改 runtime/cjgui/cjpm.toml，不接 public API；本 probe 不触发
# NSView create/destroy，不返回 native pointer / handle。
# Same-shape Boundary Brake: no-resource call probe 只是 interop evidence，不是 backend-ready 或 runtime bridge permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
REPO_DIR="$(cd "$PACKAGE_DIR/../.." && pwd)"
DECLARATION_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj"
CALL_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_no_resource_call.cj"
MAIN_THREAD_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_main_thread_call.cj"
TOKEN_SHELL_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_token_table_shell.cj"
ISSUE_REVOKE_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_token_table_issue_revoke.cj"
TEARDOWN_ADMISSION_OWNER="$PACKAGE_DIR/src/runtime_renderer_native_bridge_teardown_admission_call.cj"
APPKIT_IMPORT_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_appkit_import.cj"
APPKIT_CLASS_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_appkit_class_availability.cj"
APPKIT_MAIN_THREAD_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj"
NO_OBJECT_CREATION_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_no_object_creation_call.cj"
NSVIEW_OBJECT_TABLE_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_nsview_object_table.cj"
NSVIEW_CREATE_DESTROY_OWNER="$PACKAGE_DIR/src/runtime_renderer_platform_object_nsview_create_destroy.cj"
PACKAGE_LINK_PROBE="$SCRIPT_DIR/verify_native_bridge_cjpm_package_link_probe.sh"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-no-resource-call-XXXXXX)"
PROBE_LOG="$OUTPUT_DIR/cjpm-package-link-probe.log"
ALLOWED_SYMBOLS=(
  "cjgui_native_bridge_surface_version"
  "cjgui_native_bridge_surface_capabilities"
  "cjgui_native_bridge_status_ok"
  "cjgui_native_bridge_no_resource_admission"
)
MAIN_THREAD_SYMBOL="cjgui_native_bridge_is_main_thread"
TOKEN_SHELL_SYMBOLS=(
  "cjgui_native_bridge_token_invalid"
  "cjgui_native_bridge_token_table_capacity"
  "cjgui_native_bridge_token_table_enabled"
  "cjgui_native_bridge_token_classify"
)
ISSUE_REVOKE_SYMBOLS=(
  "cjgui_native_bridge_token_issue"
  "cjgui_native_bridge_token_revoke"
)
TEARDOWN_ADMISSION_SYMBOLS=(
  "cjgui_native_bridge_teardown_admission"
  "cjgui_native_bridge_destroy_not_supported"
  "cjgui_native_bridge_revoke_before_destroy_required"
  "cjgui_native_bridge_double_destroy_classify"
)
APPKIT_IMPORT_SYMBOLS=(
  "cjgui_native_bridge_appkit_import_available"
  "cjgui_native_bridge_appkit_no_object_admission"
  "cjgui_native_bridge_platform_object_create_still_blocked"
)
APPKIT_CLASS_SYMBOLS=(
  "cjgui_native_bridge_appkit_nswindow_class_available"
  "cjgui_native_bridge_appkit_nsview_class_available"
  "cjgui_native_bridge_appkit_class_lookup_no_object_admission"
  "cjgui_native_bridge_platform_object_allocation_still_blocked"
)
APPKIT_MAIN_THREAD_SYMBOLS=(
  "cjgui_native_bridge_appkit_platform_object_main_thread_required"
  "cjgui_native_bridge_appkit_platform_object_main_thread_admitted"
  "cjgui_native_bridge_appkit_platform_object_background_thread_denied"
  "cjgui_native_bridge_appkit_platform_object_creation_still_blocked"
)
NO_OBJECT_CREATION_SYMBOLS=(
  "cjgui_native_bridge_platform_object_create_no_object_admission"
  "cjgui_native_bridge_platform_object_create_requires_main_thread"
  "cjgui_native_bridge_platform_object_create_requires_token_contract"
  "cjgui_native_bridge_platform_object_create_allocation_blocked"
)
NSVIEW_OBJECT_TABLE_SYMBOLS=(
  "cjgui_native_bridge_nsview_table_capacity"
  "cjgui_native_bridge_nsview_table_enabled"
  "cjgui_native_bridge_nsview_table_empty"
  "cjgui_native_bridge_nsview_table_token_classify"
  "cjgui_native_bridge_nsview_table_allocation_still_blocked"
  "cjgui_native_bridge_nsview_table_destroy_still_blocked"
)
NSVIEW_CREATE_DESTROY_SYMBOLS=(
  "cjgui_native_bridge_nsview_create"
  "cjgui_native_bridge_nsview_destroy"
  "cjgui_native_bridge_nsview_token_classify"
  "cjgui_native_bridge_nsview_table_occupied_count"
  "cjgui_native_bridge_nsview_double_destroy_classify"
  "cjgui_native_bridge_nsview_destroy_requires_main_thread"
)
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge no-resource call probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$DECLARATION_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime declaration owner $DECLARATION_OWNER" >&2
  exit 3
fi
if [[ ! -f "$CALL_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime no-resource call owner $CALL_OWNER" >&2
  exit 3
fi
if [[ ! -f "$MAIN_THREAD_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime main-thread call owner $MAIN_THREAD_OWNER" >&2
  exit 3
fi
if [[ ! -f "$TOKEN_SHELL_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime token table shell owner $TOKEN_SHELL_OWNER" >&2
  exit 3
fi
if [[ ! -f "$ISSUE_REVOKE_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime token table issue/revoke owner $ISSUE_REVOKE_OWNER" >&2
  exit 3
fi
if [[ ! -f "$TEARDOWN_ADMISSION_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime teardown admission owner $TEARDOWN_ADMISSION_OWNER" >&2
  exit 3
fi
if [[ ! -f "$APPKIT_IMPORT_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime AppKit import owner $APPKIT_IMPORT_OWNER" >&2
  exit 3
fi
if [[ ! -f "$APPKIT_CLASS_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime AppKit class availability owner $APPKIT_CLASS_OWNER" >&2
  exit 3
fi
if [[ ! -f "$APPKIT_MAIN_THREAD_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime AppKit main-thread admission owner $APPKIT_MAIN_THREAD_OWNER" >&2
  exit 3
fi
if [[ ! -f "$NO_OBJECT_CREATION_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime no-object creation owner $NO_OBJECT_CREATION_OWNER" >&2
  exit 3
fi
if [[ ! -f "$NSVIEW_OBJECT_TABLE_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime NSView object table owner $NSVIEW_OBJECT_TABLE_OWNER" >&2
  exit 3
fi
if [[ ! -f "$NSVIEW_CREATE_DESTROY_OWNER" ]]; then
  echo "cjgui native bridge no-resource call probe: missing runtime NSView create/destroy owner $NSVIEW_CREATE_DESTROY_OWNER" >&2
  exit 3
fi
if [[ ! -f "$PACKAGE_LINK_PROBE" ]]; then
  echo "cjgui native bridge no-resource call probe: missing package link probe $PACKAGE_LINK_PROBE" >&2
  exit 4
fi
if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge no-resource call probe: missing production native skeleton" >&2
  exit 5
fi
for symbol in "${ALLOWED_SYMBOLS[@]}"; do
  if ! grep -E "foreign func ${symbol}\\(\\): UInt32" "$DECLARATION_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}()" "$CALL_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${ISSUE_REVOKE_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$ISSUE_REVOKE_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal token issue/revoke foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$ISSUE_REVOKE_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal token issue/revoke owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${TEARDOWN_ADMISSION_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$TEARDOWN_ADMISSION_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal teardown admission foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$TEARDOWN_ADMISSION_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal teardown admission owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${APPKIT_IMPORT_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$APPKIT_IMPORT_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal AppKit import foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$APPKIT_IMPORT_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal AppKit import owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${APPKIT_CLASS_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$APPKIT_CLASS_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal AppKit class availability foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$APPKIT_CLASS_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal AppKit class availability owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${APPKIT_MAIN_THREAD_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$APPKIT_MAIN_THREAD_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal AppKit main-thread admission foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$APPKIT_MAIN_THREAD_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal AppKit main-thread admission owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${NO_OBJECT_CREATION_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$NO_OBJECT_CREATION_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal no-object creation foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$NO_OBJECT_CREATION_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal no-object creation owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${NSVIEW_OBJECT_TABLE_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$NSVIEW_OBJECT_TABLE_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal NSView object table foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$NSVIEW_OBJECT_TABLE_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal NSView object table owner call for $symbol" >&2
    exit 6
  fi
done
for symbol in "${NSVIEW_CREATE_DESTROY_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$NSVIEW_CREATE_DESTROY_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal NSView create/destroy foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$NSVIEW_CREATE_DESTROY_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal NSView create/destroy owner call for $symbol" >&2
    exit 6
  fi
done
if ! grep -E "foreign func ${MAIN_THREAD_SYMBOL}\\(\\): Int32" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing internal foreign declaration for $MAIN_THREAD_SYMBOL" >&2
  exit 6
fi
if ! grep -F "${MAIN_THREAD_SYMBOL}()" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing internal owner call for $MAIN_THREAD_SYMBOL" >&2
  exit 6
fi
for symbol in "${TOKEN_SHELL_SYMBOLS[@]}"; do
  if ! grep -F "foreign func ${symbol}" "$TOKEN_SHELL_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal token shell foreign declaration for $symbol" >&2
    exit 6
  fi
  if ! grep -F "${symbol}" "$TOKEN_SHELL_OWNER" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing internal token shell owner call for $symbol" >&2
    exit 6
  fi
done
if ! grep -F "CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness" "$CALL_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing runtime call readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft" "$CALL_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing runtime call default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing main-thread call readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft" "$MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing main-thread call default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoNativeTokenTableShellReadiness" "$TOKEN_SHELL_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing token table shell readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft" "$TOKEN_SHELL_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing token table shell default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness" "$ISSUE_REVOKE_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing token table issue/revoke readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft" "$ISSUE_REVOKE_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing token table issue/revoke default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness" "$TEARDOWN_ADMISSION_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing teardown admission call readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft" "$TEARDOWN_ADMISSION_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing teardown admission call default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectAppKitImportReadiness" "$APPKIT_IMPORT_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing AppKit import readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft" "$APPKIT_IMPORT_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing AppKit import default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness" "$APPKIT_CLASS_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing AppKit class availability readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft" "$APPKIT_CLASS_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing AppKit class availability default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness" "$APPKIT_MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing AppKit main-thread admission readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft" "$APPKIT_MAIN_THREAD_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing AppKit main-thread admission default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness" "$NO_OBJECT_CREATION_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing no-object creation readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft" "$NO_OBJECT_CREATION_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing no-object creation default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness" "$NSVIEW_OBJECT_TABLE_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing NSView object table readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft" "$NSVIEW_OBJECT_TABLE_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing NSView object table default draft" >&2
  exit 6
fi
if ! grep -F "CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness" "$NSVIEW_CREATE_DESTROY_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing NSView create/destroy readiness endpoint" >&2
  exit 6
fi
if ! grep -F "cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft" "$NSVIEW_CREATE_DESTROY_OWNER" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: missing NSView create/destroy default draft" >&2
  exit 6
fi
if grep -E 'cjgui_app_run|cjgui_last_error|\[[[:space:]]*(NSWindow|NSApplication|CALayer)[[:space:]]+(alloc|new)\]|(NSWindow|NSApplication|CALayer)[[:space:]]*\*|nextDrawable|commit\]|presentDrawable|present\]|\[[^]]+[[:space:]]+(retain|release)\]|CFRelease|CFRetain' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge no-resource call probe: production skeleton contains forbidden resource/native behavior token" >&2
  exit 7
fi
echo "cjgui native bridge no-resource call probe: requested=true"
echo "cjgui native bridge no-resource call probe: repo=$REPO_DIR"
echo "cjgui native bridge no-resource call probe: output=$OUTPUT_DIR"
echo "cjgui native bridge no-resource call probe: runtime_foreign_declarations_observed=true"
echo "cjgui native bridge no-resource call probe: runtime_adjacent_probe_route=true"
echo "cjgui native bridge no-resource call probe: runtime_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: main_thread_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: token_table_shell_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: token_table_issue_revoke_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: teardown_admission_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_import_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_class_availability_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_main_thread_admission_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_no_object_creation_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_object_table_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_create_destroy_owner_call_source_observed=true"
echo "cjgui native bridge no-resource call probe: runtime_owner_call_executed_by_probe=false"
zsh "$PACKAGE_LINK_PROBE" | tee "$PROBE_LOG"
for observed_line in \
  "surface_version_observed=true" \
  "capabilities_observed=true" \
  "status_ok_observed=true" \
  "no_resource_admission_observed=true" \
  "main_thread_query_observed=true" \
  "main_thread_observed=true" \
  "token_invalid_observed=true" \
  "token_table_capacity_observed=true" \
  "token_table_enabled_observed=true" \
  "token_classification_observed=true" \
  "token_issue_observed=true" \
  "token_revoke_observed=true" \
  "teardown_admission_observed=true" \
  "appkit_import_observed=true" \
  "appkit_no_object_admission_observed=true" \
  "platform_object_still_blocked_observed=true" \
  "nswindow_class_available_observed=true" \
  "nsview_class_available_observed=true" \
  "class_lookup_no_object_admission_observed=true" \
  "platform_object_allocation_still_blocked_observed=true" \
  "appkit_platform_object_main_thread_required_observed=true" \
  "appkit_platform_object_main_thread_admitted_observed=true" \
  "appkit_platform_object_background_thread_denied_observed=true" \
  "appkit_platform_object_creation_still_blocked_observed=true" \
  "platform_object_create_no_object_admission_observed=true" \
  "platform_object_create_requires_main_thread_observed=true" \
  "platform_object_create_requires_token_contract_observed=true" \
  "platform_object_create_allocation_blocked_observed=true" \
  "nsview_table_capacity_observed=true" \
  "nsview_table_enabled_observed=true" \
  "nsview_table_empty_observed=true" \
  "nsview_table_token_class_observed=true" \
  "nsview_table_allocation_blocked_observed=true" \
  "nsview_table_destroy_blocked_observed=true" \
  "nsview_create_observed=true" \
  "nsview_token_valid_observed=true" \
  "nsview_destroy_observed=true" \
  "nsview_destroyed_stale_observed=true" \
  "nsview_double_destroy_observed=true" \
  "nsview_invalid_destroy_observed=true" \
  "nsview_destroy_requires_main_thread_observed=true" \
  "nsview_occupied_count_observed=true" \
  "success=true reason=none"; do
  if ! grep -F "$observed_line" "$PROBE_LOG" >/dev/null 2>&1; then
    echo "cjgui native bridge no-resource call probe: missing observed fact: $observed_line" >&2
    exit 8
  fi
done
echo "cjgui native bridge no-resource call probe: surface_version_observed=true"
echo "cjgui native bridge no-resource call probe: capabilities_observed=true"
echo "cjgui native bridge no-resource call probe: status_ok_observed=true"
echo "cjgui native bridge no-resource call probe: no_resource_admission_observed=true"
echo "cjgui native bridge no-resource call probe: main_thread_query_observed=true"
echo "cjgui native bridge no-resource call probe: main_thread_observed=true"
echo "cjgui native bridge no-resource call probe: token_invalid_observed=true"
echo "cjgui native bridge no-resource call probe: token_table_capacity_observed=true"
echo "cjgui native bridge no-resource call probe: token_table_enabled_observed=true"
echo "cjgui native bridge no-resource call probe: token_classification_observed=true"
echo "cjgui native bridge no-resource call probe: token_issue_observed=true"
echo "cjgui native bridge no-resource call probe: token_revoke_observed=true"
echo "cjgui native bridge no-resource call probe: teardown_admission_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_import_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_no_object_admission_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_still_blocked_observed=true"
echo "cjgui native bridge no-resource call probe: nswindow_class_available_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_class_available_observed=true"
echo "cjgui native bridge no-resource call probe: class_lookup_no_object_admission_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_allocation_still_blocked_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_platform_object_main_thread_required_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_platform_object_main_thread_admitted_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_platform_object_background_thread_denied_observed=true"
echo "cjgui native bridge no-resource call probe: appkit_platform_object_creation_still_blocked_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_create_no_object_admission_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_create_requires_main_thread_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_create_requires_token_contract_observed=true"
echo "cjgui native bridge no-resource call probe: platform_object_create_allocation_blocked_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_table_capacity_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_table_enabled_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_table_empty_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_table_token_class_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_table_allocation_blocked_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_table_destroy_blocked_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_create_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_token_valid_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_destroy_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_destroyed_stale_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_double_destroy_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_invalid_destroy_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_destroy_requires_main_thread_observed=true"
echo "cjgui native bridge no-resource call probe: nsview_occupied_count_observed=true"
echo "cjgui native bridge no-resource call probe: runtime_package_config_modified=false"
echo "cjgui native bridge no-resource call probe: public_api_modified=false"
echo "cjgui native bridge no-resource call probe: nsview_create_destroy_invoked_by_probe=false"
echo "cjgui native bridge no-resource call probe: native_object_created_by_no_resource_probe=false"
echo "cjgui native bridge no-resource call probe: success=true reason=none"
