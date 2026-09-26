# CJGUI 仓颉优先鸿蒙宿主可行性与最小桥接复核

日期：2026-09-25

性质：聚焦可行性/架构决策；不接管当前实现，不宣称阶段验收。

动态工作区证据截止：2026-09-25 13:01 +0800；此后当前实现者的修改不在本文状态结论内。
证据目录：[artifacts/2026-09-25-cangjie-first-harmonyos-host-review](artifacts/2026-09-25-cangjie-first-harmonyos-host-review/README.md)

## 结论先行

**当前原生 surface 交付继续采用“最小 ArkTS 宿主 + XComponent + C++ 平台桥 + 仓颉 CJGUI owner/core”最稳妥；但必须把 ArkTS 压缩成系统要求的装载/生命周期/挂载适配层，不能让它拥有业务、场景、命中或可见控件真相。**

这不是因为仓颉不能做应用宿主。相反，本机已经证明仓颉可以真实承担 `UIAbility`、`WindowStage` 和纯仓颉页面。真正卡住“纯仓颉 + 现有 NativeWindow/XComponent 后端”的，是当前公开 SDK 中缺少一条可构建、可说明的 **仓颉页面树 → Native ArkUI 挂载句柄** 链路：

1. 仓颉 `kit.ArkUI.XComponent` 在当前 SDK 中不可访问，隔离编译明确失败；
2. Native ArkUI 能创建 `ARKUI_NODE_XCOMPONENT`，也能取得 `OH_NativeXComponent`；
3. 但公开的 `NodeContent / UIContext / FrameNode` 转换入口来自 ArkTS NAPI 值；仓颉 `UIContext` 没有公开导出对应 native handle，Native 头也没有独立创建 `NodeContent` 的公开入口；
4. “仓颉 Ability + 同模块 ArkTS XComponent 页面”的直接混合方案被当前 CangjiePreBuild 明确拒绝：模块只要含 ArkTS，`srcEntry` 就必须是 ArkTS 相对路径。

因此，**仓颉原生 XComponent 宿主目前是“公开契约受阻”，不是“永远不可能”**。一旦后续 SDK 提供仓颉 `XComponent`、`NodeContent`、`UIContext` 或页面 root handle 的正式桥，应立即复测并删除 ArkTS 适配层。

同时存在一个更接近“纯仓颉应用宿主”的候选：**仓颉 `Canvas + CanvasRenderingContext2D`**。本次隔离工程已经编译、打包成功；它可让 Ability、页面和绘制调用全部在仓颉侧。但它是一个新的 Canvas 渲染后端，不是现有 XComponent/NativeWindow/GPU 后端的等价替换。当前只应启动限界 spike，不应立即切换主线。

## 状态真相

| 能力 | 当前状态 | 证据边界 |
| --- | --- | --- |
| 仓颉 `UIAbility / WindowStage` | 可行 | 纯仓颉基线可构建；仓库已有运行资产。本次未抢占模拟器重跑 |
| 仓颉声明式页面 | 可行 | 纯仓颉基线 HAP 构建成功 |
| 仓颉直接声明 `XComponent` | 当前不可用 | `import kit.ArkUI.XComponent` 编译报 `not accessible` |
| Native 创建 XComponent | API 存在 | `ARKUI_NODE_XCOMPONENT`、`createNode`、`GetNativeXComponent` 均在公开头中 |
| 仓颉页面向 Native 提供挂载点 | 未找到公开链路 | 已查本地 Cangjie SDK、官方随包文档、Native 头；不能把“未找到”扩大为永久否定 |
| 仓颉 Ability + 同模块 ArkTS 页面 | 当前工具链拒绝 | `01103043`：模块含 ArkTS 时必须用 ArkTS entry |
| 纯仓颉 Canvas 页面 | **build/package 通过** | HAP 817 KiB；运行、输入、性能与恢复均 `not_run` |
| 当前 ArkTS + XComponent + 官方仓颉 import | A1 探针运行；新 owner 装载失败 | 13:00 HAP 已修复 runtime 库与 C linkage；当前停在 `libcjgui.so` 的 macOS native-bridge 未解析闭包 |
| 当前 C++ detached thread 调 `@C app_main` | 一次运行可见，架构不稳定 | 运行日志不等于线程/销毁/重试契约成立 |
| 设置与计数真实 E2E | 源码与 HAP 已接线，运行未进入 owner | `ohos_app.cj` 已创建真实 domain/controller/host；新 HAP 在动态重定位前失败，故画面/交互/外部读回仍未验 |

