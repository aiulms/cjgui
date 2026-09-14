#!/usr/bin/env zsh

# Focused native proof: generic Cangjie scene nodes become Metal rectangles,
# the scene-color readback succeeds, and an input intent keeps its projection
# version rather than being retargeted by a later scene.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_COMPOSABLE_SCENE_TMPDIR:-/private/tmp/cjgui-composable-scene}"
mkdir -p "$TMP_DIR"

SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_INTERNAL_TESTING \
  -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" "$RUNTIME_DIR/probe/composable_scene_probe.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -o "$TMP_DIR/composable_scene_probe"
"$TMP_DIR/composable_scene_probe"
