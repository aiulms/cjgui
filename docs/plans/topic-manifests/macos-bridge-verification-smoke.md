# macOS bridge / verification / smoke 主题 manifest

状态：docs-only / topic manifest / no runtime truth

## 主题定位

本主题记录 `labs/macos_bridge_smoke`、AppKit / Metal bridge boundary、auto-close smoke、用户可见窗口截图、Metal readback 和 verification harness 的证据角色。

## 当前状态

macOS smoke 已证明本机可以通过 C ABI / Objective-C shim 打开窗口、执行最小 Metal 清屏、自动关闭、输出 capability / lifecycle / frame metadata / render stats，并在 smoke-only 范围内完成截图与 readback feasibility evidence。

## 已落地现实

- P0 macOS bridge smoke 已完成窗口、Metal 清屏与 auto-close evidence。
- AppKit / Metal bridge boundary 已记录 FFI handle lifecycle、主线程 owner、teardown ordering、capability query 和错误处理哲学。
- automated GUI verification preflight 确认近期 owner 应是独立 verification harness，bridge 只提供窄 metadata / stats。
- 用户可见窗口截图 closure 证明当前本机 smoke 可生成目标窗口 bounds 截图 sample summary。
- Metal readback feasibility closure 证明 smoke-only clear-color probe 可以在 command buffer completion 后读取一个采样点 summary。

## 未落地与明确禁止

- smoke 不是正式 runtime。
- smoke verification 不是完整 GUI verification、pixel diff、frame hash baseline、offscreen renderer 或 Renderer / Scene implementation。
- readback / screenshot evidence 不授权 runtime backend implementation，不授权 native handle、Metal resource、command buffer、drawable 或 GPU submission。
- 当前任务不触碰 `labs/macos_bridge_smoke/`。

## 当前 owner 链摘要

labs smoke 是 feasibility / teardown / verification evidence owner；正式 runtime owner 不从 smoke 继承 truth。bridge boundary 只说明未来 bridge 层必须如何持有平台对象、校验 handle、遵守主线程和 teardown 顺序。

## 关键文档链

- [macOS bridge runtime preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)
- [macOS bridge smoke closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [AppKit / Metal bridge boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [automated GUI verification preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)
- [user-visible window screenshot closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [Metal readback feasibility closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [labs macOS bridge smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)

## 下次开 gate 前必须读取

开 bridge、native handle、teardown、visual verification、screenshot、readback、Metal backend 或 smoke harness gate 前，必须读取 smoke closure、AppKit / Metal bridge boundary、automated verification preflight 和相关 closure。

## 推荐下一步

本主题不自动开启实现。若未来要把 smoke evidence 迁移为 runtime verification capability，必须先 docs-only preflight，明确 owner、artifact policy、CI/headless 可行性和 stop-line。

## 禁止误读点

- `labs/macos_bridge_smoke` 只能作为 feasibility / teardown / smoke evidence。
- smoke 不成为 runtime truth。
- screenshot / readback 不等于完整视觉验证，也不授权 backend implementation。

## 维护备注

若新增 verification harness 或 smoke evidence，应明确它是 lab evidence、diagnostics evidence 还是 runtime owner truth；默认不得反向扩大 runtime public surface。
