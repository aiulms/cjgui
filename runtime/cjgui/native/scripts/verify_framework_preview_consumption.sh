#!/usr/bin/env zsh
set -euo pipefail

if [[ -z "${CANGJIE_HOME:-}" ]]; then
  print -u2 'set CANGJIE_HOME to the Cangjie 1.1.3 toolchain before running this preview-consumption check'
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_ROOT="$(mktemp -d /private/tmp/cjgui-framework-preview-consumption.XXXXXX)"
HANDOFF_PID=""
HANDOFF_DESCRIPTOR=""

# Bind this run to the exact payload copied by export_framework_preview.sh.
# The digest is over normalized relative paths plus bytes, so it is stable
# across the later relocation to a path containing spaces and does not rely on
# a Git hash being available for this mixed worktree.
typeset -a SOURCE_PAYLOAD_RELATIVE
SOURCE_PAYLOAD_RELATIVE=(
  cjpm.toml
  src/composable_ui.cj
  src/composable_ui_component_instance.cj
  src/composable_ui_window.cj
  src/macos_application_host.cj
  src/runtime_renderer_session.cj
  shared_operation_core/cjpm.toml
  shared_operation_core/client.py
  shared_operation_core/src/shared_editing_form_contract.cj
  shared_operation_core/src/shared_operation_contract.cj
  shared_operation_core/src/shared_operation_list.cj
  shared_operation_core/src/shared_operation_transport.cj
  shared_operation_core/src/shared_text_document.cj
  shared_operation_core/src/shared_text_document_workspace.cj
  shared_operation_core/src/shared_text_document_file.cj
  native/cjgui_internal_renderer.m
  native/cjgui_internal_renderer.h
  native/cjgui_native_bridge.m
  native/cjgui_native_bridge.h
  native/cjgui_macos_application_launcher.m
  resources/composable-beacon.png
  resources/composable-beacon-coral.png
  scripts/run_macos_application.sh
  scripts/create_macos_application.sh
  templates/macos_application/ui_only/cjgui_macos_app.sh
  templates/macos_application/ui_only/cjpm.toml
  templates/macos_application/ui_only/run.sh
  templates/macos_application/collaboration/cjgui_macos_app.sh
  templates/macos_application/collaboration/cjpm.toml
  templates/macos_application/collaboration/run.sh
)

payload_sha256() {
  local root="$1"
  local manifest="$2"
  shift
  shift
  (
    cd "$root"
    for relative_path in "$@"; do
      shasum -a 256 "$relative_path" | awk '{print $1}'
    done
    shasum -a 256 "$manifest" | awk '{print $1}'
  ) | shasum -a 256 | awk '{print $1}'
}

bundle_sha256() {
  local bundle="$1"
  (
    cd "$bundle"
    find . -type f -print0 | sort -z | xargs -0 shasum -a 256
  ) | shasum -a 256 | awk '{print $1}'
}

SOURCE_PAYLOAD_SHA256="$(payload_sha256 "$RUNTIME_DIR" preview/FRAMEWORK_PREVIEW_MANIFEST.md "${SOURCE_PAYLOAD_RELATIVE[@]}")"
EXPORTER_SHA256="$(shasum -a 256 "$RUNTIME_DIR/scripts/export_framework_preview.sh" | awk '{print $1}')"
cleanup() {
  if [[ -n "$HANDOFF_PID" ]] && kill -0 "$HANDOFF_PID" 2>/dev/null; then
    kill -TERM "$HANDOFF_PID" 2>/dev/null || true
    wait "$HANDOFF_PID" 2>/dev/null || true
  fi
  # A forced test-process stop is intentionally distinct from normal close.
  # Preserve any endpoint it leaves beneath this fresh test root so the trap
  # never touches a caller's endpoint or cache.
  if [[ -n "$HANDOFF_DESCRIPTOR" && -e "$HANDOFF_DESCRIPTOR" ]]; then
    handoff_endpoint_dir="$(dirname "$HANDOFF_DESCRIPTOR")"
    if ! lsof +D "$handoff_endpoint_dir" >/dev/null 2>&1; then
      mv "$handoff_endpoint_dir" "$TEMP_ROOT/terminated-handoff-endpoint" 2>/dev/null || true
    fi
  fi
  if [[ "${CJGUI_PREVIEW_CONSUMPTION_KEEP_TMPDIR:-0}" != 1 ]]; then
    rm -rf "$TEMP_ROOT"
  fi
}
trap cleanup EXIT HUP INT TERM

