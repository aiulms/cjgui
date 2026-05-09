# P1 渲染器 native bridge 构建 probe manifest 稳定化收口复核

日期：2026-05-09

状态：manifest stabilization closure / isolated probe sealed

## 文件定位

本 closure 记录 native bridge build probe manifest 已完成封账。它只固定隔离 probe 的 script path、scope、temporary output policy 与 stop-line，不修改 build config，不接入 production `.m`，不实现 C ABI / FFI，不改变 runtime endpoint。

## 封账结果

已新增并封账：

- [native bridge build probe preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-preflight-decision.md)
- [native bridge build probe closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-build-probe-closure-review.md)
- [native bridge build probe next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-next-boundary-decision.md)
- [native bridge build probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-manifest.md)
- [verify_native_bridge_skeleton_compile.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh)

固定项：

- Probe script：`runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- Probe source：`runtime/cjgui/native/cjgui_native_bridge.m`
- Temporary output policy：`/tmp/cjgui-native-bridge-build-probe-*`
- Runtime endpoint：未新增；仍以上游 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()` 作为 planning endpoint。
- Current truth：isolated native bridge skeleton compile feasibility evidence / no-`cjpm`-integration evidence / no-callable-C-ABI evidence / no-runtime-bridge-readiness evidence

## 边界确认

本轮没有修改 `runtime/cjgui/cjpm.toml`、package config、production native skeleton `.h` / `.m`、`labs/macos_bridge_smoke/native/*`、`runtime_state.cj` 或 protected paths。

本轮没有把 `runtime/cjgui/native/cjgui_native_bridge.m` 接入 `cjpm build`，没有实现 callable C ABI / FFI，没有新增 runtime `.cj` FFI declaration，没有创建 native object、native handle、raw pointer 或 native pointer return，没有调用 retain / release / destroy，没有提交 GPU work，没有执行 render，没有写 renderer state，没有发布 public diagnostics，也没有扩 public API。

## 验证记录

最终验证记录：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过。输出目录为 `/tmp/cjgui-native-bridge-build-probe-grLQzI`，只生成隔离 object，未修改 source，未接入 `cjpm`，未调用 C ABI / FFI。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-build-probe-target --skip-script`：通过，保留既有 unused warnings，最终输出 `cjpm build success`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed。
- `git diff --check`：通过。
- 新 script / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs / README scope，避开 `reference_repos/`。
- README / tracker / plans README / runtime README reachability：通过，四个入口均可到达 build probe manifest / script / 唯一后续入口。
- 中文标题与中文正文抽查：通过，新增 Markdown 未使用 `Decision` / `Boundary` / `Verification` / `Next Opening` 作为主标题。
- protected path check：通过，`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行。
- comment-aware public declaration scan：通过，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native / build forbidden scan：通过，`runtime/cjgui/cjpm.toml`、production skeleton `.h` / `.m`、smoke scripts、`labs/macos_bridge_smoke/native/*` checksum 未变；未新增除 probe script 外的 production native 文件；未新增 runtime `.cj` FFI declaration。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：`risk_level=low`，`affected_count=0`，`affected_processes=[]`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native bridge build probe 已完成 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否。未新增 runtime endpoint，仍以上游 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()` 作为 planning endpoint。
- 本轮是否改变 owner / truth / stop-line：是。固定 probe script 的 truth / stop-line，但不新增 runtime owner。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build system integration implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 下游后续入口

`P1 internal Renderer native bridge build system integration implementation preflight decision` 已由 [native bridge build system integration implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-implementation-manifest.md) 接续封账；`cjpm` integration first implementation 已由 [native bridge cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md) 封账。当前下游唯一入口是 `P1 internal Renderer native bridge callable C ABI preflight decision`。