## 候选路线比较

| 路线 | 与目标一致性 | 当前可证伪结果 | 决策 |
| --- | --- | --- | --- |
| 纯仓颉 Ability + 公开 Native XComponent/NativeWindow | 最高；仓颉是真宿主，平台仅窄桥 | 缺公开挂载 handle；Cangjie XComponent 不可访问 | **保留目标，当前阻塞** |
| 仓颉 Ability + 同模块 ArkTS XComponent 页 | 生命周期更仓颉化，ArkTS 仅页面 | 当前插件在 CangjiePreBuild 拒绝 | **当前不可用** |
| 纯仓颉 Ability + 仓颉 Canvas 后端 | 仓颉覆盖 Ability、页面、绘制；无 ArkTS | 已 build/package；运行和框架等价性未验 | **限界 spike** |
| ArkTS Ability + 单一 XComponent + C++ 桥 + 仓颉 owner/core | 仍有最小 ArkTS 壳，但真实业务和框架可全部归仓颉 | A1 probe 已运行；真实 owner HAP 已构建但暴露一个可定位的 C linkage 装载错误 | **当前交付主线** |
| C++ `dlopen` + detached pthread 进入仓颉 `@C app_main` | 平台桥反客为主，运行时/线程/销毁难解释 | 一次运行成功；无稳定生命周期契约 | **只算探针，应移除** |
| 私有 `loadNativeView`、私有 runtime ABI | 表面上可减少 ArkTS | 无公开稳定契约、版本风险高 | **不采用** |

### 为什么 Canvas 值得试，但不能现在替换

仓颉随包官方文档明确提供 `Canvas`、`CanvasRenderingContext2D`、`onReady`、矩形、路径、文字和 `PixelMap` 绘制，起始 API 22；组件也支持通用事件。本次最小页面真实通过 Cangjie 编译和 HAP 打包，所以它不是纸面设想。

但对 CJGUI 而言，切换 Canvas 意味着新增一套渲染适配，而不是把平台句柄换个入口：

- 要把 CJGUI 已接受场景/绘制命令映射到 Canvas 2D；
- 要重新证明中文文字测量与绘制的一致性；
- 要证明连续帧调度、前后台、尺寸变化和重绘不会退化；
- 要证明触摸仍进入仓颉命中/owner，而不是由 ArkUI 控件代替业务；
- 要测量 CPU、GPU、掉帧和大场景开销，不能用“系统大概会 GPU 加速”代替数据；
- 它不提供当前 NativeWindow/EGL/OH_Drawing 路线的资源所有权与 present 控制，因此两者不能直接写成等价。

所以 Canvas 的正确标签是：**build-feasible candidate backend；runtime/performance/equivalence unproven**。

## 当前交付应保留的最小 ArkTS 边界

### ArkTS 只保留两件事

1. `EntryAbility`：接收系统生命周期，加载唯一页面，把 `foreground/background/shutdown` 转发给仓颉公开宿主入口；不保存业务状态。
2. `Index`：只声明全屏 `XComponent(type=SURFACE)`，负责系统要求的 native 模块绑定和创建/销毁通知；探针结束后删除 `Text/Button` 覆盖层。

ArkTS 不得拥有：设置值、计数、开关、授权、命中、版本、恢复状态、场景树或“是否操作成功”的判断。

### 仓颉必须是真正的应用 owner

- 构建 `CjguiApplication`/窗口会话和“设置与计数”场景；
- 拥有业务值、场景版本、命中和 action；
- 泵共同操作、输入与刷新；
- 对外返回与画面同源的值/版本；
- surface 消失时保留 owner 与已接受场景，重建后重绘；
- 决定何时提交下一帧，但不直接跨线程使用 NativeWindow/GPU 对象。

### C++ 只保留平台资源与线程亲和性

- XComponent surface 回调与 `OHNativeWindow` 引用/释放；
- surface generation、尺寸、density 和前后台投影；
- 原始输入采集与带 generation 的有界队列；
- 固定 native render thread，独占 OH_Drawing/EGL/GPU context、surface 和 present；
- 明确失败码、超时和 shutdown/join。

## 推荐的装载与启动链

当前 `Index.ets` 已经通过官方 `import { ... } from 'libcjgui_app.so'` 触发 ark_interop loader。应把它从“探针初始化器”提升为唯一受支持的仓颉启动入口：

```text
HarmonyOS
  → ArkTS EntryAbility / Index
    → official ark_interop import
      → Cangjie JSModule.bootHost()
        → Cangjie owner + managed task
          → accepted scene / input / shared operation
            → fixed native render thread
              → XComponent NativeWindow present
```

