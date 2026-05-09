# P1 渲染器 native bridge callable C ABI planning manifest 稳定化收口复核

日期：2026-05-09

状态：manifest stabilization closure / internal value boundary only

## 文件定位

本 closure 记录 callable `C ABI` planning manifest 已完成封账。它只固定 owner file、runtime input、canonical endpoint、default draft、current truth、stop-line 与下游入口，不修改 production native `.h` / `.m`，不实现 callable `C ABI`，不接 FFI。

## 封账结果

已新增并封账：

- [callable C ABI preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-preflight-decision.md)
- [callable C ABI planning value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-value-boundary-closure-review.md)
- [callable C ABI planning next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-next-boundary-decision.md)
- [callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md)
- [runtime_renderer_native_bridge_callable_c_abi.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_callable_c_abi.cj)

固定项：

- Runtime input：`CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness`
- Canonical endpoint：`CjguiInternalRendererNoCallableCAbiReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`
- Current truth：callable `C ABI` planning intent / callable naming policy / status-capability callable admission policy / no-resource callable guard / runtime FFI separation policy / no-callable-C-ABI readiness facts

## 边界确认

本轮没有修改 production native `.h` / `.m`、`runtime/cjgui/cjpm.toml`、package / build config、smoke native files、runtime `.cj` FFI declaration、public API files、`runtime_state.cj` 或 unrelated runtime owner。

本轮没有实现 callable `C ABI`，没有接 FFI，没有创建 native handle / raw pointer，没有返回 native pointer，没有 import / use Cocoa / Metal / QuartzCore in production skeleton，没有创建 AppKit / Metal object，没有调用 retain / release / destroy，没有提交 GPU work，没有执行 render，没有写 renderer state，也没有发布 public diagnostics。

## 验证记录

本宏包最终验证结果如下：

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：通过，确认 production native bridge 仍未被 `cjpm` source inclusion 接入，且无 callable `C ABI` / FFI。
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过，isolated skeleton compile 仍可用。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-callable-c-abi-planning-target --skip-script`：通过，输出包含 `cjpm build success`，仅保留既有 `230 warnings generated, 230 warnings printed.`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed。
- `git diff --check`：通过。
- 新 runtime / docs whitespace check：通过。
- Markdown absolute link missing target check：通过。
- README / tracker / plans README / runtime README reachability：通过。
- 中文标题与中文正文抽查：通过。
- protected path check：`runtime_state.cj` 仍为 `10065` 行，protected tracked paths 无本轮 diff。
- comment-aware public declaration scan：仍只允许并只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native / build forbidden scan：通过，production skeleton `.h` / `.m` 未修改，build config 未修改，smoke native files 未修改，未新增 runtime `.cj` FFI declaration，production skeleton 未出现 Cocoa / Metal / QuartzCore import、AppKit / Metal object 或 callable `C ABI` implementation。
- owner header / stop-line scan：通过。
- GitNexus `detect-changes --scope unstaged`：`Changes: 17 files, 18 symbols`，`Affected processes: 0`，`Risk level: low`。

验证结论只覆盖 callable `C ABI` planning value boundary 与 manifest 封账；不授权下一步直接接 FFI、创建 native object、修改 production native skeleton、修改 build config、暴露 public API 或写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native bridge callable `C ABI` planning manifest 已完成 stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前最新 runtime endpoint 改为 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，当前最新 owner 改为 `runtime/cjgui/src/runtime_renderer_native_bridge_callable_c_abi.cj`；truth 限定为 callable planning facts；stop-line 继续禁止 callable implementation、FFI、native object、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 下游同步

下游 [native bridge callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-manifest-stabilization-closure-review.md) 已完成。当前唯一后续入口随下游同步为 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`；这仍不授权直接新增 FFI declaration、runtime `.cj` FFI declaration、native object、native handle、raw pointer、AppKit / Metal resource、public diagnostics 或 public API。
