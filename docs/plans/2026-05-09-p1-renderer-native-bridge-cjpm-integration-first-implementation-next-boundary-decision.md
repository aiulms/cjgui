# P1 渲染器 native bridge cjpm 接入第一实现后续边界判断

日期：2026-05-09

状态：next boundary decision / build glue verified

## 文件定位

本判断确认 native bridge `cjpm` integration first implementation build glue 是否足够作为当前阶段封账对象，以及下一步是否进入 manifest stabilization。

## 当前结论

`verify_native_bridge_cjpm_integration_boundary.sh` 足够作为当前 build glue endpoint。它串联 package build 与 skeleton isolated compile，但不改变 `cjpm.toml`，不把 production `.m` 接入 `cjpm build`，不接 FFI，不实现 callable C ABI，不创建 native object，也不改变 public surface。

当前阶段仍没有 runtime endpoint；最新 runtime endpoint 仍是上游 `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`。

## 候选比较

A 选择：`P1 internal Renderer native bridge cjpm integration first implementation manifest stabilization bundle`。build glue 已足够封账，下一步应固定 actual write set、build/probe entry、macOS-only behavior、no callable C ABI / no FFI / no native object stop-line。

B 暂缓：callable C ABI implementation preflight。该入口必须等 manifest stabilization 后再判断；当前 build glue success 不授权 callable surface。

C 暂缓：native bridge production status taxonomy hardening。当前 skeleton status taxonomy 仍足够支撑 build glue；无需本轮扩展。

D 拒绝：直接 FFI / AppKit / Metal / public API。

## 同形边界刹车

不得把 build glue、`cjpm build` success、skeleton compile success、C ABI surface contract 或 smoke evidence 包装成 callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

下一步只能做 manifest stabilization，不得直接进入 callable C ABI / FFI / native object。

## 设计意图出口自检

- 本轮是否改变主题状态：是。主题从 build glue implementation closure 推进到 next-boundary decision。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 runtime endpoint。
- 本轮是否改变 owner / truth / stop-line：否。沿用 build glue script truth / stop-line。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge cjpm integration first implementation manifest stabilization bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 下游后续入口

`P1 internal Renderer native bridge cjpm integration first implementation manifest stabilization bundle`
