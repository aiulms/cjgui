# 鸿蒙技术实验：普通应用能否取消 XComponent、直接向主窗口 Surface/Buffer 提交自绘画面

实验目录：`labs/ohos_main_surface_probe/`（独立实验，不参与生产后端；未修改
`labs/ohos_cjgui_app`、`labs/ohos_thermo_app` 或 `runtime/cjgui/platforms/ohos` 的任何文件）
日期：2026-09-28

---

## 0. 结论（先读这一段）

**判定：公开接口不可行；仅内部接口可行。「私有接口实验成功」，不是普通应用的稳定方案。**

| 环节 | 接口 | 分类 | 实测 |
| --- | --- | --- | --- |
| 取主窗口对象 | ArkTS `windowStage.getMainWindowSync().getWindowProperties()` | **公开** | ✅ id/rect 正常 |
| 窗口底色透明 | `OH_WindowManager_SetWindowBackgroundColor(windowId,"#00000000")` | **公开 NDK** | ✅ rc=0，且单独生效 |
| 主窗口触摸/按键 | `OH_NativeWindowManager_Register{Touch,Key}EventFilter(windowId,cb)` | **公开 NDK** | ✅ rc=0，真实触摸逐笔到达 |
| **取窗口 Surface** | `libwm.z.so!WindowSessionImpl::GetWindowWithId` → vtable `GetSurfaceNode()` → `librender_service_client.z.so!RSSurfaceNode::GetSurface()` | **私有 innerkit ABI + ABI 布局推断** | ✅ 全链路成功 |
| 包装成 OHNativeWindow | `OH_NativeWindow_CreateNativeWindow(&sptr)` | 公开声明，但入参来自私有 ABI | ✅ 成功（注意传参语义，见 §5.2） |
| 取 surfaceId | `OH_NativeWindow_GetSurfaceId` | **公开** | ✅ rc=0 |
| 由 surfaceId 再建句柄 | `OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId)` | **公开** | ✅ rc=0，返回同一指针 |
| 提交帧 | RequestBuffer / mmap / FlushBuffer | **公开** | ✅ rc=0，画面真实变化 |

**公开链路的精确断点**：公开 API 里**没有任何入口能返回本应用主窗口的 surface 或 surfaceId**。

- `@ohos.window.d.ts`（553303 字节）全文 0 次出现 `surface`（大小写不敏感）；`WindowProperties` 只有
  `windowRect/drawableRect/type/isFullScreen/isLayoutFullScreen/focusable/touchable/brightness/
  isKeepScreenOn/isPrivacyMode/isTransparent/id/displayId`。
- NDK `window_manager/oh_window_comm.h` 的 `WindowManager_WindowProperties`（sizeof=56）字段同上，**无 surface/surfaceId**。
- `OH_WindowManager_GetAllMainWindowInfo` 返回的是 `{displayId, windowId, showing, label}` —— 没有 surfaceId，
  且需要 `ohos.permission.CUSTOM_SCREEN_CAPTURE`（普通应用拿不到）。
- ArkTS 侧能拿到 surfaceId 的只有 XComponent（`XComponentController.getXComponentSurfaceId()`）
  以及 video/camera/image-receiver 等**应用自己创建的**生产者。
- **关键反证**：一旦有了 surfaceId，公开入口 `OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId)`
  立刻可用（实测 `rc=0`，且返回与私有链路相同的 OHNativeWindow 指针）。断的不是「提交能力」，
  而是「surfaceId 的公开来源」。

因此：**当前版本下，普通 HAP 无法只靠公开接口取得主窗口可提交 Surface**；本次成功依赖
`libwm.z.so` / `librender_service_client.z.so` 的内部 ABI（SDK 无头文件、`libwm.map` 版本脚本未导出该符号），
且其中两步是 ABI 布局/虚表槽位推断。按实验判据只能记为「私有接口实验成功」。

已排除、不计入成功结果的对照：**ArkUI Native RenderNode / native_embed / nativespawn / 子窗口一律未使用**。
实验画面提交到的是应用自己的**主窗口**（windowId 由 `getMainWindowSync()` 给出，
窗口 rect 1320×2856 = 整屏，不是子窗口、不是浮窗）。

---

