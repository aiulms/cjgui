# Cangjie 1.1 Owner / Tooling / FFI Capability Intake

日期：2026-04-30

性质：sidecar research / language capability risk intake

状态：按需读取，不是每轮 implementation 的默认必读项。

## 用途

本文冻结一次针对仓颉 1.1.0 的能力边界判断，避免后续会话只记住结论、忘记依据。

它不改变当前 P1 runtime next opening，不授权 public API / C ABI / platform bridge / event loop / queue / renderer / IME / Accessibility 实现。它只在未来触碰 owner enforcement、FFI handle lifecycle、debug / profiling / memory tooling、platform bridge 或语言能力迁移时作为风险雷达读取。

## 当前基准

当前 CJGUI runtime package 以仓颉 1.1.0 为基准：

- 本机 `cjc -v`：`Cangjie Compiler: 1.1.0 (cjnative)`，target 为 `aarch64-apple-darwin`。
- 本机 `cjpm -v`：`Cangjie Project Manager: 1.1.0`。
- `runtime/cjgui/cjpm.toml` 使用 `cjc-version = "1.1.0"`。

后续判断默认基于仓颉 1.1.0、本地 CangjieSkills 和当前项目实际工具链，而不是泛泛假设仓颉未来能力。

## 1. Owner 边界不是 Rust 借用检查

仓颉 1.1.0 提供了能帮助 CJGUI 建立 owner 纪律的语言能力：

- `struct` 是值类型。
- `let` / `var` 能限制绑定和字段可变性。
- `mut` 函数对结构体原地修改有显式限制。
- `internal` / `private` / package 可见性可以收窄访问面。
- `class`、`Array`、`CPointer` 等引用 / 指针能力可以被封在 owner-local API 后面。

但当前没有证据显示仓颉 1.1.0 提供 Rust 等价的：

- 线性类型
- move-only resource
- 生命周期参数
- borrow checker
- 唯一可变借用 / 多个只读借用的编译期证明

因此 CJGUI 的 owner boundary 当前应被理解为：

> 编译期辅助 + 运行时 / 治理契约，而不是完整编译期证明。

当前 P1 选择的 internal-only、value-style state、immutable-copy transition、dehydrated fact、fail-closed gate 是必要补偿，不是过度保守。

## 2. 当前 Owner 设计应如何用仓颉 1.1 落地

短期应继续坚持：

- owner-local function 才能推进 owner truth。
- state 优先使用 `struct` + `let` facts。
- 不把 `class` reference、`Array` shared backing store、`CPointer` 或 platform handle 暴露成高层 truth。
- constructor / builder 负责建立合法 state shape。
- cross-owner summary 只消费上一层 report，不越级读取 lower-level facts。
- blocked / deferred path 必须 fail closed。
- GitNexus impact、build、smoke 和 sanity helpers 用来弥补编译期无法证明的部分。

需要特别注意：`let` 对引用类型只限制重新赋值，不等于深不可变；`Array` 虽然可表现为结构体 API，但底层数据可能共享。因此 owner boundary 不能依赖“看起来是 let”来证明深层不可变。

## 3. Debug / Profiling / Memory Tooling Reality

仓颉 1.1.0 工具链不是空白，但对 macOS GUI runtime 来说还不算完整成熟。

已确认能力：

- `cjdb` 基于 `lldb`，支持 Windows / Linux / macOS。
- `cjdb` 支持源码断点、函数断点、条件断点、变量查看、观察点、仓颉线程列表和线程栈。
- `cjcov` 支持覆盖率。
- `cjlint` 支持规范 / 安全类静态检查。
- `cjprof` 支持 CPU 采样、火焰图、堆 dump、对象引用和线程栈分析。

关键限制：

- `cjprof` 文档标注仅支持 Linux。
- `cjdb` 在 macOS 上调试可用，但表达式计算当前不支持 macOS。
- FFI / native crash、AppKit / Metal / Objective-C 对象生命周期问题仍需要系统级工具辅助。

