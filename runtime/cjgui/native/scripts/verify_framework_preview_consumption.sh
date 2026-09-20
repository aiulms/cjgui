#!/usr/bin/env zsh
set -euo pipefail

if [[ -z "${CANGJIE_HOME:-}" ]]; then
  print -u2 'set CANGJIE_HOME to the Cangjie 1.1.3 toolchain before running this preview-consumption check'
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# RED contract: an exported consumer must exercise the public window/platform
# transfer route. A probe that manufactures CjguiComposableUiDataTransferEvent
# and calls its owner's callback directly proves only the callback value type;
# it cannot prove AppKit pasteboard/drag input, the native FIFO, accepted-scene
# identity resolution, or public projection readback. Keep this check before
# any build so the old probe fails fast and leaves an auditable RED cause.
if rg -n -F '.applyDataTransfer(' "$RUNTIME_DIR/probe/framework_preview_data_transfer_consumer.cj" >/dev/null; then
  print -u2 -- 'RED: public data-transfer consumer calls owner.applyDataTransfer directly; window/platform/FIFO/identity path is unproven'
  exit 1
fi
if rg -n 'CjguiComposableUiDataTransferEvent\(|testSessionToken|internalRenderer|cjgui_internal_renderer' \
    "$RUNTIME_DIR/probe/framework_preview_data_transfer_consumer.cj" >/dev/null; then
  print -u2 -- 'RED: public data-transfer consumer contains a synthetic event or private renderer seam'
  exit 1
fi
TEMP_ROOT="$(mktemp -d /private/tmp/cjgui-framework-preview-consumption.XXXXXX)"
HANDOFF_PID=""
HANDOFF_DESCRIPTOR=""
VECTOR_PID=""
VECTOR_DESCRIPTOR=""
TRANSFER_PID=""
CLIPBOARD_GUARD=""
CLIPBOARD_GUARD_ORIGINAL=""
CLIPBOARD_GUARD_EXPECTED=""

