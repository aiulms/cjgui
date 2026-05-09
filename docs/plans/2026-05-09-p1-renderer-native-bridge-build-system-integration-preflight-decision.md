# P1 渲染器 native bridge 构建系统接入预检判断

日期：2026-05-09

状态：docs-only preflight / no build config change

## 文件定位

本文件判断 production native bridge skeleton 是否可以进入构建系统接入 runway。它不修改 `.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 build script，不把 `runtime/cjgui/native/cjgui_native_bridge.m` 接入编译，不实现 callable C ABI / FFI，不修改 native skeleton 或 smoke lab。

本文件只决定下一刀是否仍应是 internal value boundary，用来固定 macOS-only gating、Objective-C compiler invocation、SDKROOT / deployment target、framework link 与 production build probe 的规划词汇。

## 上游事实

production native bridge skeleton 已由 [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md) 封账。当前 skeleton 文件是：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`

这两个文件没有接入 build / `cjpm` / FFI，没有声明 runtime callable function，也没有导入 Cocoa / Metal / QuartzCore。未参与 build 是上一轮明确固定的预期边界，不是漏测。

最新 runtime planning endpoint 仍是 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。production skeleton manifest 是 artifact / docs write-set evidence，没有 runtime endpoint，因此本轮如果新增 value owner，应消费 teardown planning endpoint，而不是临时创造跨层输入。

## 判断结果

可以打开 native bridge build integration runway，但第一切片不得修改 `runtime/cjgui/cjpm.toml`、build script 或 package config，也不得把 production `.m` 接入编译。

第一切片仍必须是 internal value boundary，原因是当前还没有固定：

- macOS-only gating：非 macOS 平台必须保持 no-op / deny posture，不能因 production `.m` 存在而破坏包构建。
- Objective-C compiler invocation strategy：`clang -fobjc-arc`、module、SDKROOT、deployment target 等策略只能先形成规划 facts。
- SDKROOT / deployment target / framework link strategy：不能把 smoke lab 的路径和 framework 列表直接搬进 production package。
- `cjpm` package 是否能直接 compile / link `.m`：当前证据不足，必须先做 build probe 规划。
- 是否需要 separate native build script：需要在后续 build probe preflight 中判断。
- smoke lab separation：`labs/macos_bridge_smoke` 继续是 feasibility evidence，不是 production bridge build source。
- callable C ABI absent verification：后续 probe 也应能证明 skeleton / object file 可处理，但不新增 callable C ABI。

## 候选比较

A 选择：`P1 internal Renderer native bridge build integration planning value boundary bundle implementation`。

选择原因：当前 production skeleton 已足够作为 build planning evidence，但直接修改 build config 风险过早。先新增 internal value owner，固定 build gating / compile-link admission / framework-link policy / build probe policy，能保持 runtime planning 链连续，并继续禁止 C ABI / FFI / native object。

B 暂缓：直接修改 `runtime/cjgui/cjpm.toml`。当前还没有 production build probe 策略，不允许。

C 暂缓：直接接入 production `.m` 编译。当前还未固定 macOS-only gating、framework link 与非 macOS 行为，不允许。

D 拒绝：callable C ABI / FFI implementation。当前只做 build integration planning，不进入 callable surface。

E 拒绝：AppKit / Metal object creation。build integration planning 不创建 native resource。

F 拒绝：继续新增 skeleton-ready / build-ready wrapper。下一刀必须新增 build gating / compile-link / framework-link / probe policy 语义。

## 同形边界刹车

不得把 production skeleton、C ABI surface contract、token ownership、teardown planning、smoke lab 或 build planning evidence 包装成 build integration permission、C ABI implementation permission、FFI permission、native-handle permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

若选择 A，下一轮只能新增 build gating / compile-link admission / framework-link policy / production build probe policy / no-native-bridge-build-integration readiness facts，而不是薄包装。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no build script / package config modification。
- no production `.m` compile integration。
- no native skeleton modification。
- no smoke lab native modification。
- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是。主题从 production skeleton manifest 后续入口推进到 build integration planning preflight。
- 本轮是否改变 canonical tail / endpoint：否。最新 runtime endpoint 仍是 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。preflight 选择下一步新增 build integration planning value boundary，并固定 build planning stop-line。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build integration planning value boundary bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build integration planning value boundary bundle implementation`
