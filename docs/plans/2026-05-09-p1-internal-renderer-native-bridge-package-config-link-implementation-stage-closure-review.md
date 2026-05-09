# P1 内部渲染器 native bridge package config link implementation 阶段复核

日期：2026-05-09

状态：value boundary closure / script-managed route

## 封账结论

本阶段没有修改 `runtime/cjgui/cjpm.toml`。package config link first slice 未打开；当前选择 script-managed link route stabilization，并新增 internal value owner 记录主包 package config link 的 artifact 生成风险、fallback 策略与停止线。

## 新增文件

- `runtime/cjgui/src/runtime_renderer_native_bridge_package_config_link.cj`

## 固定事实

- Runtime input：`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`
- Endpoint：`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`
- Actual route：script-managed route stabilization。
- Package config status：`runtime/cjgui/cjpm.toml` 未修改。
- Artifact policy：no-resource native object / static archive 仍由 probe 脚本在 `/tmp` 下生成。
- `--skip-script` 风险：主包 package config 不能依赖本轮未接入的脚本生成 artifact。

## 固定边界

- 未新增 actual runtime FFI call。
- 未新增 public API。
- 未新增 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Cocoa / Metal / QuartzCore。
- 未修改 smoke native files。
- 未修改 `runtime_state.cj`。
- 未发布 backend-ready truth。

## GitNexus 记录

在编辑 runtime symbol 前已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`：GitNexus 返回 UNKNOWN / not found，affected 0。
- `cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft`：GitNexus 返回 UNKNOWN / not found，affected 0。

按近期新增 owner 未索引处理，并以源码、build、probe 与 scan 兜底。

## 同形边界刹车

不得把本 closure、package config link owner、script-managed route、temporary package link evidence 或 no-resource callable 包装成 actual runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，package config link stage 完成 value boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 package config link owner；truth 限定为 script-managed fallback / artifact policy / config still deferred facts；stop-line 不放宽。
- 本轮是否改变唯一 next opening：将在 next-boundary 中固定。
- 是否同步 topic manifest：将同步。
- 已同步哪些 topic manifest：将在 manifest closure 中列出。