# Bind this run to the exact payload copied by export_framework_preview.sh.
# The digest is over normalized relative paths plus bytes, so it is stable
# across the later relocation to a path containing spaces and does not rely on
# a Git hash being available for this mixed worktree.
typeset -a SOURCE_PAYLOAD_RELATIVE
SOURCE_PAYLOAD_RELATIVE=(
  README.md
  cjpm.toml
  src/composable_ui.cj
  src/composable_ui_component_instance.cj
  src/composable_vector_graphics.cj
  src/composable_vector_graphics_component.cj
  src/composable_ui_window.cj
  src/composable_ui_tree.cj
  src/composable_ui_generated.cj
  src/composable_ui_composite_component.cj
  src/macos_application_host.cj
  src/runtime_renderer_session.cj
  shared_operation_core/cjpm.toml
  shared_operation_core/client.py
  shared_operation_core/src/shared_editing_form_contract.cj
  shared_operation_core/src/shared_field_write_rule.cj
  shared_operation_core/src/shared_operation_contract.cj
  shared_operation_core/src/shared_operation_list.cj
  shared_operation_core/src/shared_operation_transport.cj
  shared_operation_core/src/shared_operation_transfer.cj
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
  if [[ -n "$VECTOR_PID" ]] && kill -0 "$VECTOR_PID" 2>/dev/null; then
    kill -TERM "$VECTOR_PID" 2>/dev/null || true
    wait "$VECTOR_PID" 2>/dev/null || true
  fi
  if [[ -n "$TRANSFER_PID" ]] && kill -0 "$TRANSFER_PID" 2>/dev/null; then
    kill -TERM "$TRANSFER_PID" 2>/dev/null || true
    wait "$TRANSFER_PID" 2>/dev/null || true
  fi
  if [[ -n "$HANDOFF_PID" ]] && kill -0 "$HANDOFF_PID" 2>/dev/null; then
    kill -TERM "$HANDOFF_PID" 2>/dev/null || true
    wait "$HANDOFF_PID" 2>/dev/null || true
  fi
  if [[ -n "$CLIPBOARD_GUARD" && -x "$CLIPBOARD_GUARD" && -n "$CLIPBOARD_GUARD_ORIGINAL" &&
        -n "$CLIPBOARD_GUARD_EXPECTED" ]]; then
    "$CLIPBOARD_GUARD" restore-if-current "$CLIPBOARD_GUARD_ORIGINAL" "$CLIPBOARD_GUARD_EXPECTED" >/dev/null 2>&1 || true
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
test -f "$FRAMEWORK_DIR/README.md"
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

# This separate source is compiled only after export and relocation. It starts
# two ordinary application hosts against the exported public framework and
# bundle-local beacon, proving image-domain sharing without copying renderer
# implementation into the consumer.
IMAGE_CONSUMER="$APPLICATIONS_DIR/Image Multiwindow Consumer"
zsh "$FRAMEWORK_DIR/scripts/create_macos_application.sh" ui-only "$IMAGE_CONSUMER" --framework "$FRAMEWORK_DIR"
cp "$RUNTIME_DIR/probe/framework_preview_image_consumer.cj" "$IMAGE_CONSUMER/src/main.cj"
IMAGE_CONSUMER_SOURCE_SHA256="$(shasum -a 256 "$IMAGE_CONSUMER/src/main.cj" | awk '{print $1}')"
! rg -q 'internalRenderer|cjgui_internal_renderer|/native/' "$IMAGE_CONSUMER/src/main.cj"

# Compile this public-only consumer only after export and relocation. It owns
# two independent command declarations, resolves each to a stable button
# identity, and reads the accepted action result back through the projection.
COMMAND_CONSUMER="$APPLICATIONS_DIR/Command Menu Consumer"
zsh "$FRAMEWORK_DIR/scripts/create_macos_application.sh" ui-only "$COMMAND_CONSUMER" --framework "$FRAMEWORK_DIR"
cp "$RUNTIME_DIR/probe/framework_preview_command_menu_consumer.cj" "$COMMAND_CONSUMER/src/main.cj"
COMMAND_CONSUMER_SOURCE_SHA256="$(shasum -a 256 "$COMMAND_CONSUMER/src/main.cj" | awk '{print $1}')"
! rg -q 'internalRenderer|cjgui_internal_renderer|/native/|testSessionToken|CJGUI_INTERNAL_TESTING' "$COMMAND_CONSUMER/src/main.cj"

# Public vector consumer: one pure chart window and one shared-operation
# vector window. The source is copied only after export, then built after the
# whole preview tree is relocated to a path containing spaces.
VECTOR_CONSUMER="$APPLICATIONS_DIR/Vector Consumer"
zsh "$FRAMEWORK_DIR/scripts/create_macos_application.sh" ui-only "$VECTOR_CONSUMER" --framework "$FRAMEWORK_DIR"
cp "$RUNTIME_DIR/probe/framework_preview_vector_consumer.cj" "$VECTOR_CONSUMER/src/main.cj"
VECTOR_CONSUMER_SOURCE_SHA256="$(shasum -a 256 "$VECTOR_CONSUMER/src/main.cj" | awk '{print $1}')"
! rg -q 'internalRenderer|cjgui_internal_renderer|/native/|testSessionToken|CJGUI_INTERNAL_TESTING|foreign[[:space:]]*\{|unsafe[[:space:]]*\{' "$VECTOR_CONSUMER/src/main.cj"
VECTOR_FRAMEWORK_RELATIVE="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$VECTOR_CONSUMER" "$FRAMEWORK_DIR")"
VECTOR_CORE_RELATIVE="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$VECTOR_CONSUMER" "$FRAMEWORK_DIR/shared_operation_core")"
export CJGUI_VECTOR_FRAMEWORK_RELATIVE="$VECTOR_FRAMEWORK_RELATIVE"
export CJGUI_VECTOR_CORE_RELATIVE="$VECTOR_CORE_RELATIVE"
# The shared-operation connection is a public package dependency of this
# consumer. Keep it explicit: Cangjie package dependencies are not inherited
# merely because cjgui itself depends on shared_operation_core.
perl -0pi -e 's!cjgui = \{ path = "\.\./\.\." \}!cjgui = { path = "$ENV{CJGUI_VECTOR_FRAMEWORK_RELATIVE}" }!; s!\[dependencies\]\ncjgui = \{ path = "[^\"]+" \}!$&\ncjgui_shared_operation_core = { path = "$ENV{CJGUI_VECTOR_CORE_RELATIVE}" }!' "$VECTOR_CONSUMER/cjpm.toml"
perl -0pi -e 's!__CJGUI_FRAMEWORK_RELATIVE_PATH__!$ENV{CJGUI_VECTOR_FRAMEWORK_RELATIVE}!g' "$VECTOR_CONSUMER/run.sh"
chmod +x "$VECTOR_CONSUMER/run.sh" "$VECTOR_CONSUMER/cjgui_macos_app.sh"

