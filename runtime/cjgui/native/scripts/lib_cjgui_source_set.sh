#!/usr/bin/env zsh
# The arrays below are the existing selective standalone-cjc probe profiles.
# They are intentionally NOT a cjpm package manifest. Package exports use the
# filesystem-derived functions below so new public modules ship automatically.

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
  linux_application_host.cj
  application_host.cj
  macos_application_cleanup.cj
  runtime_renderer_text_geometry_query.cj
  async_multiline_measure.cj
  native_text_typography.cj
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
  # 2026-10-18 Linux 接入补齐：共同窗口在这些文件里新增了跨文件类型/提供者声明，
  # 命名集合当时未同步，standalone 闭包编译会报 undeclared type name。用
  # platforms/linux/scripts/resolve_source_closure.py 迭代得到，缺一即编译不过。
  composable_ui_scroll_owner_rebase.cj
  composable_ui_command_completion.cj
  composable_ui_candidate_selection.cj
  composable_ui_selection_observation.cj
  composable_ui_installed_text_intent.cj
  composable_ui_preparation_dependency.cj
  composable_ui_windows_selection_gesture.cj
  composable_ui_mac_resident_source.cj
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

# Both current cjpm packages declare src-dir="src". Match their production
# directory rather than a second list of public module names. Test sources and
# separate probe/examples directories are not package production inputs.
cjgui_package_source_paths() {
  local package_dir="$1" source_path
  [[ -f "$package_dir/cjpm.toml" && -d "$package_dir/src" ]] || return 2
  for source_path in "$package_dir/src/"*.cj(N); do
    [[ "${source_path:t}" == *_test.cj ]] && continue
    if [[ -L "$source_path" || ! -f "$source_path" ]]; then
      print -u2 -- "cjgui package source is not a regular local file: $source_path"
      return 2
    fi
    print -r -- "$source_path"
  done
}

# The normal macOS runner builds the top-level native translation units and
# their headers. Native tests and generated native/lib remain outside this set.
cjgui_macos_native_source_paths() {
  local native_dir="$1" source_path
  for source_path in "$native_dir/"*.(m|h)(N); do
    if [[ -L "$source_path" || ! -f "$source_path" ]]; then
      print -u2 -- "cjgui native source is not a regular local file: $source_path"
      return 2
    fi
    print -r -- "$source_path"
  done
}