## 1. 环境身份（可复核）

```
SDK:       /Applications/DevEco-Studio.app/Contents/sdk/default/openharmony
           apiVersion=26  version=26.0.0.105  releaseType=Release  platformVersion=26.0.0
设备:      emulator 6.1.0.117(SP37DEVC00E115R4P11)
           const.ohos.apiversion=24   const.product.model=emulator
           const.product.cpu.abilist=arm64-v8a   const.build.characteristics=default
安装方式:  devecocli build --build-mode debug → 未签名 HAP → hdc install -r（普通 normal HAP，
           无系统签名、无 root、未改系统镜像、无伪造仓颉元数据；HAP 内只打包 libentry.so + libc++_shared.so）
```

| 证据组 | HAP sha256 | PID / windowId / surfaceId |
| --- | --- | --- |
| **final_evidence**（控制组+三帧+触摸+释放重取） | `7fa850f10b70eb8923862f9bc38854becf0b359ea1b657d3616471470a7b403f` | pid 18775 / windowId 99 / surfaceId 3289944948867 |
| **final_evidence_rebuild**（清空 build 后重建，复核一致） | `a300eb3eb9d86f10413b65fa07d51e9bf46c728849ec8cbdeaaf344891b853bc` | pid 22144 / windowId 100 / surfaceId 3289944948871 |
| exp15（**纯 NDK 透明**归因） | `7fa850f1…` | pid 18679 / windowId 99 |
| exp16（4 个候选入口逐个复测） | `7fa850f1…` | pid 19222/20651/20937 |
| exp13（无 ArkTS 传 id 的窗口枚举） | `bbd0c389…b307a95d12` | pid 14274 / windowId 96 |
| exp11/exp12（旋转、前后台） | `63769897…b0ae90a2` | pid 12399 / windowId 95 / surfaceId 3289944948859 |

> **关于可复算性**：HAP 是 zip，内含构建时间戳，因此**逐次构建 sha256 不同**（重建后仍是 1506536 B、
> 行为一致，见 `final_evidence_rebuild/`）。要锚定「同一份代码」请看源码与 `libentry.so` 指纹：
> `artifacts/run/final_evidence_rebuild/fingerprints.txt`，其中
> `main_surface_probe.cpp 6d354ab1…`、`Index.ets a4b5d8c9…`、`EntryAbility.ets 2e0bd9cc…`、
> `libentry.so 48f129150fb08eaa92796ab75218660b9d40661d7e3b7e5387c6f3f1c28cc4f8`。
> 清空 `entry/build`、`entry/.cxx` 后 `bash scripts/probe.sh build` 约 5 秒可重建。

设备侧被引用的系统库（已拉起核对，sha256 见 §7）：

```
/system/lib64/libwm.z.so                        2515680 B  sha256 6cbff57f33874ecd79590dfc391878bc4a69659ff5ff525be620ce3347dfda36
/system/lib64/librender_service_client.z.so     3190272 B  sha256 dcce0719206403e8415781003462f96c6e5894eeed555e5f12ed6a758ab526a1
/system/lib64/ndk/libnative_window_manager.so    116072 B  sha256 a77267f000246a5af56c5a35cdb9c2cda74d5d75ea382d1139dcbc3e9f7b7132
```

---

## 2. 上游调用链核对（对着真实源码核，不靠推断）

对 GitCode/GitHub 上游 `openharmony` 镜像逐文件取原文核对：

1. **`OHOS::Rosen::Window::GetSurfaceNode()`** —— `window_window_manager/interfaces/innerkits/wm/window.h`，
   声明为 `virtual std::shared_ptr<RSSurfaceNode> GetSurfaceNode() const { return nullptr; }`（内联默认体，非纯虚），
   无 `#ifdef` 守卫。位于 **innerkits**（系统内部）而非 NDK 头文件。实现分两处：
   `WindowImpl::GetSurfaceNode()`（`wm/src/window_impl.cpp`）与 `WindowSessionImpl::GetSurfaceNode()`
   （`wm/src/window_session_impl.cpp`）。`wm/libwm.map` 的版本脚本里**没有**该符号（`local: *;` 兜底）。
