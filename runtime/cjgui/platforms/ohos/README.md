# CJGUI 鸿蒙（OHOS）后端 — 平台入口

更新：2026-09-26。**本目录是鸿蒙模拟器后端的 WIP 快照；A–E 整包尚未通过指导验收。**
已核对的局部链路包括仓颉核心→snapshot→消费 HAP 的来源对应、模拟器上的
自绘与公开 owner 操作，以及系统选区变化后的高亮、失焦结算和读回。
执行报告另有原票注入、Surface 生命周期、裁剪与含空格目录构建等结果；
它们各自保留原测试范围，不合并为完整生命周期、输入法或独立消费者验收。
当前优先处理 native 引用返回/归还、同进程停止重启、创建时回调身份、
系统组合态及选区替换、裁剪像素与命中负控、分段响应采样和不同字段结构消费者。
人工输入发生在模拟器，物理鸿蒙设备尚未验证。
执行自报见[第六轮集中报告](../../../../docs/plans/2026-09-26-harmonyos-execution-report-6.md)与
[第五轮](../../../../docs/plans/2026-09-25-harmonyos-backend-first-chain-execution-report-5.md)；
当前范围与判据以[第六次指导复核](../../../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#review6-current-package)优先，
唯一当前状态见[ACTIVE](../../ACTIVE_DIRECTION.md)。本页只作入口导航。

## 这是什么

`platforms/ohos/` 是 CJGUI 的鸿蒙自绘后端实验入口，目标是让普通仓颉消费者通过
公共模板与适配层复用 XComponent/OH_Drawing 服务，形成
「仓颉组件/布局/场景/共同操作 → 鸿蒙自绘显示 → 人与外部共同操作」的完整链路。
当前已有 HAP 正常路径运行证据，独立消费及生命周期/输入边界的待验范围见页首说明。

固定路线在本平台的表现：

- **仓颉持有全部业务与 UI 真相**：组件树、布局、场景、命中语义、共同操作契约
  （授权/期望版本/读回）都来自 `runtime/cjgui` 快照源码；平台桥不持有业务。
- **平台桥（本目录描述的 ohos_renderer）** 只做四件事：surface 租约与代际、
  OH_Drawing 测量/绘制与 GPU 提交、原始触摸 → 带身份的规范事件合成、
  生命周期观察。单行文字与 ArkTS TextInput 系统代理已进入实验实现，选区、组合态、
  回调身份与外部更新接续尚未通过完整验收。图片、非空命令菜单、非空数据传输、
  悬停/按压视觉层仍保留各自支持边界。
- `cjgui_internal_renderer_*` C ABI 按实际调用实现或显式拒绝；新增票据结构的旧32/40字节错配已修，完整布局/原始验证范围见当前任务，不能沿用旧接口数量作为通过证明；
  另有 255 个历史 no-draw 审计桥符号仅做链接覆盖（返回 0，真实路径不调用）。

## 装载模型（已实测定型）

官方 Hybrid 单模块：`ArkTS EntryAbility/页面(XComponent) + src/main/cangjie(仓颉包)
+ src/main/cpp(C++ 桥)`。

- ArkTS `import 'libcjgui_app.so'` 经官方 `ark_interop_loader` 完成仓颉运行时初始化
  （hilog：`LoadCJLibrary InitCJLibrary`）。
- C++ 桥对已加载库 dlsym 调用 `cjgui_ohos_app_main(ingress)`：注册 ingress
  函数指针块（surface 租约/触摸队列/前后台），仓颉侧 spawn 应用循环线程。
- 线程图：UI 线程（XComponent 回调，不阻塞）→ 仓颉应用循环（owner 串行、
  M:N 不依赖 OS 亲和）→ 固定原生渲染线程（GPU context/surface/排版单线程拥有）；
  present/measure 当前为任务投递+有界等待。取消阶段机、`acquireCommitPermission` 同临界区许可与
  显式状态码判别已接入；共享核心的 ACK 重试/关闭意图/首帧 StartingPending/原票
  三态分离已进入实际鸿蒙消费（共享源→snapshot→消费目录→HAP 逐文件哈希链验证）。
  Surface 使用许可与真实 XComponent CYCLE×10 压力循环已交付（第六轮报告）。

## 构建入口（可复现）

```
runtime/cjgui/platforms/ohos/
  snapshot/                     # 框架核心快照
  host/                         # 宿主/renderer/链接桩/CMake 来源
  scripts/env.sh                 # 工具链路径
  scripts/sync_platform.sh       # 同步到消费者；当前仍依赖仓库中的示例定义
  scripts/build_renderer.sh
  scripts/package_runtime_libs.sh
  scripts/verify_hap_closure.sh   # 提取/解析失败已拒绝，完整闭包负控见任务
  scripts/build_and_run.sh       # 接收 LAB_ROOT；独立产物/日志身份仍待收口
  scripts/external_client_probe.py
  scripts/transport_concurrency_probe.py
  scripts/verify_transport_reopen.py   # 旧半帧/取消证据入口
  scripts/verify_transport_gate.py    # 连接限额/取消/普通业务值测试
  scripts/verify_transport_reopen_v2.py   # 真关闭重开（旧socket半帧/超时负控）
  scripts/verify_transport_committing_probe.py  # Executing 票恰好一次
  scripts/verify_renderer_transaction_probe.py  # A1 注入矩阵 M1–M5
  scripts/verify_surface_lifecycle_probe.py     # A2 六类交错反例
  scripts/verify_app_lifecycle_probe.py         # A3 生命周期 L1–L3
  scripts/verify_clipping_probe.py              # D 裁剪/命中三重核对
  scripts/verify_emoji_empty_probe.py           # C emoji/空值往返
  scripts/verify_ime_proxy_chain.sh             # IME 代理链 T0–T6
  scripts/verify_hap_closure.sh   # 逐成员提取/ELF解析失败 BROKEN，三态负控
  scripts/verify_transport_reopen_v2.py # 重开已有证据；旧半帧与异常分类待补强
  scripts/verify_transport_committing_probe.py # 当前只覆盖transport Executing
  scripts/verify_ime_proxy_chain.sh    # 当前 T0–T8 为 name 编辑及旧输入拒绝链
  scripts/human_external_human_probe.py
labs/ohos_cjgui_app/              # 当前消费工程；transport已迁平台，ArkTS代理/独立消费待完成
  scripts/                      # 兼容 wrapper
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`
（模拟器免签安装）。构建目录与 macOS 的 `cjpm target` 完全分开。

### 本机已核实的构建关键点（避坑）

- `src/cpp` 旧布局会被 hvigor 静默跳过（CodeMap 只认 `src/main/cpp`）。
- escape/beta 仓颉 SDK 对 compatibleSdkVersion>=23 不自动打包运行时库，
  需按 NEEDED 闭包显式入包（含 `libohos.ark_interop.so` 不可用——SDK 里是
  mock 桩，真身在系统 ArkTS 运行时；打包它会遮蔽真身导致重定位失败）。
- 模拟器镜像缺 `libboundscheck.so`/`libc++.so`，需从 NDK 补齐
  （`libc++.so` 在 sysroot 是 linker script，须用 `libc++_shared.so` 实体顶替）。
- XComponent 回调注册：本 SDK 头只声明 `ArkUI_NodeHandle` 变体；
  ArkTS libraryname 注入对象经 `napi_unwrap` 取出 `OH_NativeXComponent*`。
- 渲染器 C++ 不得使用 `dynamic_cast`（与 libcangjie-std-ast 的
  `__dynamic_cast` 符号冲突曾导致 SIGSEGV）；用枚举标签分发。

## 外部共同操作通道（共享协议与实例化传输）

并发归属（Astra 定稿）：一帧一票一连接、每票独立结果槽、owner 单张认领、
Pending→Executing→Done/Cancelled 状态机、Cancelled（确定未执行）与
outcome_unknown（已授执行权）分开、队列/连接/字节有界、满时官方 server_busy、
requestStop/awaitClosed 自连接唤醒。正常并发 CAS 反例见 transport_concurrency_probe.py。
读帧限额（header ≤16 字节、帧 ≤8MiB、整帧绝对期限）、等待者取消后的额度回收、
context 绑定和更完整的 Closed 判据已有实现。B3 有服务端取消并恢复证据；
最新 stop 已采用分离队列和 finally 解锁，测试控制由 `@When` 与整帧验证接缝隔离。
新日志证明连接限额、4票服务端取消和合法字段包含控制关键字的正常写入。
SETTLE控制连接结束后由独立任务awaitClosed并重开listener，真实同PID时间线已有证据；
它没有停止应用owner/renderer。新重开/Executing探针的旧半帧、超时分类和回包判别仍按任务补强。

- 仓颉 `CjguiSharedOperationExternalConnection` 的私有描述符 unix socket
  硬编码 `/tmp`（OHOS 应用沙箱不可写）→ `connection.start()` 失败，属环境事实。
- 采用 Astra 预案的替代本地传输：应用内 loopback TCP 监听（`ohos_transport.cj`，
  纯传输），请求经公开入口 `connection.dispatchPayload()` 执行——授权、协议、
  版本与业务检查全部仍在仓颉 connection 内。帧格式与官方一致
  （`<字节数>\n<负载>`）。
- 主机客户端经 `hdc fport tcp:17856 tcp:7856` 访问，**标记为模拟器开发通道**；
  普通已安装应用的沙箱外连接方案待后续验证。
- 成功 INVOKE 置位的 `windowRefreshRequested` 由宿主循环消费
  （`consumeWindowRefreshRequest` + `window.requestRefresh`）。

## 生命周期现状（部分实测，完整契约待验）

- 身份分层目标：应用实例 → renderer session → surface generation →
  scene/resize version。surface 销毁与应用退出分流已改：XComponent `onDestroy` 不再调用 stopHost。
  但引用归还、真正owner退出和按实例启动/停止身份仍待修复；全局shutdownDone不能证明本实例退出。
- 宿主等到 surface Ready 才启动窗口会话；无 surface 时 present 返回
  可恢复的 `METAL_DRAWABLE_UNAVAILABLE`，不推进帧号、不接受候选。
- 同尺寸 surface 重建同样递增 resizeVersion（核心据此重交显示资源）。
- 早期日志和截图支持当时版本的 XComponent 挂载/卸载10次及计数操作；停止语义变更后该证据不能覆盖当前实现。
  当前代际检查与400ms等待不能保证裸 window 全使用期存活。owner连续性、旧代资源保护、真实尺寸变化及正常关闭收敛须按当前版本补齐。
- 空闲：30 秒 0 次提交；唤醒源为宿主循环 pump_event bounded-sleep（≤62.5Hz），
  不产生重建/布局/提交。

## 范围与证据

当前范围包括同源核心运行、自绘中文/控件、触摸与外部共同操作、surface 生命周期
恢复、基础单行文字及系统输入适配、可复现 HAP 与 macOS 同源回归。通用文字代理
与双字段消费按任务页接续；真实 IME 未验部分如实保留。图片资源、更完整富文本及
真机性能另列后续。证据索引：
`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/`（consultations/laya/build/run/
screenshots/verification）。