推荐迁移：

1. 在仓颉 `JSModule` 导出 `bootHost / setForeground / shutdownHost`，由官方 interop 调用；`bootHost` 在已初始化的仓颉运行时中创建唯一 owner，再用仓颉受管任务推进应用循环。
2. 删除 C++ `StartHost()` 中“新建 detached pthread → `dlopen` → dlsym `cjgui_ohos_app_main`”的启动责任。
3. 若 surface/touch 暂时仍需 C ABI 回调，C++ 只对**已由官方 loader 装载**的仓颉库投递窄 ingress，不能再承担运行时初始化和 owner 启动；后续把 ingress 固化为平台契约并减少 dlsym 候选路径。
4. 渲染仍由固定 native render thread 承担；仓颉 `spawn` 不当成 GPU OS 线程亲和保证。

这一迁移比“让 C++ 线程先进入仓颉，再在仓颉里 spawn”更可解释：官方 loader 初始化运行时，仓颉创建 owner，native 线程只拥有平台资源。

## 线程、生命周期与销毁契约

| 执行域 | 唯一所有权 | 不允许做的事 |
| --- | --- | --- |
| ArkTS UI thread | Ability 回调、XComponent 创建/销毁、官方 interop 短调用 | 业务判断、同步等待渲染、持有场景真相 |
| XComponent/native callback thread | 捕获 surface/input 事件并投递 | 直接改 owner、长时间绘制、无引用保存 window |
| Cangjie owner task | 业务/场景/版本/命中/共同操作 | 直接跨线程释放 GPU/native window |
| fixed native render thread | NativeWindow 引用、GPU context、surface、draw/flush/present | 生成业务状态、绕过场景版本 |

建议状态机：

```text
UNBOOTED → OWNER_READY → SURFACE_READY(generation N) → ACTIVE
                         ↘ SURFACE_LOST(generation N retired)
ACTIVE → BACKGROUND → ACTIVE
任意非终态 → STOPPING → STOPPED
```

关键规则：

- surface 创建时先取得正确的 NativeWindow 引用，再发布新 generation；
- 销毁时先退役 generation，停止接受新 present/input，再由 render thread 释放 surface/window；
- 每个 touch、resize、frame transaction 都带 generation；旧代显式丢弃；
- owner 与业务状态不随 surface 销毁；
- `shutdownHost` 停止接单、唤醒队列、join render/worker，再释放库与全局资源；
- 任何 start 失败必须回滚状态，允许可区分重试，不能永久卡在 `started=true`。

## 当前桥的具体风险

以下结论对应 13:01 复核时的 `cjgui_host_bridge.cpp` / `ohos_renderer.cpp` / `ohos_app.cj` 快照，不覆盖执行者后续修改。该快照已出现真实 `CjguiSettingsCounterDomain/Controller` 和 host 循环，且 `ohos_renderer.cpp` 用 C shim 把 `cjgui_ohos_app_main` 转给仓颉 `cjgui_ohos_app_main_cangjie`；下面讨论的是剩余宿主风险，不是否定这部分推进：

1. **运行时入口不受支持**：`StartHost` 创建 `std::thread`，在该线程 `dlopen/dlsym` 后进入仓颉 `@C app_main`，再 `detach`。官方 import 已证明可初始化仓颉运行时，因此没有必要继续让 native pthread 充当仓颉 owner 的出生点。
2. **没有真实 shutdown**：`stopHost` 只写日志，`appShutdown` 只清 foreground；线程不 join，owner 不停止，库不关闭，HAP/Ability 销毁与进程退出之间没有可验证契约。
3. **失败后不可恢复**：`g_appStarted` 在线程真正装载/查符号前就设为 true；任何后续失败都不回滚，下一次启动直接跳过。
4. **库句柄发布竞态**：worker 写 `g_cangjieLib`，UI/NAPI `ProbeCangjie` 无锁读并 dlsym；没有明确的 happens-before 或 ready 状态。
5. **surface 原始指针所有权不足**：lease 保存回调给出的裸 `void* window`，尚未看到跨线程使用所需的 `OH_NativeWindow_NativeObjectReference/Unreference` 配对。
6. **touch generation 采样可撕裂**：先验证 active/window，解锁后读取 touch，再重新加锁取 generation；中间销毁/重建可能把事件标到错误代。应在同一临界区捕获 lease 身份，投递前再校验。
7. **并发读写细节**：surface 创建日志在解锁后读取共享 generation；density 仍硬编码 `1.0`。这些都应在第一条真实绘制链前收敛。