# Build an entire preview/application tree first, then relocate that tree as
# one unit to another path containing spaces.  The generated relative package
# dependencies therefore remain valid after relocation instead of being
# rewritten against the source checkout.
INITIAL_ROOT="$TEMP_ROOT/Initial Preview Workspace"
RELOCATED_ROOT="$TEMP_ROOT/Relocated Preview Workspace"
PREVIEW_DIR="$INITIAL_ROOT/CJGUI Framework Preview"
APPLICATIONS_DIR="$INITIAL_ROOT/Generated Applications"
mkdir -p "$INITIAL_ROOT"
mkdir -p "$APPLICATIONS_DIR"
zsh "$RUNTIME_DIR/scripts/export_framework_preview.sh" "$PREVIEW_DIR"

FRAMEWORK_DIR="$PREVIEW_DIR/framework/cjgui"
test -f "$PREVIEW_DIR/preview-manifest.md"
test -f "$FRAMEWORK_DIR/shared_operation_core/client.py"
for document_source in shared_text_document.cj shared_text_document_workspace.cj shared_text_document_file.cj; do
  if [[ ! -f "$FRAMEWORK_DIR/shared_operation_core/src/$document_source" ]]; then
    print -u2 -- "cjgui preview document source missing: $document_source"
    exit 1
  fi
done
test ! -e "$FRAMEWORK_DIR/examples"
test ! -e "$FRAMEWORK_DIR/probe"
test ! -e "$FRAMEWORK_DIR/target"
test ! -e "$FRAMEWORK_DIR/native/lib"

PREVIEW_PAYLOAD_SHA256="$(payload_sha256 "$FRAMEWORK_DIR" ../../preview-manifest.md "${SOURCE_PAYLOAD_RELATIVE[@]}")"
# This equality binds the source bytes copied by the exporter to the preview
# bytes consumed by both application templates; the manifest's destination
# name is normalized by hashing bytes in the same fixed slot.
test "$SOURCE_PAYLOAD_SHA256" = "$PREVIEW_PAYLOAD_SHA256"
RUNNER_SHA256="$(shasum -a 256 "$FRAMEWORK_DIR/scripts/run_macos_application.sh" | awk '{print $1}')"
! rg -q -F "$RUNTIME_DIR" "$FRAMEWORK_DIR"

zsh "$FRAMEWORK_DIR/scripts/create_macos_application.sh" ui-only "$APPLICATIONS_DIR/UI Only Consumer" --framework "$FRAMEWORK_DIR"
zsh "$FRAMEWORK_DIR/scripts/create_macos_application.sh" collaboration "$APPLICATIONS_DIR/Collaboration Consumer" --framework "$FRAMEWORK_DIR"

