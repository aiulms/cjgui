# P1 Renderer 自动化阶段报告 6

## 本轮完成的阶段包列表

1. `P1 internal Renderer visible-window production harness NSWindow content-view attachment` implementation bundle。
   - 新增 token-backed `NSWindow.contentView` attach / classify / detach C ABI。
   - 新增 runtime internal owner [runtime_renderer_visible_window_content_view_attachment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_content_view_attachment.cj)。
   - 新增 native probe [verify_native_bridge_nswindow_content_view_attachment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nswindow_content_view_attachment.sh)。
   - 新增并同步 [content-view attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-content-view-attachment-manifest.md)。
2. `P1 internal Renderer visible-window production harness visible-order preflight` docs-only bundle。
   - 结论：visible order 仍不得直接实现。
   - 下一刀只能做 internal visible-order policy value boundary。
   - 新增并同步 [visible-order preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-visible-order-preflight-manifest.md)。

## 当前 canonical endpoint / default draft / runtime input

- Canonical endpoint：`CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness visible-order policy value boundary bundle implementation`

## 边界保持说明

- 未调用 `makeKeyAndOrderFront` / `orderFront`。
- 未创建 `NSApplication`，未 activation。
- 未调用 production `nextDrawable`。
- 未创建 render command encoder，未 draw。
- 未调用 `commit` / `present`，未提交 GPU work，未执行 render。
- 未写 renderer state，未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public declaration；public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- 未返回 pointer / handle / `id` / `Class` 到仓颉 public surface。

## 验证命令与结果

- `zsh -n runtime/cjgui/native/scripts/verify_native_bridge_*.sh`：通过。
- 新增 red probe：`verify_native_bridge_nswindow_content_view_attachment.sh` 在 implementation 前因缺少 callable 返回 exit 3，符合预期。
- `verify_native_bridge_nswindow_content_view_attachment.sh`：通过。
- 相关 native bridge probe 回归：通过，覆盖 `NSWindow` harness、`NSView` create/destroy、`NSView` object table、`CAMetalLayer` attachment / no-attach、AppKit import / class / main-thread、platform no-object creation、teardown admission、token issue/revoke、no-resource symbols、skeleton compile、package link、cjpm package link 与 cjpm integration boundary。
- `cjpm build --target-dir /tmp/cjgui-content-view-attachment-target --skip-script`：通过，保留既有 230 条 unused warnings。
- `git diff --check`：通过。
- touched Markdown trailing whitespace check：通过。
- Markdown absolute link target check：通过。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifest reachability：通过。
- 中文标题 / 正文抽查：通过。
- public declaration scan：通过，仅发现 allowlist 符号 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native forbidden surface scan：通过，未发现 `makeKeyAndOrderFront` / `orderFront` / `activateIgnoringOtherApps` / `nextDrawable` / `renderCommandEncoder` / `drawPrimitives` / `commit]` / `presentDrawable` / `present]`。
- pointer / handle / `id` / `Class` return scan：通过。
- protected path scan：`runtime/cjgui/cjpm.toml` 与 `runtime/cjgui/src/runtime_state.cj` 无 diff；`runtime_state.cj` 行数仍是 10065。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：失败，二次复现为 `default Metal device is unavailable`，exit 20。首次直接运行还暴露当前 sandbox 禁止 `envsetup.sh` 内部 `ps` 探测；使用 `/tmp` shim 后 build/run 能进入 smoke，本体仍因 Metal device 不可用失败。

## GitNexus 结果

- `impact CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness --repo cangjie-live-codelattice`：target not found，impacted 0，risk UNKNOWN。
- `impact cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft --repo cangjie-live-codelattice`：target not found，impacted 0，risk UNKNOWN。
- `impact cjgui_native_bridge_nswindow_harness_content_view_attach --repo cangjie-live-codelattice`：target not found，impacted 0，risk UNKNOWN。
- 结论：新增符号未被当前图谱覆盖，未把 UNKNOWN / 0 impacted 当成安全证明；本轮已用源码读取、build、probe、smoke、forbidden scan、protected path scan 与 manifest check 兜底。
- `detect-changes --repo cangjie-live-codelattice --scope unstaged`：24 files，3 symbols，affected processes 0，risk low。

## 是否需要人工介入

是。

原因：必跑 `verify_auto_close.sh` 在当前自动化环境中稳定失败为 `default Metal device is unavailable`，已完成自修范围内的 envsetup / clang cache / retry，但无法在本轮恢复 Metal-capable smoke 环境。

automation_blocker: true
