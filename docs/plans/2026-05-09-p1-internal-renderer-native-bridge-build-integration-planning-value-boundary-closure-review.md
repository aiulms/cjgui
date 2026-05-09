# P1 渲染器 native bridge 构建接入规划 value boundary 收口复核

日期：2026-05-09

状态：implementation closure / internal-only value boundary

## 文件定位

本 closure 记录 native bridge build integration planning value boundary 已完成。它只新增 internal-only runtime owner，用于表达构建接入规划事实，不修改 build config，不接入 production `.m`，不实现 C ABI / FFI，不创建 native object，也不修改 native skeleton 或 smoke lab。

## 新增 owner

新增 runtime owner：

- [runtime_renderer_native_bridge_build_integration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_build_integration.cj)

固定符号：

- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`

选择该 runtime input 的原因：production native bridge skeleton manifest 固定的是 `.h` / `.m` artifact write-set evidence，没有 runtime endpoint；当前 runtime 链最新可消费的上游收束点是 teardown planning endpoint。直接把 skeleton manifest 临时创造为 runtime input 会跨层，因此本轮不这样做。

## 当前事实

新增 owner 只表达以下 internal-only dehydrated facts：

- native bridge build integration planning intent。
- macOS-only build gating policy。
- Objective-C compile / link admission policy。
- framework link admission / denial policy。
- production bridge build probe policy。
- no-native-bridge-build-integration readiness facts。

这些 facts 不代表 build integration permission、C ABI implementation permission、FFI permission、native handle permission、Metal / AppKit permission、backend-ready permission、renderer state write permission、public diagnostics permission 或 public API permission。

## GitNexus 记录

编辑前已对选定上游运行 GitNexus impact：

- `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`：`UNKNOWN / not found`。
- `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft`：`UNKNOWN / not found`。

归类：近期新增 owner 尚未被 GitNexus 索引。未出现 HIGH / CRITICAL 风险；本轮按源码、`cjpm build`、smoke 与 forbidden scan 兜底。

## 边界确认

本轮未修改 `runtime/cjgui/cjpm.toml`、build script、package config、production native skeleton、smoke lab native 文件、`runtime_state.cj` 或任何 protected path。

本轮未把 `runtime/cjgui/native/cjgui_native_bridge.m` 接入编译，未新增 runtime `.cj` FFI declaration，未实现 callable C ABI / FFI，未创建 native handle / raw pointer，未返回 native pointer，未创建 AppKit / Metal object，未调用 retain / release / destroy，未提交 GPU work，未执行 render，未写 renderer state，未发布 public diagnostics，未扩 public API。

## 同形边界刹车

本轮没有把 production skeleton、C ABI surface contract、token ownership、teardown planning 或 smoke evidence 包装成 build-ready、bridge-ready、C-ABI-ready、native-handle-ready、Metal / AppKit ready、backend-ready、public API、receipt、record 或 publication。

新增的是 build gating / compile-link admission / framework-link policy / build probe policy 语义，不是同构 ready wrapper。

## 验证记录

- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-build-integration-planning-target --skip-script`：通过；输出为 unused warnings，warning 形态与现有 internal owner 风格一致。
- 其余最终验证记录见本宏包 manifest stabilization closure。

## 设计意图出口自检

- 本轮是否改变主题状态：是。build integration planning 从 preflight 进入 internal value boundary implementation。
- 本轮是否改变 canonical tail / endpoint：是。新增 runtime endpoint `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。新增 `runtime/cjgui/src/runtime_renderer_native_bridge_build_integration.cj` 与 build planning truth / stop-line。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build integration planning closure / next boundary decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build integration planning closure / next boundary decision`