# This consumer is created only after export.  It knows no checkout-local
# renderer symbols: it declares both a bounded text and a structured offer,
# then proves the public transfer-provider dispatch reaches its single owner.
TRANSFER_CONSUMER="$APPLICATIONS_DIR/Data Transfer Consumer"
zsh "$FRAMEWORK_DIR/scripts/create_macos_application.sh" ui-only "$TRANSFER_CONSUMER" --framework "$FRAMEWORK_DIR"
cp "$RUNTIME_DIR/probe/framework_preview_data_transfer_consumer.cj" "$TRANSFER_CONSUMER/src/main.cj"
TRANSFER_CONSUMER_SOURCE_SHA256="$(shasum -a 256 "$TRANSFER_CONSUMER/src/main.cj" | awk '{print $1}')"
! rg -q 'internalRenderer|cjgui_internal_renderer|/native/|testSessionToken|CJGUI_INTERNAL_TESTING|foreign[[:space:]]*\{|unsafe[[:space:]]*\{' "$TRANSFER_CONSUMER/src/main.cj"
TRANSFER_FRAMEWORK_RELATIVE="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$TRANSFER_CONSUMER" "$FRAMEWORK_DIR")"
TRANSFER_CORE_RELATIVE="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$TRANSFER_CONSUMER" "$FRAMEWORK_DIR/shared_operation_core")"
export CJGUI_TRANSFER_FRAMEWORK_RELATIVE="$TRANSFER_FRAMEWORK_RELATIVE"
export CJGUI_TRANSFER_CORE_RELATIVE="$TRANSFER_CORE_RELATIVE"
perl -0pi -e 's!cjgui = \{ path = "\.\./\.\." \}!cjgui = { path = "$ENV{CJGUI_TRANSFER_FRAMEWORK_RELATIVE}" }!; s!\[dependencies\]\ncjgui = \{ path = "[^"]+" \}!$&\ncjgui_shared_operation_core = { path = "$ENV{CJGUI_TRANSFER_CORE_RELATIVE}" }!' "$TRANSFER_CONSUMER/cjpm.toml"
perl -0pi -e 's!__CJGUI_FRAMEWORK_RELATIVE_PATH__!$ENV{CJGUI_TRANSFER_FRAMEWORK_RELATIVE}!g' "$TRANSFER_CONSUMER/run.sh"
chmod +x "$TRANSFER_CONSUMER/run.sh" "$TRANSFER_CONSUMER/cjgui_macos_app.sh"

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
  "$IMAGE_CONSUMER/.cjgui" "$IMAGE_CONSUMER/target" \
  "$COMMAND_CONSUMER/.cjgui" "$COMMAND_CONSUMER/target" \
  "$VECTOR_CONSUMER/.cjgui" "$VECTOR_CONSUMER/target" \
  "$TRANSFER_CONSUMER/.cjgui" "$TRANSFER_CONSUMER/target" \
  "$DOCUMENT_CONSUMER/.cjgui" "$DOCUMENT_CONSUMER/target"
test ! -e "$FRAMEWORK_DIR/native/lib"

mv "$INITIAL_ROOT" "$RELOCATED_ROOT"
PREVIEW_DIR="$RELOCATED_ROOT/CJGUI Framework Preview"
APPLICATIONS_DIR="$RELOCATED_ROOT/Generated Applications"
FRAMEWORK_DIR="$PREVIEW_DIR/framework/cjgui"
DOCUMENT_CONSUMER="$APPLICATIONS_DIR/Document Consumer"
IMAGE_CONSUMER="$APPLICATIONS_DIR/Image Multiwindow Consumer"
COMMAND_CONSUMER="$APPLICATIONS_DIR/Command Menu Consumer"
VECTOR_CONSUMER="$APPLICATIONS_DIR/Vector Consumer"
TRANSFER_CONSUMER="$APPLICATIONS_DIR/Data Transfer Consumer"

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
IMAGE_BUILD_LOG="$TEMP_ROOT/image-multiwindow-preview-build.log"
COMMAND_BUILD_LOG="$TEMP_ROOT/command-menu-preview-build.log"
VECTOR_BUILD_LOG="$TEMP_ROOT/vector-preview-build.log"
build_from_isolated_preview "$APPLICATIONS_DIR/UI Only Consumer" "$UI_BUILD_LOG" 1
build_from_isolated_preview "$APPLICATIONS_DIR/Collaboration Consumer" "$COLLABORATION_BUILD_LOG" 1
build_from_isolated_preview "$DOCUMENT_CONSUMER" "$DOCUMENT_BUILD_LOG" 0
build_from_isolated_preview "$IMAGE_CONSUMER" "$IMAGE_BUILD_LOG" 1
build_from_isolated_preview "$COMMAND_CONSUMER" "$COMMAND_BUILD_LOG" 1
build_from_isolated_preview "$VECTOR_CONSUMER" "$VECTOR_BUILD_LOG" 1
TRANSFER_BUILD_LOG="$TEMP_ROOT/data-transfer-preview-build.log"
build_from_isolated_preview "$TRANSFER_CONSUMER" "$TRANSFER_BUILD_LOG" 1

for application in "$APPLICATIONS_DIR/UI Only Consumer" "$APPLICATIONS_DIR/Collaboration Consumer" "$DOCUMENT_CONSUMER" "$IMAGE_CONSUMER" "$COMMAND_CONSUMER" "$VECTOR_CONSUMER" "$TRANSFER_CONSUMER"; do
  test -d "$application/target"
done