2. **`RSSurfaceNode::GetSurface()`** —— `graphic_graphic_2d/rosen/modules/render_service_client/core/ui/rs_surface_node.h`，
   `sptr<OHOS::Surface> GetSurface() const;`（`#ifndef ROSEN_CROSS_PLATFORM`），类标了 `RSC_EXPORT`。
   实现返回 `RSSurfaceConverter::ConvertToOhosSurface(surface_)`。
3. **ArkUI 走的是同一条链**：`AceContainer::SetView/SetViewNew` → `NG::RosenWindow` 构造函数
   （`frameworks/core/components_ng/render/adapter/rosen_window.cpp`）→ `window->GetSurfaceNode()` →
   `RSUIDirector::SetRSSurfaceNode()` → `rootNode->AttachRSSurfaceNode(...)`。
   ArkUI **不**把主窗口 surface 包成 OHNativeWindow。
4. **生产/消费关系**：RS 侧 `RSRenderPipelineAgent::CreateNodeAndSurface` 在 RenderService 里建
   `IConsumerSurface`，把 `Surface::CreateSurfaceAsProducer(producer)` 经 IPC 交回客户端 ——
   **应用进程持有自己主窗口 surface 的 producer**。（与本次实测能 RequestBuffer/FlushBuffer 一致。）
5. **合成顺序**：`RSSurfaceRenderNodeDrawable::OnGeneralProcess` 依次画
   ①背景 → ②`surfaceParams.GetBuffer()!=nullptr` 时的自绘 buffer → ③DrawContent/DrawChildren（ArkUI 树）。
   ArkUI 树在 buffer **之后**画 —— 这正好解释了本次实测「窗口底色不透明时自绘画面看不见，
   改成透明后立刻可见」（§4.2）。
6. **`OH_NativeWindow_CreateNativeWindowFromSurfaceId`** 文档原文：`If the surface obtained through
   surfaceId is created in this process, the surface cannot be obtained across processes.` —— 走的是
   **进程内** `SurfaceUtils` 注册表，因此「本进程创建的生产者 + 本进程查表」是它设计的用法；
   无 `@permission` 声明。（与实测 rc=0 一致。）

---

## 3. 实验工程与运行方式

```
labs/ohos_main_surface_probe/
├── AppScope/app.json5                     bundleName=com.example.ohosmainsurfaceprobe
├── entry/src/main/ets/entryability/EntryAbility.ets   极薄 Ability：取主窗口 → 交 windowId 给原生
├── entry/src/main/ets/pages/Index.ets                 控制卡（触摸落点）+ 报告回读，**无 XComponent**
├── entry/src/main/cpp/main_surface_probe.cpp          全部分层探针（L0…L4 + 附表）
├── entry/src/main/cpp/CMakeLists.txt
├── scripts/probe.sh                       build / install / start / logs / shot
└── artifacts/                             原始日志、截图、崩溃日志、设备身份
```

运行命令：

```bash
cd labs/ohos_main_surface_probe

# 构建 + 安装
bash scripts/probe.sh build
bash scripts/probe.sh install

# 启动：probeLevel 是位掩码  1=装载私有库 2=取窗口与Surface 4=提交两帧 8=硬件合成开关
#                            16=窗口枚举  32=NDK 透明    probeCandidate 1..4 = 四个候选入口
bash scripts/probe.sh start 3  -1 2      # 透明+取Surface，不自动提交
bash scripts/probe.sh start 39 -1 2      # +提交两帧（蓝、橙白棋盘）
bash scripts/probe.sh logs
bash scripts/probe.sh shot myshot
# 另有启动参数 rotate=1/0（横竖屏）、arktsTransparency=0（跳过 ArkTS 透明，用于归因）
```

页面按钮（`uitest uiInput click <x> <y>` 可点，坐标用 `uitest dumpLayout` 取）：
`公开层 / 私有库 / 取Surface / +硬件合成 / 候选1..4 / 帧0 蓝 / 帧1 橙格 / 帧2 青条 / 转横屏 / 转竖屏 / 释放`。

---

## 4. 实测结果与证据

### 4.1 核心判据：提交至少两帧不同颜色/图案，实际窗口截图证明画面变化 ✅

证据目录 `artifacts/run/final_evidence/`（HAP `7fa850f1…`，pid 18775，windowId 99）：

