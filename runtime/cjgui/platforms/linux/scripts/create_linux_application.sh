#!/usr/bin/env bash
# Create a ui-only application from the shared portable template.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: create_linux_application.sh ui-only|mixed-form|edit-preview DESTINATION [--framework FRAMEWORK_ROOT] [--template TEMPLATE_DIR]
  DESTINATION must not exist. FRAMEWORK_ROOT defaults to this framework.
  TEMPLATE_DIR defaults to FRAMEWORK_ROOT/templates/application/<kind>.
  ui-only stays the lightweight default; mixed-form adds the existing
  handwritten + runtime-generated form consumer; edit-preview adds the
  two-window editor/preview consumer sharing one owner, font registry and
  generated region (host group, not a second platform stack).
EOF
  exit 2
}

[[ "$#" -ge 2 ]] || usage
KIND="$1"
DESTINATION="$2"
shift 2
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMPLATE_DIR=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --framework) [[ "$#" -ge 2 ]] || usage; FRAMEWORK_ROOT="$2"; shift 2 ;;
    --template) [[ "$#" -ge 2 ]] || usage; TEMPLATE_DIR="$2"; shift 2 ;;
    *) usage ;;
  esac
done

case "$KIND" in
  ui-only|mixed-form|edit-preview) ;;
  *)
    printf 'cjgui linux create: unknown kind: %s (expected ui-only, mixed-form or edit-preview)\n' "$KIND" >&2
    exit 2
    ;;
esac
[[ -d "$FRAMEWORK_ROOT" && -f "$FRAMEWORK_ROOT/cjpm.toml" && -d "$FRAMEWORK_ROOT/src" ]] || {
  printf 'cjgui linux create: framework root is unavailable: %s\n' "$FRAMEWORK_ROOT" >&2
  exit 2
}
[[ -x "$FRAMEWORK_ROOT/platforms/linux/scripts/run_linux_application.sh" ]] || {
  printf 'cjgui linux create: Linux application runner missing under %s\n' "$FRAMEWORK_ROOT" >&2
  exit 2
}
[[ -f "$FRAMEWORK_ROOT/platforms/linux/framework-sources.txt" ]] || {
  printf 'cjgui linux create: framework source list missing under %s\n' "$FRAMEWORK_ROOT" >&2
  exit 2
}
case "$KIND" in
  ui-only) KIND_DIR="ui_only" ;;
  mixed-form) KIND_DIR="mixed_form" ;;
  edit-preview) KIND_DIR="edit_preview" ;;
esac
TEMPLATE_DIR="${TEMPLATE_DIR:-$FRAMEWORK_ROOT/templates/application/$KIND_DIR}"
[[ -f "$TEMPLATE_DIR/src/main.cj" && -f "$TEMPLATE_DIR/linux/cjpm.toml" && -f "$TEMPLATE_DIR/linux/run.sh" &&
   -f "$TEMPLATE_DIR/README.md" ]] || {
  printf 'cjgui linux create: %s template is unavailable: %s\n' "$KIND" "$TEMPLATE_DIR" >&2
  exit 2
}
if [[ "$KIND" == "ui-only" ]]; then
  [[ -f "$FRAMEWORK_ROOT/resources/composable-beacon.png" ]] || {
    printf 'cjgui linux create: starter image missing under %s/resources\n' "$FRAMEWORK_ROOT" >&2
    exit 2
  }
  [[ -f "$FRAMEWORK_ROOT/resources/composable-beacon-coral.png" ]] || {
    printf 'cjgui linux create: second starter image missing under %s/resources\n' "$FRAMEWORK_ROOT" >&2
    exit 2
  }
fi
if [[ "$KIND" == "mixed-form" && ! -f "$TEMPLATE_DIR/client.py" ]]; then
  printf 'cjgui linux create: mixed-form client is unavailable: %s/client.py\n' "$TEMPLATE_DIR" >&2
  exit 2
fi
if [[ "$KIND" == "edit-preview" ]]; then
  [[ -f "$TEMPLATE_DIR/src/preview_window.cj" && -d "$TEMPLATE_DIR/resources" ]] || {
    printf 'cjgui linux create: edit-preview preview sources/resources are unavailable: %s\n' "$TEMPLATE_DIR" >&2
    exit 2
  }
fi
if [[ -e "$DESTINATION" || -L "$DESTINATION" ]]; then
  printf 'cjgui linux create: destination already exists: %s\n' "$DESTINATION" >&2
  exit 2
fi
[[ -d "$(dirname "$DESTINATION")" ]] || {
  printf 'cjgui linux create: destination parent does not exist: %s\n' "$DESTINATION" >&2
  exit 2
}
DESTINATION="$(cd "$(dirname "$DESTINATION")" && pwd)/$(basename "$DESTINATION")"
FRAMEWORK_ROOT="$(cd "$FRAMEWORK_ROOT" && pwd)"
TEMPLATE_DIR="$(cd "$TEMPLATE_DIR" && pwd)"

RELATIVE="$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$DESTINATION" "$FRAMEWORK_ROOT")"
python3 - "$TEMPLATE_DIR" "$DESTINATION" "$FRAMEWORK_ROOT" "$KIND" <<'PY'
from pathlib import Path
import json, os, shutil, sys

template, destination, framework = map(Path, sys.argv[1:4])
kind = sys.argv[4]
relative = os.path.relpath(framework, destination)
destination.mkdir()  # Atomic refusal also covers a concurrent creator.
ignore = shutil.ignore_patterns("._*", ".DS_Store")
try:
    shutil.copytree(template / "src", destination / "src", ignore=ignore)
    manifest = (template / "linux/cjpm.toml").read_text().replace(
        "__CJGUI_FRAMEWORK_RELATIVE_PATH__", json.dumps(relative, ensure_ascii=False)[1:-1])
    (destination / "cjpm.toml").write_text(manifest)
    shutil.copy2(template / "linux/run.sh", destination / "run.sh")
    shutil.copy2(template / "README.md", destination / "README.md")
    if kind == "mixed-form":
        shutil.copy2(template / "client.py", destination / "client.py")
    elif kind == "edit-preview":
        shutil.copytree(template / "resources", destination / "resources", ignore=ignore)
    else:
        shutil.copy2(framework / "resources/composable-beacon.png", destination / "composable-beacon.png")
        shutil.copy2(framework / "resources/composable-beacon-coral.png",
                     destination / "composable-beacon-coral.png")
    (destination / "run.sh").chmod(0o755)
except BaseException:
    shutil.rmtree(destination)  # Only this invocation's newly created directory.
    raise
PY
printf 'cjgui linux create: kind=%s destination=%s framework_relative=%s\n' "$KIND" "$DESTINATION" "$RELATIVE"