# The existing shared-document app is an ordinary framework consumer, not a
# public starter template. Rebase a test-owned copy to the exported preview so
# this verification proves its document-core imports are closed without
# widening create_macos_application.sh's supported template surface.
DOCUMENT_EXAMPLE_DIR="$RUNTIME_DIR/examples/shared_document_window_app"
DOCUMENT_CONSUMER="$APPLICATIONS_DIR/Document Consumer"
mkdir -p "$DOCUMENT_CONSUMER"
cp -R "$DOCUMENT_EXAMPLE_DIR/src" "$DOCUMENT_CONSUMER/src"
cp "$DOCUMENT_EXAMPLE_DIR/cjpm.toml" "$DOCUMENT_EXAMPLE_DIR/cjgui_macos_app.sh" "$DOCUMENT_CONSUMER/"
cp "$FRAMEWORK_DIR/templates/macos_application/ui_only/run.sh" "$DOCUMENT_CONSUMER/run.sh"
DOCUMENT_FRAMEWORK_RELATIVE="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$DOCUMENT_CONSUMER" "$FRAMEWORK_DIR")"
DOCUMENT_CORE_RELATIVE="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$DOCUMENT_CONSUMER" "$FRAMEWORK_DIR/shared_operation_core")"
export CJGUI_DOCUMENT_FRAMEWORK_RELATIVE="$DOCUMENT_FRAMEWORK_RELATIVE"
export CJGUI_DOCUMENT_CORE_RELATIVE="$DOCUMENT_CORE_RELATIVE"
perl -0pi -e 's!cjgui = \{ path = "\.\./\.\." \}!cjgui = { path = "$ENV{CJGUI_DOCUMENT_FRAMEWORK_RELATIVE}" }!; s!cjgui_shared_operation_core = \{ path = "\.\./\.\./shared_operation_core" \}!cjgui_shared_operation_core = { path = "$ENV{CJGUI_DOCUMENT_CORE_RELATIVE}" }!' "$DOCUMENT_CONSUMER/cjpm.toml"
perl -0pi -e 's!__CJGUI_FRAMEWORK_RELATIVE_PATH__!$ENV{CJGUI_DOCUMENT_FRAMEWORK_RELATIVE}!g' "$DOCUMENT_CONSUMER/run.sh"
chmod +x "$DOCUMENT_CONSUMER/run.sh" "$DOCUMENT_CONSUMER/cjgui_macos_app.sh"
DOCUMENT_CONSUMER_SOURCE_SHA256="$(shasum -a 256 "$DOCUMENT_CONSUMER/src/main.cj" | awk '{print $1}')"
test -f "$DOCUMENT_CONSUMER/src/main.cj"

# Nothing generated by this check is retained before the relocation/build.
# These are test-owned paths beneath the fresh mktemp root, never the caller's
# checkout or cache.
rm -rf "$FRAMEWORK_DIR/native/lib" \
  "$APPLICATIONS_DIR/UI Only Consumer/.cjgui" "$APPLICATIONS_DIR/UI Only Consumer/target" \
  "$APPLICATIONS_DIR/Collaboration Consumer/.cjgui" "$APPLICATIONS_DIR/Collaboration Consumer/target" \
  "$DOCUMENT_CONSUMER/.cjgui" "$DOCUMENT_CONSUMER/target"
test ! -e "$FRAMEWORK_DIR/native/lib"

mv "$INITIAL_ROOT" "$RELOCATED_ROOT"
PREVIEW_DIR="$RELOCATED_ROOT/CJGUI Framework Preview"
APPLICATIONS_DIR="$RELOCATED_ROOT/Generated Applications"
FRAMEWORK_DIR="$PREVIEW_DIR/framework/cjgui"
DOCUMENT_CONSUMER="$APPLICATIONS_DIR/Document Consumer"

build_from_isolated_preview() {
  local application="$1"
  local build_log="$2"
  local requires_beacon_resource="$3"
  (
    # The normal runner permits an intentional override, but an independent
    # source-preview build must prove it is not accidentally inheriting one.
    unset CJGUI_NATIVE_SOURCE_DIR
    unset CJGUI_ROOT
    zsh "$application/run.sh" --build-only
  ) >"$build_log" 2>&1
  local expected_origin="cjgui macOS application host: source_origin runtime=$FRAMEWORK_DIR native=$FRAMEWORK_DIR/native dependency_cjgui=$FRAMEWORK_DIR dependency_core=$FRAMEWORK_DIR/shared_operation_core"
  rg -q -F "$expected_origin" "$build_log"
  if [[ "$requires_beacon_resource" == 1 ]]; then
    rg -q -F "cjgui macOS application host: resource_origin=$FRAMEWORK_DIR/resources/composable-beacon.png" "$build_log"
  fi
  print -r -- "cjgui preview binding: source_payload_sha256=$SOURCE_PAYLOAD_SHA256 preview_payload_sha256=$PREVIEW_PAYLOAD_SHA256 runner_sha256=$RUNNER_SHA256 exporter_sha256=$EXPORTER_SHA256" >>"$build_log"
  ! rg -q -F "$RUNTIME_DIR/native/" "$build_log"
  ! rg -q -F "$RUNTIME_DIR/src/" "$build_log"
}