| 截图 | 触发 | 截图采样主色 | 判定 |
| --- | --- | --- | --- |
| `1_control_no_frame.jpeg` | 启动后未提交任何帧 | 无主导色（`(10,88,246)` 49 格 = ArkUI 按钮、`(151,152,156)` 41 格 = 背景桌面） | 无自绘内容 |
| `2_frame0_solid_blue.jpeg` | **真实触摸**「帧0 蓝」 | `(29,107,255)` **636/1401 格**（= 0x1E6BFF） | 整窗纯蓝 |
| `3_frame1_orange_checker.jpeg` | 真实触摸「帧1 橙格」 | `(255,138,0)` 211 格 + `(255,255,255)` 404 格 | 橙白 32px 棋盘 |
| `4_frame2_cyan_bars.jpeg` | 真实触摸「帧2 青条」 | `(16,16,16)` 323 格 + `(7,229,188)` | 青/黑 16px 竖条 |
| `5_after_release_reacquire_blue.jpeg` | 释放→重取→再提交 | `(29,107,255)` 636 格 | 重取后仍可绘制 |

图案相关性是逐像素核对过的，不是「颜色接近」：对 32px 棋盘按 `(x/32 + y/32)` 奇偶取样，
屏幕上橙/白交替相位与提交数据一致（`OWOWOWOW…`）；对 16px 竖条按 8px 步长取样，
屏幕呈 `DDCCDDCCDDCC…`（周期 32px），与缓冲区里 `px[x]=16` 竖条完全对应。

对应原始日志 `artifacts/run/final_evidence/hilog_key_events.txt`：

```
SUBMIT handle 1320x2856 stride=5280 fmt=12 size=15079680 fd=40
SUBMIT mmap OK addr=0x7f3ab9e000 size=15079680
SUBMIT FlushBuffer pattern=0 rgb=0x1e6bff rc=0 frames=1
submitFrame frame=0 rc=0 status=windowId=99 ... surfaceId=3289944948867 reqRc=0 flushRc=0 frames=1
...
SUBMIT FlushBuffer pattern=1 rgb=0xff8a00 rc=0 frames=2
SUBMIT FlushBuffer pattern=2 rgb=0x10e0c0 rc=0 frames=3
NAPI destroyNativeWindow rc=0
L3 PUBLIC OH_NativeWindow_GetSurfaceId rc=0 surfaceId=3289944948867
SUBMIT FlushBuffer pattern=0 rgb=0x1e6bff rc=0 frames=4
```

### 4.2 硬前提：窗口底色必须透明，否则自绘 buffer 被 ArkUI 树盖住

同一 HAP、同一提交路径，只改窗口底色：

- 不透明（默认白）时：`exp1/exp2` 两帧都 `rc=0`，但截图与基线**逐格相同**（白 + 卡片灰），画面无变化。
- 透明后：立刻可见（§4.1）。
- 透明入口有公开 NDK 等价物，且**单独生效已归因**：`exp15`（`arktsTransparency=0` 显式跳过 ArkTS 调用）
  日志 `BGND PUBLIC OH_WindowManager_SetWindowBackgroundColor(windowId=99, "#00000000") rc=0`，
  截图仍是完整橙白棋盘。

这条与上游 `OnGeneralProcess` 的绘制顺序吻合：buffer 在下、ArkUI 树在上，所以
**ArkUI 侧任何不透明底色都会盖住自绘内容**；反过来也意味着主窗口上没法同时保留常规 ArkUI 界面。

### 4.3 真实触摸 ✅（公开接口）

`uitest uiInput click` 是系统输入注入，不是脚本直接调业务函数。日志显示触摸**同时**到达两处：

```
TOUCH PUBLIC filter#1 action=1 finger=10000 xy=139,534 windowId=99     ← 原生触摸过滤器（公开 NDK）
TOUCH PUBLIC filter#2 action=3 finger=10000 xy=139,534 windowId=99
submitFrame frame=0 rc=0 ...                                            ← ArkUI onClick（过滤器返回 false 放行）
```

过滤器回调里的 `action/finger/displayX/displayY/windowId/actionTime` 都能读到（`OH_Input_GetTouchEvent*`），
`RegisterTouchEventFilter` 与 `RegisterKeyEventFilter` 均 `rc=0`。**这条是纯公开接口，不依赖 XComponent。**

