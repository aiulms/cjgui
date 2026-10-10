#!/usr/bin/env zsh
# Shared ordered source closure for standalone CJGUI consumers and preview
# exports. Keep this as names relative to src/ so probes, fingerprints and
# exports all resolve the same files from their own runtime root.

typeset -ga CJGUI_FRAMEWORK_SOURCE_NAMES
CJGUI_FRAMEWORK_SOURCE_NAMES=(
  composable_ui.cj
  composable_ui_component_instance.cj
  composable_grid.cj
  composable_vector_graphics.cj
  composable_vector_graphics_component.cj
  range_text.cj
  text_grapheme.cj
  text_selection_authority.cj
text_session.cj
  installed_range_input.cj
  owner_turn_budget.cj
  composable_ui_window.cj
  mac_text_pointer_capture.cj
  mac_slider_pointer_capture.cj
  mac_activation_prefix.cj
  composable_ui_wheel.cj
  composable_ui_diagnostics.cj
  composable_ui_animation.cj
  composable_ui_position_motion.cj
  composable_ui_tree.cj
  composable_ui_named_style.cj
  composable_ui_platform_state.cj
  composable_ui_platform_accent.cj
  macos_application_host.cj
  windows_application_host.cj
  application_host.cj
  macos_application_cleanup.cj
  runtime_renderer_text_geometry_query.cj
  async_multiline_measure.cj
  runtime_renderer_session.cj
  composable_ui_selection_completion.cj
  composable_ui_source_recovery.cj
  composable_ui_selection_paint.cj
  # 平台替身文件：每个文件都带 `@When[os != "macOS"]` 分支，正是其它平台需要的
  # 声明。common 窗口引用了它们（owner handoff、边缘滚动 ack、文字捕获续写、
  # 有界准备退休），遗漏会让 Windows 目标编译报未声明；它们与
  # mac_text_pointer_capture.cj 等既有条目同类。
  composable_ui_mac_owner_handoff.cj
  composable_ui_mac_edge_scroll.cj
  composable_ui_mac_text_continuation.cj
  composable_ui_mac_retirement.cj
  composable_ui_mac_caret_edit.cj
)
typeset -ga CJGUI_GENERATED_SOURCE_NAMES
CJGUI_GENERATED_SOURCE_NAMES=(composable_ui_composite_component.cj composable_ui_generated.cj)

cjgui_framework_source_names() {
  local include_generated="${1:-false}" source_name
  print -rl -- "${CJGUI_FRAMEWORK_SOURCE_NAMES[@]}"
  if [[ "$include_generated" == "true" ]]; then
    print -rl -- "${CJGUI_GENERATED_SOURCE_NAMES[@]}"
  fi
}

# Emit the exact framework source paths for use by standalone cjc consumers.
# Generated definitions stay in the source set for consumers that expose the
# generated API; callers testing the handwritten window path may omit them.
cjgui_framework_source_paths() {
  local runtime_dir="$1" include_generated="${2:-false}" source_name
  for source_name in "${CJGUI_FRAMEWORK_SOURCE_NAMES[@]}"; do
    print -r -- "$runtime_dir/src/$source_name"
  done
  if [[ "$include_generated" == "true" ]]; then
    for source_name in "${CJGUI_GENERATED_SOURCE_NAMES[@]}"; do
      print -r -- "$runtime_dir/src/$source_name"
    done
  fi
}
