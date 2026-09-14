#!/usr/bin/env zsh
set -euo pipefail

usage() {
  print -u2 'usage: create_macos_application.sh (ui-only|collaboration) DESTINATION [--framework FRAMEWORK_ROOT]'
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
  collaboration) TEMPLATE_DIR="$FRAMEWORK_ROOT/templates/macos_application/collaboration" ;;
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

cp -R "$TEMPLATE_DIR" "$DESTINATION"
export CJGUI_TEMPLATE_RELATIVE="$RELATIVE_FRAMEWORK"
perl -0pi -e 's!__CJGUI_FRAMEWORK_RELATIVE_PATH__!$ENV{CJGUI_TEMPLATE_RELATIVE}!g' \
  "$DESTINATION/cjpm.toml" "$DESTINATION/run.sh"
chmod +x "$DESTINATION/run.sh" "$DESTINATION/cjgui_macos_app.sh"
print -r -- "cjgui create: kind=$APP_KIND destination=$DESTINATION framework_relative=$RELATIVE_FRAMEWORK"