UI_BUNDLE_SHA256="$(bundle_sha256 "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app")"
COLLABORATION_BUNDLE_SHA256="$(bundle_sha256 "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app")"
DOCUMENT_BUNDLE_SHA256="$(bundle_sha256 "$DOCUMENT_CONSUMER/target/release/CJGUISharedDocument.app")"
IMAGE_BUNDLE_SHA256="$(bundle_sha256 "$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app")"
COMMAND_BUNDLE_SHA256="$(bundle_sha256 "$COMMAND_CONSUMER/target/release/CJGUIUiOnlyStarter.app")"
VECTOR_BUNDLE_SHA256="$(bundle_sha256 "$VECTOR_CONSUMER/target/release/CJGUIUiOnlyStarter.app")"
TRANSFER_BUNDLE_SHA256="$(bundle_sha256 "$TRANSFER_CONSUMER/target/release/CJGUIUiOnlyStarter.app")"

test -x "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
test -x "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/MacOS/CJGUICollaborationStarter"
test -x "$DOCUMENT_CONSUMER/target/release/CJGUISharedDocument.app/Contents/MacOS/CJGUISharedDocument"
test -x "$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
test -x "$COMMAND_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
test -x "$VECTOR_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
test -x "$TRANSFER_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
test -f "$FRAMEWORK_DIR/native/lib/libcjgui_internal_renderer.a"
plutil -lint "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$DOCUMENT_CONSUMER/target/release/CJGUISharedDocument.app/Contents/Info.plist" >/dev/null
plutil -lint "$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$COMMAND_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$VECTOR_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Info.plist" >/dev/null
plutil -lint "$TRANSFER_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Info.plist" >/dev/null
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$APPLICATIONS_DIR/UI Only Consumer/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$APPLICATIONS_DIR/Collaboration Consumer/target/release/CJGUICollaborationStarter.app/Contents/Resources/composable-beacon.png"
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$COMMAND_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$VECTOR_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"
cmp "$FRAMEWORK_DIR/resources/composable-beacon.png" "$TRANSFER_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"

IMAGE_RUN_LOG="$TEMP_ROOT/image-multiwindow-preview-run.log"
IMAGE_BINARY="$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
"$IMAGE_BINARY" --verify-image-domain >"$IMAGE_RUN_LOG" 2>&1
rg -q 'CJGUI_PREVIEW_IMAGE_MULTIWINDOW .*a_state=ready.*b_state=ready.*b_after_a_close=ready.*b_open=true.*passed=true' "$IMAGE_RUN_LOG"
[[ "$(rg -c 'composable image preparation started path=.*Resources/composable-beacon\.png' "$IMAGE_RUN_LOG")" == 1 ]]
IMAGE_MANIFEST="$TEMP_ROOT/image-multiwindow-preview.manifest"
{
  print -r -- 'format=1'
  print -r -- "consumer_source=$RUNTIME_DIR/probe/framework_preview_image_consumer.cj"
  print -r -- "consumer_source_sha256=$IMAGE_CONSUMER_SOURCE_SHA256"
  print -r -- "preview_framework=$FRAMEWORK_DIR"
  print -r -- "bundle=$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app"
  print -r -- "bundle_sha256=$IMAGE_BUNDLE_SHA256"
  print -r -- "bundle_resource=$IMAGE_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/Resources/composable-beacon.png"
  print -r -- "source_payload_sha256=$SOURCE_PAYLOAD_SHA256"
  print -r -- "preview_payload_sha256=$PREVIEW_PAYLOAD_SHA256"
  print -r -- "run_log=$IMAGE_RUN_LOG"
  print -r -- 'native_private_copy=false'
  print -r -- 'two_windows_shared_loads=1'
  print -r -- 'a_close_b_ready=true'
} >"$IMAGE_MANIFEST"

COMMAND_RUN_LOG="$TEMP_ROOT/command-menu-preview-run.log"
COMMAND_BINARY="$COMMAND_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
"$COMMAND_BINARY" --verify-command-menu >"$COMMAND_RUN_LOG" 2>&1
rg -q 'CJGUI_PREVIEW_COMMAND_MENU owners=2 .*menu_alpha=true .*menu_beta=true .*alpha_readback=alpha count=1 .*beta_readback=beta count=1 .*disabled_rejected=true .*passed=true' "$COMMAND_RUN_LOG"
COMMAND_MANIFEST="$TEMP_ROOT/command-menu-preview.manifest"
{
  print -r -- 'format=1'
  print -r -- "consumer_source=$RUNTIME_DIR/probe/framework_preview_command_menu_consumer.cj"
  print -r -- "consumer_source_sha256=$COMMAND_CONSUMER_SOURCE_SHA256"
  print -r -- "preview_framework=$FRAMEWORK_DIR"
  print -r -- "bundle=$COMMAND_CONSUMER/target/release/CJGUIUiOnlyStarter.app"
  print -r -- "bundle_sha256=$COMMAND_BUNDLE_SHA256"
  print -r -- "run_log=$COMMAND_RUN_LOG"
  print -r -- 'native_private_copy=false'
  print -r -- 'command_owners=2'
  print -r -- 'stable_targets=true'
  print -r -- 'button_menu_same_action=true'
  print -r -- 'projection_readback=true'
  print -r -- 'disabled_rejected=true'
} >"$COMMAND_MANIFEST"