### 截止 13:01 的当前装载阻塞

装载链先后暴露并推进了两层问题：

1. `libcangjie-std-ast.so` 缺包；随后打包脚本已把它装入 HAP；
2. `cjgui_ohos_surface_ready` 被 C++ 改名。动态符号表曾同时存在：

```text
UND  cjgui_ohos_surface_ready
DEF  _Z24cjgui_ohos_surface_readyv
```

源码中该函数定义在 `extern "C"` 块关闭之后。当前实现者已把定义移回 C linkage，13:00 HAP 的符号表只保留已定义的未改名符号；装载器也越过了这一层。这一前后对照确认了根因，不再把它列为当前阻塞。

当前真实错误已经前进为：

```text
Error relocating .../libcjgui.so:
cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked: symbol not found
```

对 13:00 HAP 的 `libcjgui.so` 做完整符号清单后，发现 **255 个唯一的未解析 `cjgui_native_bridge_*`**，首批明显属于 AppKit/Metal/CAMetalLayer 的历史平台探针。`ohos_renderer.cpp` 实现的是 `cjgui_internal_renderer_*`，并未提供这组 macOS bridge。说明根因不是“再漏一个 stub”，而是当前 `cjgui` source set 把 macOS-only FFI 引用一起编进了鸿蒙静态核心；仓颉编译通过并未验证动态装载闭包。

正确的下一步不是逐次启动、按 loader 报错补 255 个符号，也不是改 `RTLD_LAZY` 隐藏问题。应先生成完整的 packaged-ELF undefined/provider 对照，然后二选一收敛：

- 用 Cangjie 多平台 source set（内置 `os.ohos`）或 `@When[os == "Linux" && env == "ohos"]`，让公共仓颉 API 在 OHOS 走 OHOS 实现/显式 unsupported 分支，不引用 macOS foreign symbol；
- 对确实必须保留链接的内部探针，提供一份集中、可审计、fail-closed 的 OHOS native bridge 实现，返回明确不支持，绝不伪造 Metal/AppKit 成功。

可区分验证顺序：

1. 对 HAP 内每个 CJGUI `.so` 生成 `UND` 集合与包内 provider 集合；所有必需 `cjgui_*` 必须有唯一、平台正确的 provider；
2. 重建后 `libcjgui.so` 不再悬挂 macOS `cjgui_native_bridge_*`，同时公共 API 签名扫描不变；
3. 安装同一 HAP，日志越过 `dlopen` 和 `app_main_cangjie`，出现 `surface ready; starting settings-counter host`；
4. 最后才验证画面、输入、共同操作和恢复。仅“成功编译/打包”不算解除阻塞。

这些风险不否定现有 A1 探针价值；它们说明探针不能直接升级为产品宿主契约。

## 分两条线推进，而不是二选一押注

### 主线：最小 ArkTS + XComponent

当前阶段按下列顺序收敛：

1. **官方启动**：ArkTS import → Cangjie `bootHost`；删掉 detached raw-start。证明重复启动幂等、失败可重试、关闭可 join。
2. **surface 真相**：NativeWindow 引用、generation、resize/density、前后台、销毁顺序有日志和负例。
3. **真实帧**：固定 render thread 连续提交可区分多帧；无 surface/旧 generation 不推进 accepted frame。
4. **仓颉 owner**：设置、计数、开关全部由仓颉场景与 action 生成；移除 ArkUI 探针控件。
5. **共同操作**：外部客户端读→写→读与画面/owner 同版本；未授权、错误版本、旧 surface 均失败可见。
6. **恢复**：后台/前台和 surface destroy/recreate 后 owner 值不丢，旧代输入/帧被拒绝。

### 支线：纯仓颉 Canvas 限界 spike

只实现一个最小、可推翻的纵切，不复制完整框架：

1. 使用独立 bundle/Ability，安装本次纯仓颉 Canvas HAP；证明真实首帧和三帧可区分更新；
2. 将 CJGUI 最小绘制命令（背景、矩形、中文文字）映射到 Canvas；文字测量和像素结果与 accepted scene 对应；
3. Canvas 通用 touch 事件只转成 CJGUI pointer event，由仓颉 hit test 激活 `+/-/toggle`；
4. 共同操作读写同一个仓颉 owner；
5. 前后台、窗口尺寸变化与页面重建后恢复；
6. 记录 60 秒 frame pacing、CPU/GPU、内存、中文字形和大列表/多节点压力。