因此 macOS GUI runtime 后续不能只依赖仓颉自带工具。进入真实 event loop / queue / platform bridge / render path 前，必须同时设计：

- internal cycle trace
- structured blocked / failure report
- state transition evidence
- smoke / screenshot / future pixel evidence
- Xcode Instruments / lldb / platform log 的辅助路径

## 4. FFI / Cross-Platform Reality

仓颉 1.1.0 的 C FFI 能力是可用基础：

- `foreign` / `@C` 声明 C 函数。
- `CFunc` 支持 C 函数指针和回调。
- `CPointer` 支持 C 指针。
- `@C struct` 支持 C layout 结构体。
- `CString` / `LibC` 提供 C 字符串与 C 内存分配释放能力。
- `unsafe` 将 FFI 风险显式标记出来。
- `cjc` 可输出动态库 / 静态库。
- `cjpm` 支持 FFI 配置和交叉编译 target 参数。

但这些能力主要是 C ABI 级桥接，不等于 AppKit / Objective-C / Swift / Metal / IME / Accessibility 的高级原生绑定。

当前判断：

- macOS 平台桥接仍应通过极窄 C / Objective-C shim 进入仓颉。
- 仓颉核心不应长期持有 raw pointer 或 platform object。
- handle owner、retain / release、destroy order 必须在 bridge boundary 冻结。
- 真实 IME / Accessibility / GPU resource lifecycle 不能被低估。
- 跨平台应在单平台 owner / bridge 经验稳定后再抽象。

官方安装文档也提示：工具链已适配 Linux / macOS / Windows，但完整功能测试主要集中在部分 Linux 发行版，Windows 基于 MinGW 且功能有欠缺。因此 CJGUI 不能把跨平台能力当成已完成前提。

## 5. 未来语言能力增强时如何回收红利

当前设计应保留“未来下沉到类型系统”的接缝。

如果仓颉未来提供更强能力，例如：

- 线性类型
- move-only type
- borrow / lifetime-like 检查
- read-only borrow
- effect system
- actor isolation
- resource type / deterministic release
- stronger opaque type / sealed module boundary

CJGUI 应优先把当前文档 / runtime 契约迁移为语言级约束。

迁移方向：

- 当前 owner-local function -> future owner capability / owner token。
- 当前 immutable-copy state -> future move-only state transition 或 unique state capability。
- 当前 runtime assertion / sanity helper -> future type / effect check。
- 当前 FFI handle contract -> future linear resource handle。
- 当前 local snapshot / controller handle -> future typed capability handle。
- 当前 unsafe bridge wrapper -> future resource-safe bridge abstraction。

这意味着当前 P1 的边界不是浪费。它把 owner、truth、projection、blocked path 和 FFI seam 先刻出来，未来语言变强时可以替换约束实现，而不是重写架构。

## 6. 设计结论

仓颉 1.1.0 足够支撑 CJGUI 做 internal runtime skeleton、C ABI bridge、value-style state pipeline 和受控平台实验。

它暂时不提供 Rust 级 owner enforcement，也没有给 macOS GUI 提供完整 profiler / memory analysis 闭环。

因此当前正确路线是：

- 继续用仓颉写核心 runtime truth / policy / state evolution。
- 继续把 platform bridge 压到极窄边界。
- 继续用 internal-only value objects 和 fail-closed reports 管住 owner。
- 不把 runtime assertions 和 governance 误解为最终形态。
- 未来仓颉语言增强时，优先把 owner / resource / FFI lifecycle 契约下沉到类型系统。

## 何时读取

只在以下开口前按需读取：

- owner boundary 从 internal draft 进入 public-facing contract
- state owner 从 value-style summary 进入真实 mutable runtime store
- FFI handle / native object / platform bridge lifecycle
- AppKit / Objective-C / Metal / IME / Accessibility bridge
- event loop / queue / scheduler / cross-thread UI update
- debug / profiling / memory leak investigation
- language feature migration / owner model normalization
- public API / public C ABI 前的 capability review

普通 P1 internal runtime bundle 不默认读取本文。
