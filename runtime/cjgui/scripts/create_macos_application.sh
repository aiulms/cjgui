#!/usr/bin/env zsh
set -euo pipefail

usage() {
  print -u2 'usage: create_macos_application.sh (ui-only|command-surface|collaboration|mixed-form) DESTINATION [--framework FRAMEWORK_ROOT]'
  exit 2
}

(( $# >= 2 )) || usage
APP_KIND="$1"
DESTINATION="$2"
shift 2
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
while (( $# > 0 )); do
  case "$1" in
    --framework)
      (( $# >= 2 )) || usage
      FRAMEWORK_ROOT="$2"
      shift 2
      ;;
    *) usage ;;
  esac
done

case "$APP_KIND" in
  ui-only) TEMPLATE_DIR="$FRAMEWORK_ROOT/templates/macos_application/ui_only" ;;
  command-surface) TEMPLATE_DIR="$FRAMEWORK_ROOT/templates/macos_application/command_surface" ;;
  collaboration) TEMPLATE_DIR="$FRAMEWORK_ROOT/templates/macos_application/collaboration" ;;
  mixed-form) TEMPLATE_DIR="$FRAMEWORK_ROOT/templates/macos_application/mixed_form" ;;
  *) usage ;;
esac

if [[ ! -d "$FRAMEWORK_ROOT" || ! -f "$FRAMEWORK_ROOT/cjpm.toml" || ! -d "$TEMPLATE_DIR" ]]; then
  print -u2 -- "cjgui create: framework root or template is unavailable: $FRAMEWORK_ROOT"
  exit 2
fi
if [[ -e "$DESTINATION" ]]; then
  print -u2 -- "cjgui create: destination already exists: $DESTINATION"
  exit 2
fi

DESTINATION_PARENT="$(cd "$(dirname "$DESTINATION")" && pwd)"
DESTINATION="$DESTINATION_PARENT/$(basename "$DESTINATION")"
FRAMEWORK_ROOT="$(cd "$FRAMEWORK_ROOT" && pwd)"
RELATIVE_FRAMEWORK="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$DESTINATION" "$FRAMEWORK_ROOT")"

python3 - "$TEMPLATE_DIR" "$DESTINATION" "$RELATIVE_FRAMEWORK" <<'PY'
from pathlib import Path
import json, shutil, sys

source, destination = map(Path, sys.argv[1:3])
relative = sys.argv[3]
ignored = {'target', '.cjgui', 'artifacts', '__pycache__', '.DS_Store'}
destination.mkdir()  # Atomic refusal also covers a concurrent creator.
try:
    for child in source.iterdir():
        if child.name in ignored:
            continue
        target = destination / child.name
        if child.is_dir():
            shutil.copytree(child, target, ignore=shutil.ignore_patterns(*ignored))
        else:
            shutil.copy2(child, target)
    # Each destination language gets its own string escaping. A path is data,
    # including spaces, $, backticks and quotes; it must never become shell code.
    escaped_string = json.dumps(relative, ensure_ascii=False)[1:-1]
    escaped_shell = relative
    for character in ['\\', '"', '$', '`']:
        escaped_shell = escaped_shell.replace(character, '\\' + character)
    for name, value in [('cjpm.toml', escaped_string), ('run.sh', escaped_shell), ('client.py', escaped_string)]:
        path = destination / name
        if path.exists():
            path.write_text(path.read_text().replace('__CJGUI_FRAMEWORK_RELATIVE_PATH__', value))
    for name in ['run.sh', 'cjgui_macos_app.sh', 'client.py']:
        path = destination / name
        if path.exists():
            path.chmod(path.stat().st_mode | 0o111)
except BaseException:
    shutil.rmtree(destination)  # Only this invocation's newly created directory.
    raise
PY
print -r -- "cjgui create: kind=$APP_KIND destination=$DESTINATION framework_relative=$RELATIVE_FRAMEWORK"