VECTOR_RUN_LOG="$TEMP_ROOT/vector-preview-run.log"
VECTOR_BINARY="$VECTOR_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
"$VECTOR_BINARY" --verify-vector >"$VECTOR_RUN_LOG" 2>&1 &
VECTOR_PID=$!
for attempt in {1..80}; do
  VECTOR_DESCRIPTOR="$(sed -n 's/^CJGUI_VECTOR_PUBLIC_READY DESCRIPTOR_PATH \([^ ]*\).*$/\1/p' "$VECTOR_RUN_LOG" | tail -n 1)"
  if [[ -n "$VECTOR_DESCRIPTOR" && -f "$VECTOR_DESCRIPTOR" ]]; then break; fi
  if ! kill -0 "$VECTOR_PID" 2>/dev/null; then break; fi
  sleep 0.1
done
test -n "$VECTOR_DESCRIPTOR"
test -f "$VECTOR_DESCRIPTOR"
VECTOR_TARGET="$(sed -n 's/^CJGUI_VECTOR_PUBLIC_READY .*SHARED_TARGET \([^ ]*\)$/\1/p' "$VECTOR_RUN_LOG" | tail -n 1)"
test -n "$VECTOR_TARGET"
PYTHONPATH="$FRAMEWORK_DIR/shared_operation_core" python3 - "$VECTOR_DESCRIPTOR" "$VECTOR_TARGET" <<'PY'
from pathlib import Path
import sys
import time
from client import SharedOperationArgument, SharedOperationClient

operation = SharedOperationClient.from_descriptor(Path(sys.argv[1]), fragment_bytes=1)
initial = operation.get_context()
before = initial.integer("VERSION")
# Capture the public projected field before the consumer's final human action;
# after that action the normal application closes promptly.
window = operation.get_window_context(sys.argv[2])
field = next((values for values in window.values("WINDOW_FIELD_VALUE")
              if len(values) >= 8 and values[2] == "isMarked"), None)
geometry = next((values for values in window.values("WINDOW_FIELD_VALUE")
                 if len(values) >= 8 and values[2] == "ellipseGeometry"), None)
if field is None or field[5] != "STRING" or geometry is None or geometry[5] != "STRING":
    raise SystemExit(f"vector window projection field missing: {window.raw}")
geometry_before = bytes.fromhex(geometry[7]).decode("utf-8")
applied = operation.invoke(before, "SET_MARKED", [7401], [SharedOperationArgument.boolean("isMarked", True)])
if applied.kind != "RESULT" or not applied.boolean("APPLIED"):
    raise SystemExit("vector color write was not applied")
geometry_after = ""
for _ in range(40):
    updated = operation.get_window_context(sys.argv[2])
    updated_geometry = next((values for values in updated.values("WINDOW_FIELD_VALUE")
                             if len(values) >= 8 and values[2] == "ellipseGeometry"), None)
    if updated_geometry is not None:
        geometry_after = bytes.fromhex(updated_geometry[7]).decode("utf-8")
        if geometry_after == "ellipse center=130,85 radius=24,20":
            break
    time.sleep(0.01)
if geometry_after != "ellipse center=130,85 radius=24,20":
    raise SystemExit(f"vector geometry projection did not converge: before={geometry_before!r} after={geometry_after!r}")
# Acknowledge the delivered projection read. The consumer keeps the normal
# local-input sequence behind this owner-turn handshake.
try:
    operation.get_context()
except OSError:
    pass
print(f"CJGUI_PREVIEW_VECTOR_EXTERNAL_READBACK resource=7401 field=isMarked marked=true geometry_before={geometry_before.replace(' ', '_')} geometry_after={geometry_after.replace(' ', '_')} target={sys.argv[2]}")
PY
wait "$VECTOR_PID"
VECTOR_STATUS=$?
VECTOR_PID=""
cat "$VECTOR_RUN_LOG"
rg -q 'CJGUI_VECTOR_PUBLIC_RESULT .*chart=1 .*external_marked=true .*human_action=false .*human_readback=false .*chart_pointer=false .*mixed_same_turn=false .*idle_stable=true .*public_only=true .*passed=true' "$VECTOR_RUN_LOG"
VECTOR_MANIFEST="$TEMP_ROOT/vector-preview.manifest"
{
  print -r -- 'format=1'
  print -r -- "consumer_source=$RUNTIME_DIR/probe/framework_preview_vector_consumer.cj"
  print -r -- "consumer_source_sha256=$VECTOR_CONSUMER_SOURCE_SHA256"
  print -r -- "preview_framework=$FRAMEWORK_DIR"
  print -r -- "bundle=$VECTOR_CONSUMER/target/release/CJGUIUiOnlyStarter.app"
  print -r -- "bundle_sha256=$VECTOR_BUNDLE_SHA256"
  print -r -- "run_log=$VECTOR_RUN_LOG"
  print -r -- "app_status=$VECTOR_STATUS"
  print -r -- 'native_private_copy=false'
  print -r -- 'chart_consumer=true'
  print -r -- 'shared_operation_consumer=true'
  print -r -- 'external_color_write=true'
  print -r -- 'external_geometry_write=true'
  print -r -- 'ordinary_input_public=true'
  print -r -- 'idle_close_convergence=true'
  print -r -- 'window_projection_readback=true'
  print -r -- 'human_action_after_external=not_run'
  print -r -- 'interactive_a_same_owner_input=not_run'
} >"$VECTOR_MANIFEST"