### 4.4 前后台切换 ✅ / 尺寸变化 ✅ / Surface 释放 ✅

- **前后台**：`uitest uiInput keyEvent Home` → 日志 `onBackground`；`aa start` 回前台 → `onForeground`，
  同一 PID 12399；回前台后原 OHNativeWindow 继续可用，提交 `data rc=0`，整屏为青/黑竖条。
- **尺寸变化（横竖屏）**：`setPreferredOrientation(LANDSCAPE)` 后窗口 `rect=0,0 2856x1320`，
  **surface 自身 geometry 跟随变为 2856x1320**，RequestBuffer 返回 `2856x1320 stride=11424`，
  提交后整屏铺满（1401/1401 采样格为主色）。
  ⚠️ 踩坑记录：一开始渲染侧用启动时缓存的窗口尺寸去 `SET_BUFFER_GEOMETRY`，旋转后把 buffer 强行拉回
  1320×2856，画面只覆盖左上角一块（`exp10` 反例）。**必须以 surface 自己的 geometry 为准**。
- **Surface 释放/重取**：`destroyNativeWindow rc=0` 后重新走一遍私有链，`RSSurfaceNode*` 与 `Surface*`
  相同、`surfaceId` 相同、`OHNativeWindow` 是**新指针**，再提交仍 `rc=0` 且画面更新。
  注意：这里释放的是**应用侧 OHNativeWindow 包装**，不是窗口的 RSSurfaceNode —— 主窗口 surface
  由 ArkUI/RS 拥有，应用侧没有「销毁主窗口 surface」的公开语义。

### 4.5 候选入口与私有链的实测细节（4 个候选逐个复测）

§5.1 的 sret 调参纠正后逐个复测（`artifacts/run/exp16_candidates/candidates.txt`）：

| 候选 | 符号（libwm.z.so） | 结果 |
| --- | --- | --- |
| 1 `Window::GetWindowWithId` | `_ZN4OHOS5Rosen6Window15GetWindowWithIdEj` | ✅ 返回 `Window*`，后续 GetSurfaceNode/GetSurface/surfaceId 全通 |
| **2 `WindowSessionImpl::GetWindowWithId`** | `_ZN4OHOS5Rosen17WindowSessionImpl15GetWindowWithIdEj` | ✅ 同上；vtable[0] == `WindowSessionImpl::GetSurfaceNode` |
| 3 `WindowSceneSessionImpl::GetMainWindowWithId` | `_ZN4OHOS5Rosen22WindowSceneSessionImpl19GetMainWindowWithIdEj` | ✅ 同上 |
| 4 `WindowImpl::GetWindowWithId` | `_ZN4OHOS5Rosen10WindowImpl15GetWindowWithIdEj` | ⛔ 返回 `Window* = 0`（本进程不存在 WindowImpl 实例），不崩、不可用 |

**结论修正**：先前 4 个候选全部崩溃是**我们调用约定错**（§5.1），纠正后 3 个可用、1 个（WindowImpl）
因本进程没有该实现而返回空。也就是说这条私有链在本镜像上比预期更"宽"：候选 1/2/3 都能走通。

只读环境事实（`artifacts/run/*/hilog_*.txt` 的 `L1 maps` 段）：
`libwm.z.so`、`librender_service_client.z.so` **本来就在应用进程里**（作为公开 NDK 库
`libnative_window_manager.so` 的 NEEDED 被加载）；`dlopen` 用**裸名**失败（应用命名空间搜不到
`/system/lib64`），用 **`/proc/self/maps` 里读到的绝对路径**成功。

### 4.6 崩溃与版本边界（如实记录，不当作成功）

- `RSSurfaceNode::SetContainerWindow(bool, RRectT<float>)` 在**主窗口节点**上调用**崩溃**：
  `SIGSEGV(SEGV_MAPERR)@0x3`（近空指针），栈顶就是该函数 +140。
  该步骤本意是让 RS 把自绘 buffer 当硬件层合成；实测**不需要它**（透明前提已足够），
  因此这是一次失败的私有探索，未计入结论。
