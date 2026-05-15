# P1 Renderer 可见窗口生产 Harness 原生 NSWindow 预检决策

## 预检结论

预检通过，批准 bounded first slice：

- production native bridge 新增 token-backed `NSWindow` harness create / destroy / classify C ABI。
- runtime 侧新增 internal FFI call owner，只把 native 返回值脱水为 readiness facts。
- 新增 native probe 覆盖 main-thread gate、opaque token、table lifecycle、stale / double-destroy fail-closed 与 still-blocked facts。
- 更新旧 native guard，使旧的 no-object / no-resource guard 不再把本阶段批准的 `NSWindow` harness 误判为越界，同时仍阻断 `NSApplication`、`nextDrawable`、`present`、`commit`、encoder 与 pointer return。

## 不批准内容

- 不批准 visible order / `makeKeyAndOrderFront`。
- 不批准 `NSApplication sharedApplication`。
- 不批准 production `nextDrawable`。
- 不批准 command buffer / render encoder / draw / `commit` / `present`。
- 不批准 renderer state write、public API、public diagnostics 或 build config integration。

## GitNexus 预检

- `Function:native/cjgui_native_bridge.h:cjgui_native_bridge_surface_capabilities`：LOW，直接影响 0。
- `Function:native/cjgui_native_bridge.h:cjgui_native_bridge_nsview_create`：LOW，直接影响 0。
- `Function:src/runtime_renderer_platform_object_nsview_create_destroy.cj:cjgui_native_bridge_nsview_create`：LOW，impactedCount 3。
- `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness` 与 `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft`：图谱未找到，按 UNKNOWN 记录，使用源码阅读、build、probe 与 scan 兜底。

## 设计意图出口自检

- preflight 未把 scope unlock 升级成 backend-ready truth。
- preflight 只批准 token-backed native resource table first slice。
- preflight 明确要求 probe 证明 `nextDrawable` / command buffer / encoder / present 仍为 blocked facts。
- Same-shape Boundary Brake：不得新增同构 wrapper；runtime owner 必须消费上游 visible-window policy readiness 并给出新的事实出口。

## 执行路线

同轮继续 implementation：native C ABI、runtime internal owner、native probe、回归脚本边界调和、验证与阶段封账。