TRANSFER_RUN_LOG="$TEMP_ROOT/data-transfer-preview-run.log"
TRANSFER_BINARY="$TRANSFER_CONSUMER/target/release/CJGUIUiOnlyStarter.app/Contents/MacOS/CJGUIUiOnlyStarter"
TRANSFER_DRIVER_LOG="$TEMP_ROOT/data-transfer-preview-platform-driver.log"
# A disabled endpoint is a normal unavailable control, not an invalid scene.
# Exercise the exported public window API before the platform clipboard flow:
# the consumer declares one target whose resolved node is disabled, and it
# must still start with an active projection. The consumer exposes no native
# test seam here, so an accepted scene is the observable contract boundary.
TRANSFER_DISABLED_BINDING_LOG="$TEMP_ROOT/data-transfer-disabled-binding.log"
"$TRANSFER_BINARY" --verify-data-transfer-disabled-binding >"$TRANSFER_DISABLED_BINDING_LOG" 2>&1
cat "$TRANSFER_DISABLED_BINDING_LOG"
rg -q 'CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_BINDING initial_started=true disabled_refresh=true projection_active=true .*passed=true' \
  "$TRANSFER_DISABLED_BINDING_LOG"

# The disabled phase receives a real AppKit Cmd-V attempt before the same
# public window enables its target and receives a second attempt. The owner
# must observe exactly the enabled one; this distinguishes an absent binding
# from merely failing to deliver either platform input. Restore only when the
# general pasteboard still holds our test text, so a user copy made during the
# short probe is never overwritten.
TRANSFER_DISABLED_PLATFORM_LOG="$TEMP_ROOT/data-transfer-disabled-platform.log"
TRANSFER_DISABLED_PLATFORM_DRIVER_LOG="$TEMP_ROOT/data-transfer-disabled-platform-driver.log"
CLIPBOARD_GUARD="$TEMP_ROOT/cjgui_clipboard_guard"
clang -fobjc-arc -framework AppKit "$RUNTIME_DIR/native/tests/clipboard_guard.m" -o "$CLIPBOARD_GUARD"
CLIPBOARD_GUARD_ORIGINAL="$TEMP_ROOT/clipboard-before-disabled-platform.plist"
CLIPBOARD_GUARD_EXPECTED="$TEMP_ROOT/clipboard-disabled-platform-expected.plist"
"$CLIPBOARD_GUARD" start-text "$CLIPBOARD_GUARD_ORIGINAL" "$CLIPBOARD_GUARD_EXPECTED"
"$TRANSFER_BINARY" --verify-data-transfer-disabled-platform >"$TRANSFER_DISABLED_PLATFORM_LOG" 2>&1 &
TRANSFER_PID=$!
for attempt in {1..120}; do
  if rg -q '^CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_PLATFORM_READY .*phase=disabled' "$TRANSFER_DISABLED_PLATFORM_LOG"; then break; fi
  if ! kill -0 "$TRANSFER_PID" 2>/dev/null; then break; fi
  sleep 0.1
done
rg -q '^CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_PLATFORM_READY .*projection_ready=true phase=disabled' \
  "$TRANSFER_DISABLED_PLATFORM_LOG"
osascript >"$TRANSFER_DISABLED_PLATFORM_DRIVER_LOG" 2>&1 <<'APPLESCRIPT'
tell application "System Events"
    tell process "CJGUIUiOnlyStarter"
        set frontmost to true
        set targetWindow to window "Preview Disabled Transfer Target"
        set position of targetWindow to {620, 120}
        delay 0.3
        set targetPosition to position of targetWindow
        set targetX to item 1 of targetPosition
        set targetY to item 2 of targetPosition
        perform action "AXRaise" of targetWindow
        delay 0.2
        if (value of attribute "AXMain" of targetWindow) is not true then error "disabled target window did not become main"
        click at {targetX + 210, targetY + 90}
        key code 9 using {command down}
        delay 2.6
        click at {targetX + 210, targetY + 90}
        key code 9 using {command down}
    end tell
end tell
APPLESCRIPT
"$CLIPBOARD_GUARD" restore-if-current "$CLIPBOARD_GUARD_ORIGINAL" "$CLIPBOARD_GUARD_EXPECTED" \
  >>"$TRANSFER_DISABLED_PLATFORM_DRIVER_LOG"
