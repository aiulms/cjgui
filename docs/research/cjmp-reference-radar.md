# CJMP 参考雷达

日期：2026-05-18

状态：sidecar research / future reference radar / not-current-runway

## 结论

CJMP 和 CJGUI 都处在“仓颉 UI / GUI”相关的大方向里，但不是同一条路线。

CJMP 更像传统跨平台 UI 框架的仓颉化与 ArkUI-X 体系延伸：它面向应用开发者提供组件、页面、引擎、平台适配、SDK 和测试体系。CJGUI 当前更像从底层往上打的 AI-native GUI runtime / renderer 实验：先把仓颉 runtime、AppKit / Metal 桥接、可审计 owner、极窄 C ABI、result envelope 和 AI 协作边界打穿，再决定稳定 public surface。

因此，CJMP 是重要参考对象，不是 CJGUI 当前路线标准，也不是当前 Renderer 主线 blocker。

## 已观察到的 CJMP 公开定位

公开入口：

- [CJMP 组织页](https://gitcode.com/CJMP)
- [CJMP Docs](https://gitcode.com/CJMP/Docs)
- [CJMP Engine](https://gitcode.com/CJMP/Engine)
- [CJMP CJFrontend](https://gitcode.com/CJMP/CJFrontend)
- [CJMP OpenSDK](https://gitcode.com/CJMP/OpenSDK)

根据公开 README / 组织页可见信息，CJMP 的自我定位包括：

- 构建支持 UI + 逻辑的高性能跨平台开发框架。
- 提供接近原生的性能体验。
- 支持多 UI 前端。
- Engine 由多 UI 前端适配层、UI 组件、渲染管线、图形引擎、执行引擎和平台适配层组成。
- Engine 基于 ArkUI-X 优化扩展，可构建支持鸿蒙、Android 和 iOS 的 UI Engine 程序。
- CJFrontend 提供仓颉侧 UI 前端，开发体验接近 `@Entry` / `@Component` / `Text` / `Row` / `Column` 这类 ArkUI 风格。

## 和 CJGUI 的差异

| 维度 | CJMP | CJGUI |
| --- | --- | --- |
| 主要路线 | 仓颉跨平台 UI 框架 / ArkUI-X 体系延伸 | AI-native 仓颉 GUI runtime / renderer 实验 |
| 当前重点 | 组件 API、跨平台 SDK、引擎集成、应用开发体验 | AppKit / Metal 底层链路、极窄桥接、owner truth、自动化验证 |
| 开发者入口 | `@Entry` / `@Component` / 组件式 UI | 暂不提供稳定 public API，先跑通底层 runtime / renderer |
| AI 原生定位 | 公开资料未体现为核心架构目标 | Semantic UI、Action Gateway、AI 生成 UI、preview / diff / reject 是长期北极星 |
| 可参考价值 | 高 | 自身主线不应被替代 |

## 未来值得参考的部分

当 CJGUI 进入 public API、组件层、跨平台 SDK 或应用开发体验设计时，可以按需参考 CJMP：

- 仓颉 UI API 的开发者体验，例如 `@Entry`、`@Component`、组件组合、生命周期展开方式。
- Engine 的模块划分，例如前端适配、组件、渲染管线、图形引擎、执行引擎、平台适配。
- SDK / Docs / Test / SystemLibs 的仓库组织方式。
- 跨鸿蒙、Android、iOS 的构建和发布经验。
- 仓颉与 Native / ObjC 互操作的工程资料。

## 当前不采纳的部分

当前 Renderer 主线不因为 CJMP 改向：

- 不把 CJMP 当成 CJGUI 的路线标准。
- 不迁移到 ArkUI-X 路线。
- 不提前设计完整组件库或稳定 public DSL。
- 不把“传统组件 API”当成 AI-native UI 的替代方案。
- 不让自动化线程为了 CJMP 停下当前 AppKit / Metal / Renderer first-slice 主线。

## 触发读取条件

默认自动化线程不需要读取本文件。只有出现以下场景时才按需读取：

- 准备设计 CJGUI public UI API / 组件层 / DSL。
- 需要对外解释 CJGUI 与已有仓颉 UI 框架的差异。
- 需要做竞品 / 参考项目对照。
- 需要判断某个 ArkUI 风格 API 是否值得借鉴。
- 需要评估 CJGUI 是否应接入跨平台 SDK / SystemLibs / 测试组织经验。

## 当前主线结论

CJMP 是雷达，不是方向盘。

当前 CJGUI 主线仍以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和最新 Renderer stage report 为准，继续推进 AppKit / Metal / Renderer first-frame 链路与 AI-native runtime 边界。