进入主线的条件：上述行为全部通过，并且性能/能力没有违反“高性能自绘 GUI 框架”目标。否则将 Canvas 保留为受限实验或工具型后端，不影响 XComponent 主线。

## 对未来纯仓颉 Native host 的重新开启条件

满足任一项即可重开，不靠猜私有 ABI：

- 仓颉 ArkUI 正式提供 `XComponent`；
- 仓颉正式提供 `NodeContent` / `ContentSlot` / `FrameNode` 或 `UIContext` native handle；
- Native ArkUI 正式提供不依赖 ArkTS NAPI 的页面 root/context/NodeContent 创建或获取入口；
- 华为给出受支持的“仓颉页面挂载 Native Node/XComponent”样例并在本 SDK 版本可编译运行。

重开时最小实验应是：纯仓颉 Ability/page → 公开 handle → Native create XComponent → surface callback → 可区分帧 → touch → 仓颉 owner → 销毁重建。缺任一环都不能写“已替代 ArkTS”。

## 工具与证据覆盖说明

- CodeLattice 项目视图未覆盖两个新 `labs/ohos_*` 工程，GitNexus 当前索引根为 `runtime/cjgui`，对 Harmony host 查询没有过程结果；这里的空结果只代表图覆盖不足，不代表无依赖或无实现。
- 架构判断因此以当前源码、安装 SDK、官方随包文档、隔离构建和现有运行资产为主。
- 已有 Astra 咨询用于线程亲和、surface generation、固定 render thread 和官方 loader 方向的交叉参考；本报告没有把模型答复当验收。
- 本地 Laya 实际执行了两轮候选分类。其“立即纯仓颉/立即切 Canvas”建议分别与编译硬约束、运行证据边界冲突，未采纳；完整请求、响应、概率和采纳理由均在证据目录。

## SDK 与官方资料基线

本次针对的精确环境：

- OpenHarmony Native/ETS SDK `26.0.0.105`，API 26；
- HarmonyOS Cangjie SDK `26.0.0.105`，platform 26；
- DevEco Cangjie plugin `26.0.0.821`；
- Cangjie compiler `1.2.0-beta.rc3 (cjnative)`；
- 应用 `targetSdkVersion 26.0.0`、`compatibleSdkVersion 6.1.1(24)`。

本地随 SDK/插件官方资料：

- `AbilityKit/cj-apis-app-ability-ui_ability.html`：仓颉 `UIAbility`、`onWindowStageCreate`；
- `arkui-cj/cj-apis-window.html`：仓颉 `WindowStage.loadContent`；
- `arkui-cj/cj-appendix-thread.html`：`UIThread: MainThreadContext` 与 UI 主线程提交；
- `arkui-cj/cj-canvas-drawing-canvas.html`、`cj-canvas-drawing-canvasrenderingcontext2d.html`：仓颉 Canvas，API 22 起；
- `arkinterop/cj-apis-ark_interop.html`：`JSModule.registerModule` 是仓颉向 ArkTS 导出；
- `arkui/native_node.h`、`arkui/native_node_napi.h`、`ace/xcomponent/native_interface_xcomponent.h`：Native Node/XComponent 与 NAPI 转换契约。

对应官方在线入口：

- [仓颉语言与 HarmonyOS 资源](https://developer.huawei.com/consumer/cn/cangjie)
- [ArkUI 概览（明确 XComponent 用于 C++ 自绘引擎接入）](https://developer.huawei.com/consumer/cn/arkui/)
- [ArkUI NativeModule C API 汇总](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/capi-arkui-nativemodule)
- [Stage 模型概览](https://developer.huawei.com/consumer/cn/arkui/arkui-stage)

资料结论限定在上述已安装版本。后续升级 SDK 后，应先重跑 E1/E2/E3 和 native handle inventory，再决定是否删除 ArkTS。

## 最终决策

1. **不等待纯仓颉 XComponent 才继续当前阶段**；继续最小 ArkTS + XComponent 主线。
2. **不接受 C++ detached pthread 作为长期仓颉启动器**；迁到官方 ark_interop 的仓颉 `bootHost`。
3. **把 ArkTS 缩到系统外壳**；业务、场景、交互、版本、共同操作与恢复全部归仓颉。
4. **启动独立纯仓颉 Canvas spike**；它是有真实编译证据的新候选，但未达到替换条件。
5. **保持删除路径**：一旦官方公开仓颉 Native mount contract 可用，用同一纵切证明后移除 ArkTS，而不是长期合理化桥接层。