CLIPBOARD_GUARD_ORIGINAL=""
CLIPBOARD_GUARD_EXPECTED=""
set +e
wait "$TRANSFER_PID"
TRANSFER_DISABLED_PLATFORM_STATUS=$?
set -e
TRANSFER_PID=""
cat "$TRANSFER_DISABLED_PLATFORM_DRIVER_LOG"
cat "$TRANSFER_DISABLED_PLATFORM_LOG"
test "$TRANSFER_DISABLED_PLATFORM_STATUS" = 0
rg -q 'CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_PLATFORM disabled_events=0 enabled_events=1 projection_active=true passed=true' \
  "$TRANSFER_DISABLED_PLATFORM_LOG"

CLIPBOARD_GUARD_ORIGINAL="$TEMP_ROOT/clipboard-before-data-transfer.plist"
CLIPBOARD_GUARD_EXPECTED="$TEMP_ROOT/clipboard-data-transfer-external-text.plist"
"$CLIPBOARD_GUARD" start-text "$CLIPBOARD_GUARD_ORIGINAL" "$CLIPBOARD_GUARD_EXPECTED"
"$TRANSFER_BINARY" --verify-data-transfer >"$TRANSFER_RUN_LOG" 2>&1 &
TRANSFER_PID=$!
for attempt in {1..120}; do
  if rg -q '^CJGUI_PREVIEW_DATA_TRANSFER_READY ' "$TRANSFER_RUN_LOG"; then break; fi
  if ! kill -0 "$TRANSFER_PID" 2>/dev/null; then break; fi
  sleep 0.1
done
rg -q '^CJGUI_PREVIEW_DATA_TRANSFER_READY .*projections_ready=true' "$TRANSFER_RUN_LOG"
# Drive the two ordinary exported windows through AppKit. The consumer owns
# no synthetic event helper: click/focus and Command-C/V are platform events,
# and the Cangjie process remains in its normal bounded application pump. Keep
# the external text and structured source phases separate so a user copy is
# detected before the test source would replace the general pasteboard.
osascript >"$TRANSFER_DRIVER_LOG" 2>&1 <<'APPLESCRIPT'
tell application "System Events"
    tell process "CJGUIUiOnlyStarter"
        set frontmost to true
        set targetWindow to window "Preview Transfer Target"
        set position of targetWindow to {620, 120}
        delay 0.4
        set targetPosition to position of targetWindow
        set targetX to item 1 of targetPosition
        set targetY to item 2 of targetPosition
        -- A content AX press can reach a background window without changing
        -- AppKit's key window. AXRaise is the platform's window-level focus
        -- action; it changes only normal AppKit window selection and is kept
        -- distinct from all renderer/FIFO/owner paths exercised below.
        perform action "AXRaise" of targetWindow
        delay 0.2
        if (value of attribute "AXMain" of targetWindow) is not true then error "target window did not become main before external paste"
        click at {targetX + 210, targetY + 90}
        key code 9 using {command down}
    end tell
end tell
APPLESCRIPT
"$CLIPBOARD_GUARD" is-current "$CLIPBOARD_GUARD_EXPECTED"
CLIPBOARD_GUARD_EXPECTED="$TEMP_ROOT/clipboard-data-transfer-structured-source.plist"
"$CLIPBOARD_GUARD" expected-transfer-source "$CLIPBOARD_GUARD_EXPECTED" \
  'application/vnd.cjgui.preview.transfer.record' 'record-42' 'preview_source_window' 'preview-source-session' 22
osascript >>"$TRANSFER_DRIVER_LOG" 2>&1 <<'APPLESCRIPT'
tell application "System Events"
    tell process "CJGUIUiOnlyStarter"
        set frontmost to true
        set sourceWindow to window "Preview Transfer Source"
        set targetWindow to window "Preview Transfer Target"
        set position of sourceWindow to {120, 120}
        set position of targetWindow to {620, 120}
        delay 0.3
        set sourcePosition to position of sourceWindow
        set targetPosition to position of targetWindow
        set sourceX to item 1 of sourcePosition
        set sourceY to item 2 of sourcePosition
        set targetX to item 1 of targetPosition
        set targetY to item 2 of targetPosition
        perform action "AXRaise" of sourceWindow
        delay 0.2
        if (value of attribute "AXMain" of sourceWindow) is not true then error "source window did not become main before structured copy"
        click at {sourceX + 210, sourceY + 132}
        key code 8 using {command down}
        delay 0.3
        perform action "AXRaise" of targetWindow
        delay 0.2
        if (value of attribute "AXMain" of targetWindow) is not true then error "target window did not become main before structured paste"
        click at {targetX + 210, targetY + 132}
        key code 9 using {command down}
    end tell
end tell
APPLESCRIPT
"$CLIPBOARD_GUARD" restore-if-current "$CLIPBOARD_GUARD_ORIGINAL" "$CLIPBOARD_GUARD_EXPECTED" \
  >>"$TRANSFER_DRIVER_LOG"