- **版本边界**：`OH_NativeWindowManager_GetTouchEventFilter` 声明为 `@since 26.0.0`，
  但本机镜像 `const.ohos.apiversion=24` 不导出它。**直接链接会让整个 `libentry.so` 重定位失败**：
  `Error relocating /data/storage/el1/bundle/libs/arm64/libentry.so: OH_NativeWindowManager_GetTouchEventFilter: symbol not found`
  → JS 侧 `import` 得到 `undefined` → `TypeError: Cannot read property setWindow of undefined` 崩溃。
  已改为运行时 `dlsym` 可选探测。**SDK 26 编译 ≠ 镜像 24 有该符号**，注册类接口（15.0.0）则正常。

---

## 5. 私有链的两处 ABI 陷阱（复现者必读）

### 5.1 `sptr<T>` / `std::shared_ptr<T>` 是 **sret 返回**，不是 x0

`Window::GetWindowWithId`、`GetSurfaceNode`、`RSSurfaceNode::GetSurface` 都返回带非平凡析构的类类型，
按 Itanium C++ ABI 属于 *non-trivial for the purposes of calls*，**返回值经 x8 隐藏指针返回**。
反汇编可直读：

```
0000000000110fe4 <Window::GetWindowWithId(unsigned int)>:
  11100c: mov  w20, w0
  111010: mov  x19, x8          ← x8 是 sret 指针
  111028: ldr  x8, [sp, #8]
  11102c: str  x8, [x19]        ← 写回调用者的临时对象
```

按 `void*(*)(uint32_t)` 调用时 x8 残留上一次的函数地址，`str x8,[x19]` 写成「往代码页写」→
`SIGSEGV(SEGV_ACCERR)@<函数自身地址>`。用带非平凡析构的 16 字节载体承接即可（同时兼容 8/16 字节布局，
载体析构空实现 → 最坏只是多持一个引用）。**这条纠正后，4 个候选全部从「崩溃」变成「正常返回」**，
也说明最初的崩溃不是鸿蒙的限制。

### 5.2 `OH_NativeWindow_CreateNativeWindow` 要传「指向 sptr 的指针」

头文件原文：`@param pSurface Indicates the pointer to a ProduceSurface. The type is a pointer to sptr<OHOS::Surface>`。
传裸 `Surface*` 会在 `CreateNativeWindowFromSurface → RefBase::IncStrongRef` 处
`SIGSEGV(SEGV_ACCERR)`（artifact `cppcrash…162920337`）。正确做法是传 `&sptr`（sptr 布局就是单个
`Surface*`，槽位地址即合法 `sptr<Surface>*`）。另外该函数自 API 12 起标 `@deprecated`，
更推荐的路子是拿到 surfaceId 后走 `OH_NativeWindow_CreateNativeWindowFromSurfaceId`（公开且未废弃）。

---

## 6. 系统 TextInput 代理在去掉 XComponent 后怎么办（接线缺口）

**先说结论：代理本身与 XComponent 无关，可以原样保留；真正的缺口在「谁来给输入和画面兜底」。**

现状（`labs/ohos_cjgui_app`，经源码核对）：

- 系统 IME 走 **ArkTS 隐形 `TextInput` 代理**（`entry/src/main/ets/pages/Index.ets` 的 `proxyTextInput`，
  `opacity(0.01)`、几何/初值来自 owner 快照、身份由 `cjgui-text-proxy.ets` 的 `CjguiProxyKey`
  （appInstance+sessionToken+contextId+editGeneration+mountGeneration）守卫生效），
  聚焦后必须显式 `inputMethod.getController().showTextInput()` 才会真正挂上输入法会话。
- 原生 C-API 路（`OH_TextEditorProxy_*` + `OH_InputMethodController_Attach`）在
  `platforms/ohos/host/ohos_renderer.cpp:imeAttach()` 里写全了但**零调用点**（死代码）；
  而且 HAP 里打包的手搓 `libohinputmethod.so` 是**裸 `ret` 桩**，会遮蔽系统实现 ——
  与历史上 `libnative_window.so` 占位库遮蔽系统实现是**同一类坑**，将来要用原生 IME 必须先删这个桩。