UI_BUILD_LOG="$TEMP_ROOT/ui-only-preview-build.log"
COLLABORATION_BUILD_LOG="$TEMP_ROOT/collaboration-preview-build.log"
DOCUMENT_BUILD_LOG="$TEMP_ROOT/document-preview-build.log"
build_from_isolated_preview "$APPLICATIONS_DIR/UI Only Consumer" "$UI_BUILD_LOG" 1
build_from_isolated_preview "$APPLICATIONS_DIR/Collaboration Consumer" "$COLLABORATION_BUILD_LOG" 1
build_from_isolated_preview "$DOCUMENT_CONSUMER" "$DOCUMENT_BUILD_LOG" 0

for application in "$APPLICATIONS_DIR/UI Only Consumer" "$APPLICATIONS_DIR/Collaboration Consumer" "$DOCUMENT_CONSUMER"; do
  test -d "$application/target"
done

UI_BUNDLE_SHA256="$(bundle_sha256 "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app")"
COLLABORATION_BUNDLE_SHA256="$(bundle_sha256 "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app")"
DOCUMENT_BUNDLE_SHA256="$(bundle_sha256 "$DOCUMENT_CONSUMER/target/release/CJGUISharedDocument.app")"

test -x "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
test -x "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/MacOS/CJGUICollaborationStarter"
test -x "$DOCUMENT_CONSUMER/target/release/CJGUISharedDocument.app/Contents/MacOS/CJGUISharedDocument"
test -f "$FRAMEWORK_DIR/native/lib/libcjgui_internal_renderer.a"
plutil -lint "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$DOCUMENT_CONSUMER/target/release/CJGUISharedDocument.app/Contents/Info.plist" >/dev/null
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/Resources/composable-beacon.png"

CLOSE_OUTPUT="$("$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/MacOS/CJGUICollaborationStarter" --verify-normal-close)"
print -r -- "$CLOSE_OUTPUT" | rg -q 'CJGUI_COLLABORATION_NORMAL_CLOSE endpoint=cleared'
CLOSE_DESCRIPTOR="$(print -r -- "$CLOSE_OUTPUT" | sed -n 's/^CJGUI_COLLABORATION_READY DESCRIPTOR_PATH //p')"
test -n "$CLOSE_DESCRIPTOR"
test ! -e "$CLOSE_DESCRIPTOR"

# Fresh-template public handoff: a blank task title is a valid transient
# field value, so context discovery must still work through the stable
# resource name.  The generic public client derives the writable STRING
# action/parameter and target from the issued snapshot; it does not carry the
# template's resource ID or action name as test input.
HANDOFF_LOG="$TEMP_ROOT/collaboration-public-handoff.log"
HANDOFF_BINARY="$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/MacOS/CJGUICollaborationStarter"
"$HANDOFF_BINARY" >"$HANDOFF_LOG" 2>&1 &
HANDOFF_PID=$!
for attempt in {1..40}; do
  HANDOFF_DESCRIPTOR="$(sed -n 's/^CJGUI_COLLABORATION_READY DESCRIPTOR_PATH //p' "$HANDOFF_LOG" | tail -n 1)"
  if [[ -n "$HANDOFF_DESCRIPTOR" && -f "$HANDOFF_DESCRIPTOR" ]]; then break; fi
  sleep 0.1