CLIPBOARD_GUARD_ORIGINAL=""
CLIPBOARD_GUARD_EXPECTED=""
set +e
wait "$TRANSFER_PID"
TRANSFER_STATUS=$?
set -e
TRANSFER_PID=""
cat "$TRANSFER_DRIVER_LOG"
cat "$TRANSFER_RUN_LOG"
test "$TRANSFER_STATUS" = 0
rg -q 'CJGUI_PREVIEW_DATA_TRANSFER mode=clipboard platform_copy=true platform_drop=false external_text_paste=true fifo_dispatch=true .*target_projection=true .*text_value=external-text structured_value=record-42 rejected=0 passed=true' "$TRANSFER_RUN_LOG"
TRANSFER_MANIFEST="$TEMP_ROOT/data-transfer-preview.manifest"
{
  print -r -- 'format=1'
  print -r -- "consumer_source=$RUNTIME_DIR/probe/framework_preview_data_transfer_consumer.cj"
  print -r -- "consumer_source_sha256=$TRANSFER_CONSUMER_SOURCE_SHA256"
  print -r -- "preview_framework=$FRAMEWORK_DIR"
  print -r -- "bundle=$TRANSFER_CONSUMER/target/release/CJGUIUiOnlyStarter.app"
  print -r -- "bundle_sha256=$TRANSFER_BUNDLE_SHA256"
  print -r -- "run_log=$TRANSFER_RUN_LOG"
  print -r -- "platform_driver_log=$TRANSFER_DRIVER_LOG"
  print -r -- "disabled_binding_log=$TRANSFER_DISABLED_BINDING_LOG"
  print -r -- "disabled_platform_log=$TRANSFER_DISABLED_PLATFORM_LOG"
  print -r -- "disabled_platform_driver_log=$TRANSFER_DISABLED_PLATFORM_DRIVER_LOG"
  print -r -- 'native_private_copy=false'
  print -r -- 'platform_window_copy=true'
  print -r -- 'platform_external_text_receive=true'
  print -r -- 'platform_fifo_dispatch=true'
  print -r -- 'cross_window_identity_readback=true'
  print -r -- 'bounded_text_and_structured=true'
  print -r -- 'disabled_endpoint_rebind=true'
  print -r -- 'disabled_endpoint_platform_paste_rejected=true'
} >"$TRANSFER_MANIFEST"

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

print -r -- "cjgui_framework_preview_consumption=ok ui_only=build collaboration=build document=build image_multiwindow=build_and_run command_menu=build_and_run vector=build_and_run data_transfer=build_and_run relocated_with_spaces=ok source_origin=exported_preview native_override=cleared dependency_origin=exported_preview resource_origin=exported_preview image_resource_origin=exported_preview image_private_native_copy=false image_shared_loads=1 image_a_close_b_ready=true command_owners=2 command_stable_targets=true command_button_menu_same_action=true command_projection_readback=true command_disabled_rejected=true vector_chart_consumer=true vector_shared_operation_consumer=true vector_external_color_write=true vector_window_projection_readback=true data_transfer_platform_window=true data_transfer_external_text=true data_transfer_structured=true data_transfer_fifo=true data_transfer_identity_readback=true data_transfer_disabled_endpoint_rebind=true data_transfer_disabled_endpoint_platform_paste_rejected=true data_transfer_native_private_copy=false vector_human_action_after_external=not_run public_empty_title=accepted stale_rejected=true normal_close=endpoint_cleared source_payload_sha256=$SOURCE_PAYLOAD_SHA256 preview_payload_sha256=$PREVIEW_PAYLOAD_SHA256 runner_sha256=$RUNNER_SHA256 exporter_sha256=$EXPORTER_SHA256 document_consumer_source_sha256=$DOCUMENT_CONSUMER_SOURCE_SHA256 image_consumer_source_sha256=$IMAGE_CONSUMER_SOURCE_SHA256 command_consumer_source_sha256=$COMMAND_CONSUMER_SOURCE_SHA256 vector_consumer_source_sha256=$VECTOR_CONSUMER_SOURCE_SHA256 transfer_consumer_source_sha256=$TRANSFER_CONSUMER_SOURCE_SHA256 ui_bundle_sha256=$UI_BUNDLE_SHA256 collaboration_bundle_sha256=$COLLABORATION_BUNDLE_SHA256 document_bundle_sha256=$DOCUMENT_BUNDLE_SHA256 image_bundle_sha256=$IMAGE_BUNDLE_SHA256 command_bundle_sha256=$COMMAND_BUNDLE_SHA256 vector_bundle_sha256=$VECTOR_BUNDLE_SHA256 transfer_bundle_sha256=$TRANSFER_BUNDLE_SHA256 image_manifest=$IMAGE_MANIFEST command_manifest=$COMMAND_MANIFEST vector_manifest=$VECTOR_MANIFEST transfer_manifest=$TRANSFER_MANIFEST evidence_tmp_root=$TEMP_ROOT"
