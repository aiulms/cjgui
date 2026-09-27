#!/usr/bin/env zsh
set -euo pipefail

if (( $# != 1 )); then
  print -u2 'usage: export_framework_preview.sh DESTINATION'
  exit 2
fi

DESTINATION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOSITORY_ROOT="$(cd "$RUNTIME_DIR/../.." && pwd)"
source "$RUNTIME_DIR/native/scripts/lib_cjgui_source_set.sh"
if [[ -e "$DESTINATION" ]]; then
  print -u2 -- "cjgui preview: destination already exists: $DESTINATION"
  exit 2
fi
# The export target's parent may not exist yet (a caller picks a fresh
# stamped directory); create it instead of failing on the dirname cd.
mkdir -p "$(dirname "$DESTINATION")"
DESTINATION_PARENT="$(cd "$(dirname "$DESTINATION")" && pwd)"
DESTINATION="$DESTINATION_PARENT/$(basename "$DESTINATION")"
typeset -a LICENSE_FILES
LICENSE_FILES=(LICENSE NOTICE)
for license_file in "${LICENSE_FILES[@]}"; do
  if [[ ! -f "$REPOSITORY_ROOT/$license_file" ]]; then
    print -u2 -- "cjgui preview: required source license file is missing: $REPOSITORY_ROOT/$license_file"
    exit 1
  fi
done
STAGING_DIR="$(mktemp -d "$DESTINATION_PARENT/.$(basename "$DESTINATION").cjgui-preview.XXXXXX")"
cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT HUP INT TERM

FRAMEWORK_DIR="$STAGING_DIR/framework/cjgui"
mkdir -p "$FRAMEWORK_DIR"
cp "$RUNTIME_DIR/cjpm.toml" "$FRAMEWORK_DIR/cjpm.toml"
cp "$RUNTIME_DIR/README.md" "$FRAMEWORK_DIR/README.md"
# The README's primary onboarding pointer must resolve inside the export:
# carry the application-host quick start beside the README instead of leaving
# a dangling first-run link.
cp "$RUNTIME_DIR/MACOS_APPLICATION_HOST.md" "$FRAMEWORK_DIR/MACOS_APPLICATION_HOST.md"
mkdir -p "$FRAMEWORK_DIR/src" "$FRAMEWORK_DIR/shared_operation_core/src" "$FRAMEWORK_DIR/native" \
  "$FRAMEWORK_DIR/resources" "$FRAMEWORK_DIR/scripts" "$FRAMEWORK_DIR/templates"
# Preview consumers may copy either package independently. Keep the source
# license and notice with the preview root and both package roots.
for license_file in "${LICENSE_FILES[@]}"; do
  cp "$REPOSITORY_ROOT/$license_file" "$STAGING_DIR/$license_file"
  cp "$REPOSITORY_ROOT/$license_file" "$FRAMEWORK_DIR/$license_file"
  cp "$REPOSITORY_ROOT/$license_file" "$FRAMEWORK_DIR/shared_operation_core/$license_file"
done

for source_name in "${CJGUI_FRAMEWORK_SOURCE_NAMES[@]}" "${CJGUI_GENERATED_SOURCE_NAMES[@]}"; do
  cp "$RUNTIME_DIR/src/$source_name" "$FRAMEWORK_DIR/src/$source_name"
done
cp "$RUNTIME_DIR/shared_operation_core/cjpm.toml" "$FRAMEWORK_DIR/shared_operation_core/cjpm.toml"
cp "$RUNTIME_DIR/shared_operation_core/client.py" "$FRAMEWORK_DIR/shared_operation_core/client.py"
# The typed public layer and its runnable example ship beside the raw client so a
# developer can import them from the export root alone.
cp "$RUNTIME_DIR/shared_operation_core/cjgui_generated_client.py" \
  "$FRAMEWORK_DIR/shared_operation_core/cjgui_generated_client.py"
cp "$RUNTIME_DIR/shared_operation_core/example_generated_consumption.py" \
  "$FRAMEWORK_DIR/shared_operation_core/example_generated_consumption.py"
cp "$RUNTIME_DIR/shared_operation_core/example_generated_observation.py" \
  "$FRAMEWORK_DIR/shared_operation_core/example_generated_observation.py"
cp "$RUNTIME_DIR/shared_operation_core/example_generated_candidate_race.py" \
  "$FRAMEWORK_DIR/shared_operation_core/example_generated_candidate_race.py"
typeset -a PREVIEW_CORE_SOURCES
PREVIEW_CORE_SOURCES=(
  shared_editing_form_contract.cj
  shared_field_write_rule.cj
  shared_operation_contract.cj
  shared_operation_list.cj
  shared_operation_transport.cj
  shared_operation_transfer.cj
  shared_operation_image_owner.cj
  shared_text_document.cj
  shared_text_document_workspace.cj
  shared_text_document_file.cj
)
for source_name in "${PREVIEW_CORE_SOURCES[@]}"; do
  cp "$RUNTIME_DIR/shared_operation_core/src/$source_name" "$FRAMEWORK_DIR/shared_operation_core/src/$source_name"
done
for source in cjgui_internal_renderer.m cjgui_internal_renderer.h cjgui_native_bridge.m cjgui_native_bridge.h cjgui_macos_application_launcher.m; do
  cp "$RUNTIME_DIR/native/$source" "$FRAMEWORK_DIR/native/$source"
done
cp "$RUNTIME_DIR/resources/composable-beacon.png" "$RUNTIME_DIR/resources/composable-beacon-coral.png" "$FRAMEWORK_DIR/resources/"
cp "$RUNTIME_DIR/scripts/run_macos_application.sh" "$RUNTIME_DIR/scripts/create_macos_application.sh" "$FRAMEWORK_DIR/scripts/"
cp -R "$RUNTIME_DIR/templates/macos_application" "$FRAMEWORK_DIR/templates/"
# Consumers shipped with the preview so the exported tree, generation and
# rule-set surfaces can be built and run from the export root alone. Their
# dependency paths are rewritten to the exported packages; no author-directory
# or environment override is needed.
typeset -a PREVIEW_CONSUMERS
PREVIEW_CONSUMERS=(
  "tree_outline_consumer:cjgui"
  "generated_panel_consumer:cjgui,cjgui_shared_operation_core"
  "adaptive_layout_public_consumer:cjgui,cjgui_shared_operation_core"
  "rule_set_window_app:cjgui,cjgui_shared_operation_core,cjgui_rule_set_application"
)
mkdir -p "$STAGING_DIR/consumers"
cp -R "$RUNTIME_DIR/examples/rule_set_application" "$STAGING_DIR/framework/rule_set_application"
rm -rf "$STAGING_DIR/framework/rule_set_application/target"
python3 - "$STAGING_DIR/framework/rule_set_application/cjpm.toml" <<'PYAPPDEP'
import re
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(r'cjgui = \{ path = "[^"]+" \}', 'cjgui = { path = "../cjgui" }', text)
text = re.sub(r'cjgui_shared_operation_core = \{ path = "[^"]+" \}',
              'cjgui_shared_operation_core = { path = "../cjgui/shared_operation_core" }', text)
open(path, "w", encoding="utf-8").write(text)
PYAPPDEP
for consumer_spec in "${PREVIEW_CONSUMERS[@]}"; do
  consumer_name="${consumer_spec%%:*}"
  consumer_deps="${consumer_spec#*:}"
  consumer_source="$RUNTIME_DIR/examples/$consumer_name"
  [[ -d "$consumer_source" ]] || continue
  consumer_target="$STAGING_DIR/consumers/$consumer_name"
  mkdir -p "$consumer_target"
  cp "$consumer_source/cjpm.toml" "$consumer_source/run.sh" "$consumer_source/cjgui_macos_app.sh" "$consumer_target/" 2>/dev/null || true
  cp -R "$consumer_source/src" "$consumer_target/src"
  if [[ "$consumer_name" == "generated_panel_consumer" ]]; then
    cp "$consumer_source/verify_generated_effect_candidates.py" "$consumer_target/"
    cp "$consumer_source/verify_public_effect_observation.py" "$consumer_target/"
    cp "$consumer_source/verify_public_window_material.py" "$consumer_target/"
    cp "$consumer_source/verify_generated_diagnostics.py" "$consumer_target/"
  fi
  # The exported launcher lives under framework/cjgui/scripts; point the
  # consumer runner at it so the export root is runnable by itself.
  if [[ -f "$consumer_target/run.sh" ]]; then
    python3 - "$consumer_target/run.sh" <<'PYRUNSH'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = text.replace("$CJGUI_ROOT/scripts/run_macos_application.sh",
                    "$CJGUI_ROOT/framework/cjgui/scripts/run_macos_application.sh")
text = text.replace("$APP_DIR/../../scripts/run_macos_application.sh",
                    "$APP_DIR/../../framework/cjgui/scripts/run_macos_application.sh")
open(path, "w", encoding="utf-8").write(text)
PYRUNSH
  fi
  python3 - "$consumer_target" "$consumer_deps" <<'PYCONSUMER'
import re
import sys
target, deps = sys.argv[1:3]
path = f"{target}/cjpm.toml"
text = open(path, encoding="utf-8").read()
replacements = {
    "cjgui_shared_operation_core": "../../framework/cjgui/shared_operation_core",
    "cjgui_rule_set_application": "../../framework/rule_set_application",
    "cjgui": "../../framework/cjgui",
}
for name, relative in replacements.items():
    text = re.sub(rf'{name} = \{{ path = "[^"]+" \}}', f'{name} = {{ path = "{relative}" }}', text)
open(path, "w", encoding="utf-8").write(text)
PYCONSUMER
done
cp "$RUNTIME_DIR/preview/FRAMEWORK_PREVIEW_MANIFEST.md" "$STAGING_DIR/preview-manifest.md"
chmod +x "$FRAMEWORK_DIR/scripts/run_macos_application.sh" "$FRAMEWORK_DIR/scripts/create_macos_application.sh" \
  "$FRAMEWORK_DIR/templates/macos_application"/*/*.sh
mv "$STAGING_DIR" "$DESTINATION"
trap - EXIT HUP INT TERM
print -r -- "cjgui preview: exported=$DESTINATION"