done
test -n "$HANDOFF_DESCRIPTOR"
test -f "$HANDOFF_DESCRIPTOR"
PYTHONPATH="$FRAMEWORK_DIR/shared_operation_core" python3 - "$HANDOFF_DESCRIPTOR" <<'PY'
from pathlib import Path
import sys
from client import SharedOperationArgument, SharedOperationClient

operation = SharedOperationClient.from_descriptor(Path(sys.argv[1]), fragment_bytes=1)
initial = operation.get_context()
parameter = next(values for values in initial.values("PARAMETER") if values[2] == "STRING")
action = parameter[0]
target = next(int(values[0]) for values in initial.values("FIELD") if values[1] == parameter[1])
initial_version = initial.integer("VERSION")
nonempty = operation.invoke(initial_version, action, [target], [SharedOperationArgument.string(parameter[1], "preview-external-task")])
if nonempty.kind != "RESULT" or not nonempty.boolean("APPLIED"):
    raise SystemExit("dynamic public title write was not applied")
emptied = operation.invoke(nonempty.integer("VERSION_AFTER"), action, [target], [SharedOperationArgument.string(parameter[1], "")])
if emptied.kind != "RESULT" or not emptied.boolean("APPLIED"):
    raise SystemExit("empty title write was rejected before the submit boundary")
after_empty = operation.get_context([target])
field = next(values for values in after_empty.values("FIELD") if int(values[0]) == target and values[1] == parameter[1])
resource = next(values for values in after_empty.values("RESOURCE") if int(values[0]) == target)
if field[4] != "-" or bytes.fromhex(resource[2]).decode("utf-8") != f"记录 {target}":
    raise SystemExit("blank task field made the public resource undiscoverable")
stale = operation.invoke(nonempty.integer("VERSION_AFTER"), action, [target], [SharedOperationArgument.string(parameter[1], "stale-preview-task")])
if stale.kind != "RESULT" or stale.boolean("APPLIED") or not stale.boolean("CONFLICT") or stale.value("REASON") != ("version_conflict",):
    raise SystemExit("stale public title write did not fail closed")
print(f"CJGUI_PREVIEW_PUBLIC_HANDOFF action={action} parameter={parameter[1]} target={target} initial_version={initial_version} empty_version={emptied.integer('VERSION_AFTER')} stale_conflict=true")
PY
kill -TERM "$HANDOFF_PID"
for attempt in {1..20}; do
  if ! kill -0 "$HANDOFF_PID" 2>/dev/null; then break; fi
  sleep 0.1
done
if kill -0 "$HANDOFF_PID" 2>/dev/null; then
  print -u2 -- "preview handoff test process did not stop: $HANDOFF_PID"
  exit 1
fi
if [[ -e "$HANDOFF_DESCRIPTOR" ]]; then
  handoff_endpoint_dir="$(dirname "$HANDOFF_DESCRIPTOR")"
  lsof +D "$handoff_endpoint_dir" 2>/dev/null || true
  mv "$handoff_endpoint_dir" "$TEMP_ROOT/terminated-handoff-endpoint"
fi
HANDOFF_PID=""
HANDOFF_DESCRIPTOR=""

print -r -- "cjgui_framework_preview_consumption=ok ui_only=build collaboration=build document=build relocated_with_spaces=ok source_origin=exported_preview native_override=cleared dependency_origin=exported_preview resource_origin=exported_preview public_empty_title=accepted stale_rejected=true normal_close=endpoint_cleared source_payload_sha256=$SOURCE_PAYLOAD_SHA256 preview_payload_sha256=$PREVIEW_PAYLOAD_SHA256 runner_sha256=$RUNNER_SHA256 exporter_sha256=$EXPORTER_SHA256 document_consumer_source_sha256=$DOCUMENT_CONSUMER_SOURCE_SHA256 ui_bundle_sha256=$UI_BUNDLE_SHA256 collaboration_bundle_sha256=$COLLABORATION_BUNDLE_SHA256 document_bundle_sha256=$DOCUMENT_BUNDLE_SHA256 evidence_tmp_root=$TEMP_ROOT"
