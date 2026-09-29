# CJGUI 鸿蒙（OHOS）后端 — 平台入口

更新：2026-09-28。鸿蒙后端已在华为模拟器上验证真实 XComponent 引用与绘制、
Surface 生命周期、停止重开、裁剪/命中、系统输入及设置与 thermo 两款 normal HAP
的生成式控件和共享 PNG 图片消费。图片资源采用平台解码与自绘，支持 key/version、
fit/fill、父裁剪、异步加载和缓存；[本包证据](../../../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-image-resource-next)
限定了已验证范围。当前 SDK/镜像/输入法组合的 marked range
与取消回调仍待版本化对照，物理设备性能及发布审核另行验证。
当前短状态见[ACTIVE](../../ACTIVE_DIRECTION.md)。

## 这是什么

`platforms/ohos/` 是 CJGUI 的鸿蒙自绘后端入口，让普通仓颉消费者通过
公共模板与适配层复用 XComponent/OH_Drawing 服务，形成
「仓颉组件/布局/场景/共同操作 → 鸿蒙自绘显示 → 人与外部共同操作」的完整链路。
设置与 thermo 已各有 normal HAP 的真实生成控件、输入和 owner 读回证据。

固定路线在本平台的表现：

- **仓颉持有全部业务与 UI 真相**：组件树、布局、场景、命中语义、共同操作契约
  （授权/期望版本/读回）都来自 `runtime/cjgui` 快照源码；平台桥不持有业务。
- **平台桥（本目录的 ohos_renderer）** 承接 Surface 租约/代际、
  OH_Drawing 绘制与提交、原始触摸到规范事件、生命周期和系统 TextInput 代理。
  系统选区、外部换版后的输入接续与旧回调拒绝已有模拟器证据；图片使用同一自绘后端。
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
  Surface 使用许可、真实引用归还与同 PID 停止重开已有当前模拟器证据。

## 构建入口（可复现）

```
runtime/cjgui/platforms/ohos/
  snapshot/                       # 仓颉核心与共享协议的鸿蒙快照
  host/                           # XComponent 宿主、renderer 与 ABI 桥
  scripts/sync_platform.sh        # 同步平台与应用共同源码到消费工程
  scripts/build_and_run.sh        # 构建、闭包校验、安装与当轮启动归档
  scripts/verify_hap_closure.sh    # 按 HAP 实际 ELF NEEDED 验证依赖
labs/ohos_cjgui_app/              # 设置 normal HAP
labs/ohos_thermo_app/             # thermo normal HAP
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
- 主机客户端通过绑定指定 `--target` 的本轮独立本机端口转发至应用端口
  （设置 7856，thermo 7857）；创建回执、PID 与 HAP 哈希用于当轮身份核对。
  这是模拟器开发通道。
- 成功 INVOKE 置位的 `windowRefreshRequested` 由宿主循环消费
  （`consumeWindowRefreshRequest` + `window.requestRefresh`）。

## 生命周期与输入证据

当前模拟器证据按 HAP、PID、appInstance、Surface generation 与原票归档。
真实引用覆盖 XComponent 卸载期间的 Create/Flush 保活；STOP 覆盖 queued/committing
票据终态、ACK、资源收敛和同 PID 新实例重开。实际画面、裁剪、命中及 owner 更新
已有逐像素与公开读回证据。系统输入覆盖可见草稿、提交、非空选区替换、外部校准
及旧挂载回调拒绝；marked range/取消回调的当前版本边界见交接页。

## 范围与证据

当前范围包括同源核心、自绘控件、触摸与外部共同操作、Surface 生命周期、系统文字
代理及两款 normal HAP 的生成控件和图片消费；性能、物理设备
与发布审核保持各自证据范围。原始证据索引：
`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/`（consultations/laya/build/run/
screenshots/verification）。
