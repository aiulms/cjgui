# Linux 平台接入：选型研究报告

日期：2026-10-17（2026-10-18 修订：补 Vulkan 路线实测，VM 提到 8 核 16 GiB）。
范围：环境核实 + 复用边界核对 + 后端选型 + 最小实验。**本轮不含移植**，不启动 Linux 执行线，不改 E/H/W 写集。
证据均为本机命令与来宾实测；无法核实的项在末尾单列，不写成结论。

## 0. 结论

> 2026-10-18 实施期纠正见 [第 8 节](#8-实施期纠正2026-10-18第一阶段开工后)：本节与第 2、3 节的部分结论已被真实实现推翻或改写（尤其是「兜底只少功能」「以链接器报缺为准」「1/8 入口」三条），第 8 节保留原文、单列差异。

1. **渲染 API：Vulkan 首选（X11/xcb 先行），GL 作为有条件的备选。** 判据不是速度，是覆盖面：Vulkan 的设备/管线/描述符/命令缓冲在 Linux、Android 上完全同一份，只有 WSI 换（xcb → wl_surface → ANativeWindow）。选 GL 等于给 Linux 和 Android 各写一套。**本机 Vulkan 只有 CPU 光栅化（llvmpipe），GL 才有硬件加速（virgl）**——这点必须先说清楚，它是这条路唯一真实的代价。
2. **窗口协议：X11 首选。** 这套环境唯一真实运行的会话是 UKUI + kwin_x11（GDM 已 `WaylandEnable=false`），X11 下没有合成器、直连提交。Wayland 是同一个 Vulkan 后端的第二个 WSI，不是第二套渲染器。
3. **复用方式：共同层不动。** 平台边界就是已有的 C ABI `cjgui_internal_renderer_*`。Linux 需要的是「一个和 Windows 同量级的 host（约 100 行）+ 一个新的 native 实现」。
4. **第一阶段**：让既有普通消费者 `examples/range_text_window_app`（有界文字窗口）在 Linux 上走完「建窗 → 自绘文字与控件 → 键鼠改共同状态 → 外部调用改同一状态 → 人继续 → 正常关闭」。
5. **隐藏成本不在渲染器**：共享层有 16 处 `@When[非 macOS 非 Windows]` 兜底分支会在 Linux 上静默返回空/0（例：`internalRendererSelectionBackgroundVersion` 直接 `return 0u32`）。Linux 落进去不会报错，只会少功能。这是第一阶段最容易「看起来跑通了但实际是残的」的地方。

## 1. 环境实测（先查再判断）

| 项 | 实测 |
| --- | --- |
| 宿主 | macOS 26.6，Apple M5 Pro，arm64；Parallels Desktop；VM 目录 `~/Parallels/openEuler 26.09 DevStation.pvm` |
| 连接 | 共享网络 `10.211.55.0/24`，来宾 `10.211.55.4`，`ssh oeuser@10.211.55.4`（密钥已通，sudo 免密）；Parallels Tools **未安装** |
| 来宾系统 | openEuler 26.09（oe2609），kernel 6.18.48-0.0.0.15.oe2609.aarch64，**aarch64**，**8 vCPU / 16 GiB**（原 4/8，整包构建需此配置），磁盘 62 GiB |
| 桌面会话 | GDM → **UKUI on X11**（`ukui-session` + `kwin_x11` + `Xorg`），`loginctl` Type=x11；启动时停在锁屏 |
| Wayland | `/etc/gdm/custom.conf` 里 `WaylandEnable=false`；`kwin_wayland` **不存在**（只有 ukui-kwin-x11）；`gnome-shell 49.3` + `mutter` 在；无 `wayland-protocols`（xdg-shell.xml 需外取） |
| GPU | `Virtio 1.0 GPU`；`/dev/dri/card0` + `renderD128`；Mesa 25.0.7 |
| GL | `GL_RENDERER = virgl (Apple M5 Pro (Compat))`，GL 4.0 core / GLES 3.0，`Accelerated: yes` → **硬件加速** |
| Vulkan | 唯一设备 = **llvmpipe (LLVM 17.0.6) type=4（CPU）**，api 1.4.305；`virtio_icd`（venus）/`radeon_icd` 均 0 设备 → **无硬件加速** |
| Vulkan WSI | 实例扩展 24 个，含 `VK_KHR_xcb_surface` / `xlib` / **`wayland_surface`** / `VK_EXT_headless_surface`；设备有 `VK_KHR_swapchain`（rev 70）；`libvulkan_lvp.so` 链接 `libwayland-client` → Wayland WSI 已编进 ICD |
| EGL 平台 | GBM / X11 / Surfaceless 均可初始化；**Wayland 平台 `eglInitialize` 失败**（会话里无 compositor） |
| X11 合成 | `_NET_WM_CM_S0` 不存在 → **无合成器**，窗口直接扫描出 |
| 屏幕 | 当前 1032×768 @60Hz，可用模式到 4096×2160（无 HiDPI 模式可测） |
| 图形开发库 | libEGL/libGLESv2/libGL、EGL/GLES 头、libX11、libxcb + 头、xkbcommon(+x11)、libvulkan + 头、wayland-client/egl、libgbm、glslangValidator |
| 文字库 | freetype 2.14.3、harfbuzz 14.3.1、fontconfig 2.18.3（含 devel）；中文可用字族 68 个 |
| 输入法 | fcitx5 各前端包已装，但**进程未运行**，会话无 `XMODIFIERS`/`IM_MODULE` → 中文输入当前不可用 |
| 无障碍 | at-spi2-core 2.60.6 已装，未见消费者 |
| 工具链 | 无 cjc/cjpm；gcc 12.3.1、cmake 4.4.3、ninja、python 3.11.13 |

### 工具链：官方 1.1.3 aarch64 包装上可用，但要两处环境修补

- 包：`cangjie-sdk-linux-aarch64-1.1.3.tar.gz`，395,740,749 B，sha256 `0b0ce42c…c41f`（与官网一致），解压 1.2 GiB。
- `cjc -v` → `Cangjie Compiler: 1.1.3 (cjnative)`，`Target: aarch64-unknown-linux-gnu`；`cjpm 1.1.3`。
- 直接 `cjc hello.cj` 链接失败，两个原因，都可复现：
  1. cjc 把 `crtbeginS.o`/`crtendS.o` 作为**裸文件名**交给 `ld`，而 GNU ld 只对 `-l` 库走搜索路径，裸文件名只按当前目录/显式路径找。把这两个文件放进 `/usr/lib64` 后 cjc 能自己拼出完整路径（`/lib64/crtbeginS.o`）。
  2. `-lgcc` 需要 `--link-options "-L /usr/lib/gcc/aarch64-openEuler-linux/12"`。
- 修好后：`main() { println("你好, 仓颉 Linux") }` 编译运行正常，中文输出正常。
- **整包 `cjgui`（396 文件）在 8 核 16 GiB 下 `cjpm build success`，0 error、404 warnings。** 在 4 核 8 GiB 下同一命令 `rc=9` 且无诊断——**根因是内存/并行度不足，不是工具链缺陷**（见风险 1 修订）。

## 2. 三个关键问题

### 2.1 当前虚拟机实际能运行什么

能跑：aarch64 仓颉 1.1.3 原生编译；X11 窗口 + EGL/GLES 硬件加速提交（virgl）；X11 窗口 + Vulkan **CPU** 提交（llvmpipe，UI 形状探针已跑通）；嵌套 Wayland 合成器（mutter --nested）；GBM/surfaceless 离屏；fontconfig/harfbuzz/freetype 全栈。
不能跑（本环境下）：GPU Vulkan；**Wayland 桌面会话**（kwin_wayland 不存在，只能起嵌套合成器）；中文输入（fcitx5 未启动）；真实 HiDPI。

区分三件事，本轮只做到第一层：
- **源码存在**：库、头文件、desktop 文件都在。
- **本机可运行**：`cjc` 编译 + 图形初始化 + 帧提交成功（有实测输出）。
- **物理显示**：**未验**。所有图形实验都是在「已登录但锁屏」的会话里完成的，窗口确实创建并提交了帧，但没有人眼看到画面的证据。第一阶段第一步就是解锁后看到窗口。

### 2.2 哪些现有机制能直接复用

| 层 | 现状 | Linux 处置 |
| --- | --- | --- |
| `shared_operation_core`（31 个 .cj，owner/正文/版本/传输/生成式契约） | **在本机 Linux 上 `cjpm build success`，0 error** | 直接复用，不改 |
| `CjguiApplicationHost` 接口（window/start/pumpOneTurn/isOpen/close） | 5 个方法，消费者只依赖它 | 新增 Linux 实现即可 |
| `CjguiComposableUiWindow`（约 2.4 万行：组件、布局、场景、选择、输入交接） | 共同层 | 不动；平台差异只在 native |
| `windows_application_host.cj` | **77 行**（HWND/消息循环/D3D 全在 native） | Linux host 照此写，预计 100 行上下 |
| `platform_adapter.cj`（254 行） | **历史 stop-line 骨架**，注释明确「不实现 platform adapter」 | 不要当接缝用，也不要在它上面加 Linux 分支 |
| 平台 native | macOS `native/*.m`（Metal）、Windows `platforms/windows/native/*.c`（D3D11，18,275 行）、OHOS `platforms/ohos/host/*.cpp`（OH_Drawing，16.8k 行） | 三套都是完整场景→GPU 编码器，各自实现同一套 `cjgui_internal_renderer_*` 名字；**全仓 native 源码里 EGL 引用 0 处、Vulkan 引用 0 处**，Linux 会是第一个 Vulkan 后端 |

**平台边界是 C ABI，不是文件名。** 头文件 `native/cjgui_internal_renderer.h` 3,294 行，**348 个不重复符号**；仓颉侧去重后 269 个入口。按能力粗分：scene/composable 69、text 73、window/lifecycle 23、present/frame 16、input 12、test/diag 18、其余 57。

**每个后端只实现自己 `@When` 分支引用到的子集**，实测各平台在各自 native 源码里出现的入口数：macOS `.m` 403（含超出当前头文件的历史名字）、Windows `.c` **146**、OHOS `.cpp` **69**。所以 Linux 不要想着一次补齐 269 个——**起步集合以链接器报缺为准**。

**必须调整的现有耦合（这是真正的工作量，不是补个 adapter）：**

- `@When` 分布（`runtime/cjgui/src`，共 383 处）：`os == "macOS"` 174、`os != "macOS"` 101、`os == "Windows"` 39、`macOS || Windows` 28、`os != "Windows"` 25、`os != macOS && != Windows` 16。其中 76 处 `os != "macOS"` 集中在 `runtime_renderer_session.cj`。
- **两台机器上的实际后果**：Linux 没有自己的分支，会同时落进「非 macOS」（实为 Windows 写）和「既非 macOS 也非 Windows」（实为 OHOS 写）两类分支。后者**不会报错**，直接返回空值，例如：
  - `internalRendererSelectionBackgroundVersion()` → `return 0u32`（选区背景版本恒 0）
  - `internalRendererConsumedPointerFifo()` → 返回全 0 的 FIFO（指针 FIFO 永远空）
  - 消费方 `range_text_window_app/src/main.cj:1161` 的 `rangeTextPreviewSelectionRuns` → 返回空数组（**选区底色不画**）
- 所以第一阶段有一项**必须做的事**：把平台条件从「非此即彼」改成显式平台判断（macOS / Windows / Linux / OHOS），逐处确认落点。这条比渲染器更容易漏，且漏了不报错。

**确实要新写的窄接口**（都在 native 侧，不新增仓颉 owner）：
- 窗口与 surface 生命周期（X11 window、Vulkan surface/swapchain、ConfigureNotify）
- 事件泵与阻塞等待（`pump_event` / `owner_wait_work`）
- 文字测量与整形（`measure_composable_text` 收的是**原始 UTF-8 + fontSize/fontWeight/fontFamily 枚举 + maxWidth**，回测量值 → 整形在 native，共同层不做）
- 场景→Vulkan 编码（render pass / pipeline / descriptor / 字形图集 / 增量上传）
- 关闭/退出握手（`request_application_stop` / `complete_application_exit_request`）

### 2.3 首个后端怎么选

**先给实测，再说结论。** 两组探针是同一个 UI 形状：1000×700 窗口、1024² RGBA 图集、每帧 N 个带纹理 quad、每帧末尾做一次 X 服务端同步（XSync / xcb round-trip），这样「提交」和「服务端收下」都算进成本。

| draws/帧 | GL（EGL+GLES3，**virgl 硬件**） | Vulkan（xcb，**llvmpipe CPU**） |
| --- | --- | --- |
| 50 | 0.26 ms | 1.13 ms |
| 200 | 0.34 ms | 1.10 ms |
| 800 | 0.77 ms | 2.12 ms |
| 2000 | 1.71 ms | 3.02 ms |
| 200 + 每帧整张 1024² 上传 | 1.99 ms（+1.65） | 1.43 ms（**+0.33**） |
| 冷启动（建窗→首帧可绘） | ≈110 ms | ≈50 ms |
| 峰值 RSS（2000 draws） | 66.7 MB | 94.7 MB |
| present 模式 | — | X11 支持 IMMEDIATE；**Wayland 只有 MAILBOX/FIFO，没有 IMMEDIATE** |

**怎么读这张表：**
- 这**不是同驱动对比**：GL 走 virgl（GPU），Vulkan 走 llvmpipe（CPU 光栅化）。Vulkan 用纯 CPU 只比 GPU 的 GL 慢约 1.8 倍，2000 draws 也才 3 ms（相当于 330 fps），**说明「没有 GPU 也能拿 Vulkan 做 UI」这件事成立**，这是选型上最关键的一条。
- 图集上传 Vulkan 便宜 5 倍（0.33 ms vs 1.65 ms）。文字 UI 的图集是增量更新的，这条对 CJGUI 有利。
- 冷启动 Vulkan 更快（≈50 ms vs ≈110 ms），管线创建在 llvmpipe 上不贵。
- 内存 Vulkan 多约 28 MB，全是驱动/设备基线，不随场景增长。
- **FIFO 与 IMMEDIATE 在这台机器上没有区别**（都无 16.7 ms 台阶），因为 X11 没有合成器、没有 vblank 节流。**本机测不出 present 节流成本**，这条不算结论。

**渲染 API 选择**

| | Vulkan（**首选**） | OpenGL EGL/GLES3（备选） |
| --- | --- | --- |
| 覆盖 Linux + Android | 设备/管线/描述符/命令缓冲同一份，只换 WSI | 也是同一份 GLES，但 GLES 已是死胡同 API |
| 本机加速 | **无（CPU 光栅化）** | 有（virgl） |
| 本机可用性 | 已跑通完整 UI 形状（含纹理、push constant、present） | 已跑通 |
| 图集上传 | +0.33 ms/1024² | +1.65 ms/1024² |
| 代码量 | 大：描述符、管线、显式同步、swapchain 生命周期 | 小：隐式同步，swap 即提交 |
| 帧节拍 | 自己管（已有 turn/scheduler） | 同 |
| 风险 | 驱动差异要自己兜（present 模式、surface 尺寸未定义） | 驱动差异由 EGL 兜一部分 |

**结论：Vulkan 首选，理由是可复用面而不是速度。** 本机 Vulkan 无硬件加速是事实，但 3 ms/帧（2000 draws）够用；把 GL 当首选等于给 Linux 和 Android 各写一套渲染器，而 Android 那边最终大概率还是要回到 Vulkan。

**GL 的启用条件（写清楚，不是「以后再说」）**：同时满足两条才回头做 GL 后端——(a) 目标机器上 `vulkaninfo` 枚举不到任何 ICD（老 Intel iGPU 这类只有 GL 的机器），(b) 第一阶段验收明确要求在 virgl 那种硬件路径上跑出流畅感。**不同时开发两套。**

**窗口协议**

| | X11（首选） | Wayland（同后端的第二个 WSI） |
| --- | --- | --- |
| 本机可用性 | 就是当前会话，立刻能跑 | `kwin_wayland` 不存在；只能 `mutter --nested` 起嵌套合成器（已实测可起，`wayland-0`） |
| Vulkan 面 | `VK_KHR_xcb_surface`，实测建 surface + swapchain + 出图 | `VK_KHR_wayland_surface` 存在，**实测只推进到建 swapchain**，present 在嵌套软件合成器里 acquire 超时 |
| 呈现 | 无合成器，直接扫描出 | 合成器必过一手，帧回调可做节流 |
| 输入 | Xlib 事件 + XIM（libX11 自带） | wl_seat + xkbcommon，IME 走 text-input-v3 |
| 缩放/DPI | 整数字阶，分数缩放差 | 原生 fractional-scale |
| 覆盖范围 | 同一二进制经 XWayland 跑在 Wayland 桌面 | 只覆盖 Wayland 桌面 |

选 X11 是证据不是偏好：唯一能立刻验证的会话；无合成器让首帧成本最低；XWayland 让第一个后端不至于在 Wayland 桌面上完全不可用。

## 3. 性能与系统能力：落到具体设计

### 3.1 事件循环、按需唤醒、呈现

- native 持有一个 `poll()` 循环，监听四路：X11 连接 fd（`ConnectionNumber`）、自唤醒 pipe/eventfd（Agent 或外部线程投递时写一个字节）、timerfd（光标闪烁、动画 deadline）、Vulkan swapchain 的 present 完成（用 fence fd 或提交后轮询）。
- `owner_wait_work` 就是阻塞点：无输入、无 timer、无外部唤醒时一直阻塞，**不产生帧**。醒来后只做「取事件 → 入队」，绘制由共同层失效驱动，不在 native 里做「空闲也重绘」。
- 输入到呈现不做同步等待：X11 事件自带坐标，不需要 round-trip；指针位置、按键顺序按既有 `inputSequence` 契约入队。
- **本机实测：两种 API 都没有 vblank 节流。** `eglSwapInterval` 0/1 都是 0.28–3.2 ms 无台阶；Vulkan 的 FIFO 与 IMMEDIATE 同样无差别（无合成器）。结论：**帧节奏必须自己管**（CJGUI 已有 turn/scheduler），不能指望 present 限速，也不能用「present 阻塞时长」当性能指标。
- Vulkan 侧要在途帧数固定（探针用 2），用 fence 复用命令缓冲；不 `vkDeviceWaitIdle` 做日常同步。

### 3.2 布局、整形、字形纹理、选择装饰

- 布局、选择、装饰、命中都在共同层，Linux 不重做；native 只回测量值和字形位图。
- 整形：Fontconfig 选族与回退链 → HarfBuzz 出 glyph/advance/cluster → FreeType 出位图 → 图集。**只在文本或字号变化时整形**，命中测试用已缓存的 run，不重排。
- 图集：1024² RGBA 页 + 槽位分配，字形按 (face, size, glyphId) 缓存；换 DPI 时按新尺寸分页，不整体重建。Vulkan 侧用持久映射的 staging buffer + `vkCmdCopyBufferToImage`（实测 +0.33 ms/整页），比 GL 的 `glTexSubImage2D` 便宜。
- **draw 成本**：Vulkan 边际约 **1.07 µs/draw**（200→2000 增 1.92 ms），GL 约 **0.76 µs/draw**。UI 一帧 2000 draw 约 2–3 ms。批处理（同材质合批、push constant 换 transform）要做，但不是致命项。
- 文字这条路**没有捷径**：C ABI 收的是原始 UTF-8，整形必须在 Linux 本地做。HarfBuzz/FreeType/Fontconfig 不是「可研究项」，是第一阶段必需依赖（三者在目标机已是系统库）。

### 3.3 GPU 在途资源、缩放、DPI、关闭

- 在途：present 之后不立即复用该帧引用的纹理/缓冲；两帧环形 + 显式 retired 队列，靠 fence 判断可回收。不用 `vkDeviceWaitIdle` 做日常同步。
- 缩放：**已实测可走通**。ConfigureNotify → 销毁 framebuffer/imageView → 以 `oldSwapchain` 重建 → 销毁旧链，**destroy+rebuild 0.45–0.70 ms**（llvmpipe，1280×900 请求被屏幕宽度钳到 1032×682）。图集与字形缓存不动。
  **坑**：`xcb_configure_window` 之后立刻查 `vkGetPhysicalDeviceSurfaceCapabilitiesKHR` 拿到的是**旧尺寸**；必须先排空事件队列并等 WM 生效，surface extent 才会跟上。第一阶段的事件泵必须把 ConfigureNotify 当成「重建条件」，不能每次醒来都查 caps。
- DPI：X11 没有可靠分数缩放。第一阶段只支持整数倍（1x/2x），从 `Xft.dpi` / `GDK_SCALE` / 物理尺寸推导，作为一个值交给既有 scale 通道；分数缩放留到 Wayland WSI。
- 关闭：WM_DELETE_WINDOW → 请求停止 → 共同层走完 `complete_application_exit_request` → native 释放顺序固定为「停止提交 → `vkDeviceWaitIdle` → 销毁 swapchain/图像视图 → 销毁管线/描述符/图集 → 销毁 device → 销毁 surface/instance → 关闭 X 连接」。任何一步失败都要能报告，不能静默吞。

### 3.4 系统 IME、剪贴板、字体回退、无障碍

- **IME 不自研**。X11 第一条路径用 libX11 的 XIM（`XOpenIM`/`XCreateIC`/`XFilterEvent`）：组合态、提交、候选窗口位置交给系统；框架只把 preedit/commit 映射到既有 `compositionPhase` / `marked*` 字段。已知代价：XIM 是阻塞式 API，需要与 poll 循环协调（`XNextEvent` + `XPending`，不要在多线程里碰同一个 Display）。
- 现状：fcitx5 已装但**没运行**，中文输入在本机当前不可用。第一阶段验收先用 ASCII 直输，中文 IME 作为第二阶段独立门。
- 剪贴板：X11 selection（`CLIPBOARD`/`PRIMARY`）在 native 实现，事件进共同层的同一操作入口；不做「只在 Linux 有的一套剪贴板状态」。
- 字体回退：Fontconfig 给回退链，HarfBuzz 逐 cluster 判断缺字并换族；缺字要有可见的 fallback 记录，不静默画豆腐块。
- 无障碍：AT-SPI2 走 D-Bus，属于后续阶段。现有 ABI 没有独立 AX 入口，语义靠 `prepare_composable_node` 的 `semanticId`/`semanticLabel` 带过去——Linux 的 AX 桥要接在这条既有通道上，不另造语义树。

## 4. 第一阶段：范围与可见成果

**目标消费者**：`runtime/cjgui/examples/range_text_window_app`（既有普通消费者，不移植 Pharos）。
**可见成果（一条链，缺一不算过）**：
建窗 → 共同组件自绘文字与控件 → 键盘/鼠标修改共同状态 → 外部客户端调用操作同一状态 → 人继续操作 → 正常关闭退出码 0。

**本阶段要实现**
1. `src/linux_application_host.cj`（约 100 行，对照 Windows host）+ `application_host.cj` 增加 `@When[os == "Linux"]` 与 `cjguiStopApplicationLoop`。
2. `platforms/linux/native/`：X11 窗口、Vulkan instance/device/swapchain、render pass、管线、场景提交、事件泵与阻塞等待、关闭握手。
3. 文字：Fontconfig + HarfBuzz + FreeType，`measure_composable_text` 与多行自然高度，字形图集与增量上传。
4. 输入：键盘（xkbcommon 映射）、指针、滚轮、焦点；ASCII 直输。
5. **平台条件审计**：把 16 处 `非 macOS 非 Windows` 兜底与 101 处 `os != "macOS"` 逐处确认落点，把 Linux 需要的改成显式三值。至少覆盖选区背景版本、指针 FIFO、预览选区这三条（消费方会直接受影响）。
6. 构建：`platforms/linux/native` 一份 CMakeLists（照 OHOS 写法），cjpm 链接 `-lvulkan -lxcb -lfreetype -lharfbuzz -lfontconfig`。

**本阶段明确不做**
Pharos 移植、中文 IME、Wayland WSI、GL 后端、分数缩放、无障碍、图片之外的资源类型、GPU 计时埋点、生成式界面的 Linux 验收。

**起步 ABI 集合（按能力，不按符号逐条锁死；实施以消费者真实调用为准）**
lifecycle 8 个左右（create/destroy/title/background/stop/exit）、present 8 个（present_clear/configure_scene/set_node/set_geometry/discard/acknowledge/display_progress）、preparation 5 个、text 6 个（measure/measure_multiline/set_runs/line_rect）、input 4 个（pump_event/wait_work/has_unconsumed_input/pointer_geometry）。约占 269 个入口的 1/8，其余（owner handoff、data transfer、installed range、右键菜单、IME 组合）按消费者推进补。**以链接器报缺为准，不靠读代码猜。**

## 5. 未确认的风险

1. ~~整包在 Linux 上编不过~~ → **已定位并解除**：4 核 8 GiB 下 `cjpm build` `rc=9` 无诊断，是因为构建内存/并行度不足（同轮还导致 VM 失联）。提到 **8 核 16 GiB** 后 `cjpm build success`，0 error、404 warnings。工具链无缺陷。
2. **Vulkan 本机无硬件加速**。所有 Vulkan 数字都是 llvmpipe CPU 光栅化，不能推及有 GPU 的实体机；反过来，实体机上的 Vulkan 只会更快，这条方向的误判风险低。
3. **present 节流成本未测**。无合成器 → FIFO 与 IMMEDIATE 无差别，测不出 vsync 相关成本。
4. ~~窗口缩放未测~~ → **已实测**：Vulkan 重建交换链可用，destroy+rebuild **0.45–0.70 ms**。附带一个坑记在 3.3：不排空事件队列时查到的 surface 尺寸是旧的。
5. **Wayland 只验到建 swapchain**。`mutter --nested` 里 present 的 acquire 超时（软件合成器），Wayland 下的出图、帧回调、IME v3 全未验。
6. **virgl/llvmpipe 只代表这台 VM**。帧数字是 Apple M5 Pro 经 Parallels 的结果。
7. **画面未做人眼验收**。锁屏会话里提交成功 ≠ 屏幕上看得见。
8. **中文输入未验证**，fcitx5 未运行；XIM 在各前端上的行为差异没测。
9. **DPR/HiDPI 未验证**，屏幕只有 1032×768。
10. **Parallels Tools 未装**：宿主↔来宾剪贴板共享、动态分辨率不可用。
11. **只测了一个桌面**（UKUI）。GNOME/KDE 的 X11 行为、合成器开启时的呈现成本都未测。

## 6. 实验记录与空间账

| 实验 | 命令/产物 | 结论 |
| --- | --- | --- |
| 环境采集 | `ssh oeuser@10.211.55.4`（密钥） | 见第 1 节表 |
| Vulkan 设备/扩展 | `/tmp/cjlinux/vkext.c` | 1 设备 llvmpipe；WSI 有 xcb/xlib/wayland/headless |
| Vulkan UI 探针 | `/tmp/cjlinux/vkui.c`（xcb + swapchain + 纹理 + push constant + N draws） | 200 draws 1.10 ms、2000 draws 3.02 ms；上传 +0.33 ms；冷启动 ≈50 ms；峰值 RSS 94.7 MB |
| Vulkan WSI 变体 | `/tmp/cjlinux/vkwl.c` + `xdg-shell`（外取 XML 生成） | 嵌套 mutter 下建 surface/swapchain 成功（formats=8、present modes=MAILBOX/FIFO），present acquire 超时 |
| Vulkan 缩放 | `/tmp/cjlinux/vkresize.c`（xcb configure 1000×682→1280×900 被钳到 1032×682） | destroy+rebuild **0.45–0.70 ms**；不排空事件时 caps 返回旧尺寸 |
| GL 对照 | `/tmp/cjlinux/eglprobe.c`（X11+EGL+GLES3，带 XSync） | 200 draws 0.34 ms、2000 draws 1.71 ms；上传 +1.65 ms；冷启动 ≈110 ms；峰值 RSS 66.7 MB |
| 数字修正 | 上轮 GL 的 1.17/1.98 ms 是 4 核满负载构建时采的 | 安静环境重测快 3 倍，**旧数字作废** |
| FIFO vs IMMEDIATE | `vkui N 60 0/1` | 无差别（无合成器），测不出 vsync |
| 嵌套合成器 | `mutter --nested --wayland` | 可起，产出 `wayland-0`；`kwin_wayland` 不存在 |
| 工具链 | SDK + sha256 + `cjc -v` + hello | 1.1.3 aarch64 可用，需两处修补 |
| FFI | `probe.c` + `ffi.cj` | `probe_add=42`；进程内 EGL 1.5 初始化成功 |
| 共同核心 | `cjpm build`（31 文件） | **success，0 error** |
| 框架整包 | `cjpm build -j8`（396 文件，8 核 16 GiB） | **success，0 error，404 warnings** |

**空间**：来宾新增 SDK 解压 1.2 GiB + 安装包 396 MiB + 构建目录约 400 MiB，磁盘 48→46 GiB 可用。实验源码在 `/tmp`（宿主 `/tmp/cjlinux`），未拷回仓库。E/H/W 写集未触碰，无 stage/commit/push。

## 8. 实施期纠正（2026-10-18，第一阶段开工后）

本节**不改上面任何原始记录**：第 0–7 节的数字与结论保持当时原文，供复算与追溯。下面只写开工后
用真实实现与正确构建闭包测出来、与原文**结论不同**的部分，以及原文里已被证实不成立的判据。
所有新数字仍来自同一台来宾（openEuler 26.09 aarch64，UKUI/X11，Vulkan 仅 llvmpipe CPU 光栅化）。

### 8.1 跨平台复用结论的纠正

1. **「Linux 落进兜底分支只会少功能」不成立——其中两条是硬失败。**
   - `internalRendererSelectionBackgroundVersion()` 落 `return 0u32`：`composable_ui_window.cj:9321-9329` 在
     场景含选区背景而版本不是 1 或 2 时，会 `rejectParticipantCandidate(..., "selection_background_backend_unsupported")`
     **拒绝整个候选场景**。这不是"选区背景版本恒 0 少画一层"，是**窗口起不来**。Linux 必须返回 1（与 Windows 同；
     macOS 返回 2 表示平台自绘）。
   - `internalRendererComposableDisplayValue` 落 `os != "Windows"`（即 macOS 支）：`preserve=true` 时把发给
     native 的正文替换成**空串**。`preserve=true` 在「焦点文本框 + owner 版本未变」时成立，也就是**打字/聚焦的常态**。
     Linux 侧同样是自绘正文、没有 AppKit text proxy，表现是**焦点文本框空白**。
   所以第一阶段的正确说法是：**16 处兜底里至少 2 处会让主验收链直接失败，不是"看起来跑通但残"**。

2. **「起步集合以链接器报缺为准」必须加上前提：闭包要先对。**
   实测：把整目录 `src/`（481 个 `.cj`）编成静态库，链接期要求 **113 个 `cjgui_internal_renderer_*` + 262 个
   `cjgui_native_bridge_*`（macOS Metal 桥）= 375 个** native 符号；换成真实消费者闭包
   （`native/scripts/lib_cjgui_source_set.sh` 的命名集合）后只要 **123 个**。差别全部来自"把只该给 macOS 编的
   文件也编进来了"。而且该命名集合当时**已滞后于工作区**（缺 8 个文件，缺了直接编译报 undeclared type），
   本次已就地补齐并在集合里注明依据。
   结论：**链接器只能报"符号缺失"，报不出"分支落错"；两者必须一起用，且闭包必须先用编译器核准。**

3. **「起步 ABI 约占 269 个入口的 1/8（约 35 个）」偏小约 3.5 倍。**
   正确闭包下的实测需求是 **123 个**：113 个 `cjgui_internal_renderer_*` + 5 个 macOS 平台查询
   （`cjgui_macos_{control_accent_srgb8,effective_dark_mode,reduce_motion_enabled,window_minimized,window_visible}`）
   + 5 个异步测量桥（`cjgui_async_composable_{multiline,text_metrics}_begin`、`CjguiAsyncMultilineMeasurePoll/Release`、
   `CjguiAsyncTextMetricsPoll`）。后 10 个在第一阶段是**必须**的：它们在闭包里没有被 `@When` 挡住。

4. 原文 2.2 节说 `platform_adapter.cj` 是历史 stop-line 骨架、不要当接缝用——**本次遵守**：Linux 走的是
   `CjguiApplicationHost` 五方法 + native `cjgui_internal_renderer_*`，没有碰 `platform_adapter.cj`。

### 8.2 性能结论的纠正

5. **探针的 draw 成本与正式实现的 draw 成本不是同一个量。** 探针每帧末尾做一次 X 服务端同步
   （XSync / xcb round-trip），把 X11 IPC 往返算进了"帧成本"；正式实现里成本几乎全部落在 **present（驱动侧执行）**。
   正式实现实测（640×400，MAILBOX，llvmpipe，1200 帧）：
   - 2000 次 `draw_triangles`/帧、每次 6 顶点、**实心与文字交替（2000 条未合并区间）**：帧均 **6.43 ms**
     （p50 6.06 / p99 12.22），其中 **present 6.18 ms**、`vkCmdDraw` 记录 0.19 ms、**API 层合计 0.025 ms**。
   - 同样 2000 次调用、但同状态连续（合并成 1 次 `vkCmdDraw`）：帧均 **0.84 ms**。
   - 同样 12000 顶点/帧、200 次调用：帧均 1.19 ms。
   所以边际成本应记为 **≈2.8 µs/draw（llvmpipe）**，且它落在驱动侧而不是 API 层；原文 §3.2 的
   "1.07 µs/draw（Vulkan）/ 0.76 µs/draw（GL）"是探针形状下的数字，不能当"UI 一帧 2000 draw 的成本"。

6. **合批的收益被原文低估了一个量级。** 原文写"批处理要做，但不是致命项"；实测同状态合批把
   2000 次调用从 6.43 ms 压到 0.84 ms（**7.7×**）。这应当作为会话层的设计约束
   （按纹理状态批量发出，不要让实心几何与字形交替逐条下发），而不只是"优化项"。

7. **"Vulkan 只比 GL 慢约 1.8 倍"不能当选型依据。** 两者驱动不同（virgl GPU vs llvmpipe CPU），
   且都在探针那个带 round-trip 的形状里测。它只能说明"同形状下 CPU 光栅化慢不到 2 倍"。
   选型理由仍是原文那条——**覆盖面（Linux/Android 同一份设备/管线/描述符/命令缓冲，只换 WSI）**，
   结论不变，但依据要换成覆盖面而不是这张表。

8. **内存判据要换。** "present 前后 RSS 单点对比 < 8 MiB"在重载下**会误报**：首跑 RSS +69 MB 像泄漏，
   追下去是驱动 pool 预热 + 两级锯齿（`heap_inuse` 在 121↔137 MB 间跳、1200 帧无单调增长、fd 恒 8、
   Vulkan 对象创建数恒定）。可靠信号是 **窗口最小值趋势 + 对象创建计数 + `heap_inuse`**。
   实测插桩：1321 帧里 `vertex_buffer_creates=2`（两个在途 slot 各一次），1200 帧 tail 窗口最小值比 head 低 0.8 MB。
   原文"峰值 RSS 66.7 MB（GL）/ 94.7 MB（Vulkan）"是探针的，不能当实现占用。

9. **原文的免责在正式实现里同样成立，且必须继续带着走**：FIFO 与 IMMEDIATE 在这台机器上无差别
   （X11 无合成器）→ **测不出 present 节流成本**；所有数字是 **llvmpipe CPU 光栅化**，不代表硬件性能；
   "画面未做人眼验收"这条在第一阶段实施里必须真正解决，不能沿用。原文的冷启动（≈50 ms）与图集上传
   （+0.33 ms/1024²）**本轮没有在正式实现里复测**，保留为未复核数字。

10. **验证层不是可选项。** 正式 Vulkan 后端在 `VK_LAYER_KHRONOS_validation` 下首跑即抓到 1 个真缺陷
    （图集首次上传 barrier 写 `oldLayout=SHADER_READ_ONLY` 而图像实际仍是 `UNDEFINED`）。探针阶段没有层，
    这类缺陷不会暴露。第一阶段把 validation 纳入自测入口。

## 7. 待决定

- 是否按「X11 + Vulkan」开工第一实施阶段（本报告推荐）。
- 第一阶段验收里，中文输入是否必须（当前判断：放第二阶段，但会改变「既有消费者贯通」的成色，需要明确）。
- 第一阶段的「可见」标准：只要窗口能看见字，还是要求 60 fps 稳定（llvmpipe 下有实测余量，但真实编辑器场景没测）。