去掉 XComponent 后**不受影响**（代理不依赖它）：
代理挂载由 owner 的 focus/reconcile/end 载荷驱动（TSFN → `registerFocusRequest`），几何来自
`display.getDefaultDisplaySync().densityPixels`，IME 上下文从 renderer 的 `ime_context_json` 拉取 ——
全部在 ArkUI 页面里，XComponent 不在链上。

**必须新接的缺口（按实验实测给出可选法）：**

1. **触摸来源**。原来靠 XComponent 的 `DispatchTouchEvent`（`OH_NativeXComponent_Callback`）。
   去掉后可用**公开** `OH_NativeWindowManager_RegisterTouchEventFilter(windowId, cb)`（本次实测
   `rc=0` 且真实触摸逐笔可读；返回 `false` 放行不影响 ArkUI）或页面级 `.onTouch()`。
2. **按键/键盘**。同理有公开 `RegisterKeyEventFilter(windowId, cb)`（实测 `rc=0`）+
   `OH_Input_GetKeyEvent*`。组合输入（marked range）仍应由代理 + `showTextInput()` 承担，
   不在本实验范围。
3. **窗口底色必须透明**（否则一切自绘都看不见，§4.2）。公开 NDK 一行即可，但要注意：
   透明之后主窗口上**不能**再摆常规不透明 ArkUI 界面，否则又会盖住自绘内容 ——
   这会改变当前「ArkTS 薄壳 + XComponent」里 ArkUI 界面的可用性假设。
4. **surface 生命周期**。XComponent 提供 Created/Changed/Destroyed 三回调；主窗口路线下**没有**公开等价物。
   框架需要把 surface 生命周期绑到 **window/ability 生命周期**上，并用
   `getWindowProperties()` / `on('rotationChange')` 或周期性重读 surface geometry 来发现尺寸变化
   （本次实测：surface 自己的 geometry 才是权威，旋转后必须重读，不能沿用缓存）。
5. **释放语义**。应用侧只能销毁自己包出来的 `OHNativeWindow`；窗口的 `RSSurfaceNode` 归 ArkUI/RS，
   应用侧没有销毁语义，框架不能再把「Surface 释放」当成组件销毁事件。
6. **安全区/沉浸式**：不受影响，继续走公开 window API。

---

## 7. 「进一步去掉 ArkTS」单独报告（不计入本次成功判据）

**没有做过「无 ArkTS HAP」的验证**，以下是本实验拿到的证据与明确标注为未验证的部分。

已实测（`artifacts/run/exp13_noarkts_enum/`，pid 14274，HAP `bbd0c389…`）：

- 在**不知道 windowId** 的前提下，对私有入口 `WindowSessionImpl::GetWindowWithId(id)` 做有界盲扫
  （id 1..16 与 60..140，共 97 个），**恰好命中 1 个窗口**：id=96，即本应用自己的主窗口；
  系统窗口没有泄漏进本进程。命中的窗口再走 vtable→`GetSurfaceNode()` 得到同一个节点。
  → **「谁告诉应用 windowId」这一环在实验上不再是硬阻塞**（虽然盲扫很难算工程方案）。
- 窗口底色透明有公开 NDK 入口（§4.2，已单独归因）。
- 触摸/按键有公开 NDK 入口（§4.3）。

仍然需要 ArkTS 的部分（**推断，未验证**）：

- stage 模型的 Ability 外壳本身（`srcEntry` 指向 ArkTS 能力类）——本次未尝试任何替代。
- ArkUI 页面：隐形 `TextInput` 代理需要它当宿主；若还想保留 ArkUI 界面也需要它。
  若完全不要 ArkUI，代理会消失 → **系统 IME 的组合输入能力需要另找宿主**（这正是 §6 里
  「原生 C-API IME 路」从未真正打通所留下的空缺，且目前被裸 `ret` 桩挡着）。
- 本次没有尝试 nativespawn / 子进程，也不把它当主窗口判据。

---

## 8. 已知边界与未覆盖项

- 只用**模拟器**（emulator 6.1.0.117，API 24 行为）；真机、系统签名、系统应用、CUSTOM_SCREEN_CAPTURE
  等更高权限场景**未测**，结论不覆盖。
- 只做了 CPU 缓冲提交（RequestBuffer/mmap/FlushBuffer）。CJGUI 现网渲染器走的是
  `OH_Drawing` GPU 上下文（`OH_Drawing_SurfaceCreateOnScreen(gpuContext,…,window)`），
  **本实验没有迁移渲染器、也没有验证 OH_Drawing 能挂到主窗口 surface 上**——这是下一步最大的未知。
- 未测：多帧持续刷新（vsync 驱动）、掉帧/合成延迟、buffer 队列深度与背压、
  真机 HWC/GPU 合成路径下自绘 buffer 是否仍可见。
- `SetContainerWindow` 崩溃原因未定位到根因（只记录了崩在函数 +140，近空指针）。
- 未覆盖：marked/cancel 回调、物理设备性能、发布审核。

---

## 9. 下一步建议（按信心排序）

1. **先做隔离 PoC，不要动生产后端**：把 `OH_Drawing_GpuContextCreate + OH_Drawing_SurfaceCreateOnScreen`
   挂到本次拿到的同一个 OHNativeWindow 上，看 GPU 路径能否出图。这决定「去掉 XComponent」是否对 CJGUI 有意义。
2. **同时并行推进「不依赖主窗口」的正式路线**：XComponent 路线当前可用且已经带真机级证据；
   主窗口路线今天只能标私有。若短期要交付，把本实验定位成**技术储备 + 上游诉求材料**。
3. **向上游反馈两条具体诉求**（有本次原文证据，不是空泛请求）：
   - 公开 API 缺一个「返回本应用主窗口 surfaceId / OHNativeWindow」的入口；现有
     `OH_NativeWindow_CreateNativeWindowFromSurfaceId` 已经能完成任务，只差 surfaceId 来源。
   - `OH_NativeWindowManager_Register*EventFilter` 这一组公开接口是去掉 XComponent 后输入的正解，
     建议在文档里显式说明「无 XComponent 主窗口自绘」这一用法，并补 surface 生命周期回调。
4. **若要继续私有探针**：优先补候选 3/4 的复测与 `GetSurface()` 返回类型确认；
   不要再碰 `SetContainerWindow`（已崩）；并给私有链加显式版本断言
   （库 sha256 + 符号存在性 + vtable 槽位校验），任一不符就拒绝启动而不是崩。
5. 与 CJGUI 主线的衔接点（**不在本次范围**）：`RegisterTouchEventFilter` 可以作为
   XComponent 触摸之外的**第二条输入源**独立接入验证；窗口透明/旋转几何重读这两条经验
   可以直接写进 OHOS 后端的设计约束。

---

## 10. 证据索引

日志、截图、崩溃日志、设备身份全部落在 `labs/ohos_main_surface_probe/artifacts/`：

```
artifacts/run/final_evidence/          控制组+三帧+触摸+释放重取（主判据）
  run_identity.txt                     HAP sha256 / pid / 启动参数
  1_control_no_frame.jpeg … 5_after_release_reacquire_blue.jpeg
  hilog_full.txt / hilog_key_events.txt / layout.json
artifacts/run/final_evidence_rebuild/  清空 build 重建后的复核（源码+产物指纹、控制组+两帧）
artifacts/run/exp15_ndk_transparency_only/   纯 NDK 透明归因（arktsTransparency=0）
artifacts/run/exp16_candidates/candidates.txt  4 个候选入口逐个复测结果
artifacts/run/exp11_rotate_fixed/            横竖屏：surface geometry 跟随
artifacts/run/exp12_fgbg/                    前后台：onBackground/onForeground 后继续绘制
artifacts/run/exp13_noarkts_enum/            无 ArkTS 传 id 的窗口枚举
artifacts/run/exp10_rotate/                  反例：缓存尺寸导致 buffer 不跟随旋转
artifacts/run/exp1…exp7                      反例：窗口不透明时提交 rc=0 但画面不变
artifacts/faultlogs/                         6 份 cppcrash + 3 份 jscrash 原文
```

工具版本身份（用于复核）：`devecocli`（DevEco 26.0.0.821）、`hdc`（SDK 26.0.0.105 toolchains）、
`uitest`（镜像自带）、NDK clang/llvm-objdump/llvm-nm（SDK 26.0.0.105）。
