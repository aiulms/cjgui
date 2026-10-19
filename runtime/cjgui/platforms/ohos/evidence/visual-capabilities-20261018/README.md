# 跨平台视觉能力收口（2026-10-19）

本页保留 2026-10-18/19 的 OHOS 真机、macOS 窗口与 Linux 来宾探针，并记录 2026-10-19 收口轮：
统一 effectGroup 计数、补齐 OHOS translate 命中/文字/滚动与 tint 乘色、修正 macOS 效果缓存与
输出范围、留下可运行普通消费入口、补 Windows 当前主树编译检查。

证据分三层，不混写：**实现**（源码存在）、**编译**（构建或语法检查通过）、**正常消费**
（真实点击、状态读回、窗口像素）。本轮新增消费证据见
[ordinary-consumer-20261019](ordinary-consumer-20261019/)。

OHOS 最初一轮的目的：证明 fork 样式模型新增的 `translateX/Y`、`scaleX/Y` 能穿过布局、场景快照、
`CjguiInternalRendererComposableGeometry` staging 与 `ohos_renderer.cpp`，在真实 Pharos PDF
应用中按约定语义绘制。此前通道已用 identity 值探针证明，该轮的差异是**应用层真实取值**。

## 构建身份

- 编译源：`cjgui-pdf/entry/pdf_application/src/pdf_controller.cj`（HAP 的 `libcjgui_pdf_application.so`）
- 框架：`entry/cjgui/src/` 与 `snapshot/src/` 五个文件逐一相同；头文件相同
- HAP：干净版 61,756,989 B；探针版 61,752,861 B
- 探针补丁（仅本轮截图用，已还原）：
  - hero 卡片：`translateX: 24.0, scaleX: 0.85, scaleY: 0.85`
  - hero 标题：`scaleX: 0.7, scaleY: 0.7`
- 还原后 `entry/pdf_application/src/pdf_controller.cj` SHA256 =
  `861c670ee2d1fdaee1a8cffebf9372683119163a5616aa6cb68947bd2637babc`（与探针前原件一致）

## 行为约定

- 平移按祖先累计，子节点继承；缩放仅作用于本节点绘制，子节点不继承。
- 缩放绕节点自身布局盒中心；布局与命中矩形不变。

## 像素量测（1320×2856，density 3.5）

| 对象 | 基线 | 探针 | 结论 |
| --- | --- | --- | --- |
| hero 卡片左边（中心行 y=266） | 41 px | 217 px | 预测 41 + 24×3.5 + 0.15×(659.5−41) = 217.8，实测 217 |
| 黑色按钮左沿 | 718 px | 802 px | +84 px = 24×3.5，精确；按钮高 126 px 两侧相同（36×3.5） |
| 标题墨迹 bbox | 364×57 px | 255×40 px | 比率 0.7005 / 0.7018，与 0.7 一致 |
| 标题墨迹中心 y | 260 | 260.5 | 纵向中心不变（绕自身中心） |
| 副标题（子节点） | 未缩放 | 右移 84 px | 只继承平移，不继承缩放 |

`hero-baseline.png` / `hero-probe.png` 为卡片区域对照裁图。

## 还原核验

`ohos-restored.jpeg` 与 `ohos-baseline.jpeg` 在状态栏以下 3,585,120 像素上：
均值差 0.0、最大差 0、差值 >20 的像素 0。探针是唯一差异源，还原为逐像素一致。

构建日志：
- `framework-build-initial-failure.log`：fork 缺 `subtreeNodeCount`，编译失败 EXIT=255
- `framework-build-success.log`：补齐后 BUILD SUCCESSFUL，EXIT=0
- `probe-build.log` / `restore-build.log`：探针与还原两次 HAP 构建，均 EXIT=0

## effectGroup / backdrop 数据路径（2026-10-19）

fork 样式模型新增 `CjguiComposableUiEffectGroup`（opacity、blendMode、backdrop 半径/回退），
两条 staging 路径（`syncProjection` 正常刷新、`stageComposableSceneNode` 交互重绘）写入 ABI 字段。
线性 alpha mask 未接通，模型不暴露。

**2026-10-19 收口修正：** 权威 ABI 的 `effectGroupSubtreeCount` 包含组自身。此前 OHOS staging
写 `subtreeNodeCount − 1`、host 按 `[index+1, index+1+count)` 消费，两处自洽但违反 ABI。
现在 staging 写 `UInt32(node.subtreeNodeCount)`（snapshot `composable_ui_window.cj:4210/5778`），
host 取 `[index, index+count)`（`ohos_renderer.cpp:6307-6308`），并用
`OH_Drawing_CanvasSaveLayer` 把整段画进一层；单节点组 `count=1` 同样应用 opacity，
嵌套组与组后兄弟不被吞入。macOS 的同一区间也按含组自身消费
（`cjgui_internal_renderer.m:15908/15966`）。

下方像素表来自修正前的配套探针（staging/host 两端同为旧约定），它证明的是
**整组隔离合成而非逐节点 alpha**；新计数尚未在真机重跑，不能把旧图像当作新约定的通过证明。

探针：hero 卡片 `effectGroup(opacity: 0.45)`。

| 像素 | 基线 | 探针 | 组合成预测 |
| --- | --- | --- | --- |
| hero 卡背景 | (251,251,253) | (248,248,250) | 0.45×251 + 0.55×245 = 247.7 |
| 打开文件按钮 | (18,18,20) | (142,142,144) | 0.45×18 + 0.55×245 = 142.85 |
| 最近阅读卡（同级） | (251,251,251) | (251,251,251) | 不受影响 |
| 页面背景 | (245,245,247) | (245,245,247) | 不受影响 |

按钮值落在组合成预测上而非逐节点二次混合（约 145），说明子树被单层隔离合成。
第一版只接了交互路径，探针零差异；补上 `syncProjection` 正常路径后生效。
还原后干净 HAP 截图与基线在状态栏以下逐像素一致（均值 0.0、最大差 0）。

`ohos-effectgroup-probe.jpeg` / `hero-effectgroup.png` / `ohos-effectgroup-restored.jpeg`；
日志 `effectgroup-build-noop.log`（首版无效果）、`effectgroup-build-success.log`、
`effectgroup-restore-build.log`。

## OHOS backdrop on-path（2026-10-19）

探针：`buildHome` 在工具网格后追加 340×90（逻辑）半透明白卡，
`effectGroup(opacity: 1.0, backdropBlurRadiusPoints: 12)`，`translateY: -170`，
使卡片覆盖已绘制的工具网格。探针节点占用 90 逻辑高度，首页固定预算被压缩，
截图中最近阅读/搜索行出现挤压——这是探针插入节点的布局副作用，不是 backdrop 路径。
离线还原后该扰动消失。

| 量测 | 基线 | 探针 | 结论 |
| --- | --- | --- | --- |
| 卡片下图标区 Laplacian 方差 | 276.5（同图未覆盖的 OCR 行） | 1.3 | 高频能量降至 0.005，图标变为高斯团 |
| 图标上方未覆盖区域 | — | — | 保持锐利，模糊只在卡片矩形 + halo 内 |
| 还原后整屏（y≥300） | 干净 HAP | 干净 HAP | 均值 0.0、最大差 0、>2 像素 0 |

`ohos-backdrop-probe.jpeg` / `backdrop-probe-crop.png` / `ohos-backdrop-restored.jpeg`；
日志 `backdrop-probe-build.log`（EXIT=0）、`backdrop-restore-build.log`（EXIT=0）。
探针前 `/tmp/pdf_controller.entry_before_backdrop_probe.cj` 与还原后源均为
`861c670ee2d1fdaee1a8cffebf9372683119163a5616aa6cb68947bd2637babc`。

## macOS backdrop on-path（2026-10-19）

探针：`range_text_window_app` 的 `buildUi` 末尾向 root 追加 820×120 白卡
（alpha 0.35，`effectGroup(backdropBlurRadiusPoints: 12)`，`translateY: -430`），
覆盖正文文本。窗口由 PID 定位后 `screencapture -l` 直接取窗口像素（2024×1528）。
探针插入同样占用布局高度，正文区域被压缩；还原后消失。

| 量测 | 基线 | 探针 | 结论 |
| --- | --- | --- | --- |
| 卡片内正文 Laplacian 方差 | 1294.2（同区域原文） | 258.9 | 降至 0.200，文字成灰色团 |
| 卡片外标题带（y=140..210） | — | — | 最大差 0，未受影响 |
| 全图差异 | — | — | 差异仅落在卡片矩形 bbox (146,328)–(1082,566) |

`macos-backdrop-probe.png` / `macos-backdrop-probe-crop.png` / `macos-backdrop-baseline.png`；
日志 `macos_probe_build3.log`、`macos_baseline_build.log`（均 `cjpm build success`）。
探针后 `examples/range_text_window_app/src/main.cj` 恢复为
`2b5d5065b2a2d0833705203401769659a2197257df3c27cbb43b04f3b427ebd4`，干净构建与基线截图已复核。

## Linux on-path（2026-10-19）

探针：`range_text_window_app` 的 `buildUi` 在状态行后追加一组节点，一次覆盖五项能力：
标题 `rotateDegrees: 8`；状态行 `translateX: 60`；两个 `SCALE100`（第二个 `scaleX/Y: 0.7`，
固定宽 240 + gap 20）；200×28 裁剪父节点内放 380 宽、`translateX: 120` 的子文本；
先加红块（`zIndex: 3`，`translateY: 40`）后加蓝块（`zIndex: 1`）。来宾 Xvfb `:99`，
Vulkan llvmpipe，900×620，驱动 `/tmp/drv/driver shot` 取窗。

| 量测 | 期望 | 实测 | 结论 |
| --- | --- | --- | --- |
| 缩放文本字宽 | 0.70× | 73 px → 51 px = 0.699 | scale 生效 |
| 裁剪黄底宽度 | 200 px | x=16..215（200） | 父矩形裁剪 |
| 子文本越界部分 | 完全不可见 | x≥216 为背景色；文本按 380 宽绘制本应到 ~516 | 继承 clip 链生效 |
| 红/蓝重叠 | 红在后绘制覆盖蓝 | 红 y=198..237；蓝仅露 y=238..247 | zIndex 稳定排序，先加的红盖住后加的蓝 |
| 状态行左缘 | 正文 +60 px | 正文 x=23，状态行 x=83 | translateX 生效 |
| 标题倾斜 | tan 8°≈0.141 | 下缘回归斜率 0.118（可见倾斜，裁剪与字形包络使估计偏低） | rotateDegrees 生效 |

探针插入占用布局高度导致正文整体上移、标题上半被窗口裁掉，与变换无关；还原后消失。
`linux-visual-probe.png` / `linux-heading-tilt.png` / `linux-clean-baseline.png`；
日志 `linux-clean-build.log`（`cjpm build success`）、`linux-visual-probe-app.log`。

复现：`linux_guest.sh sync` 后进来宾执行
`cd ~/cjgui-linux/runtime/cjgui/examples/range_text_window_app && cjpm build --skip-script -j8`
（框架与 sidecar 由 `linux_guest.sh build`/`sidecar` 预先构建），
再在 `DISPLAY=:99` 下运行 `target/release/bin/main` 并用驱动 `shot`。
本轮修了同步脚本：`build-script-cache/` 此前会被 rsync 从 macOS 带到来宾，
cjpm 复用其中的 Mach-O `build-script` 报“无法执行二进制文件”；现已排除该目录。

## 普通消费入口（durable，2026-10-19）

`runtime/cjgui/examples/range_text_window_app` 保留一个可点击的视觉实验区，不再靠临时探针：

- `visualLabScene()`：五行场景。Translate 按钮；底/顶与两个同 zIndex 的重叠 chip；
  单节点组与含重叠子内容的裁剪组；tint/scale/rotate 三个开关与两块图标。
- 真实动作 ID：`VISUAL_LAB_TRANSLATE`、`VISUAL_LAB_UNDER/TOP`、
  `VISUAL_LAB_EQUAL_FIRST/SECOND`、`VISUAL_LAB_TINT/SCALE/ROTATE`。
- 状态读回：`dx`、`top`、`equal`、`tint`、`scale`、`rotate` 与 `last hit` 直接画在界面上，
  截图可脱离日志判断命中归属。
- 图标：`assets/tint_glyph_white.png`（白）与 `assets/tint_glyph_red.png`（红），
  都是非对称开口 C 环、带半透明抗锯齿边，便于观察旋转与半透明边缘乘色。

运行（macOS，当前主树）：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
cd runtime/cjgui/examples/range_text_window_app && cjpm build
cd runtime/cjgui && CANGJIE_HOME=/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3 \
  zsh ./scripts/run_macos_application.sh examples/range_text_window_app/cjgui_macos_app.sh --build-only
cd examples/range_text_window_app && \
  "./target/release/CJGUI Range Text Consumer.app/Contents/MacOS/CJGUIRangeTextConsumer"
```

`cjpm build` 不会刷新 `.app`；必须再跑 `--build-only` 重新打包签名，否则窗口仍是旧二进制。

### 实测与证据（2026-10-19 01:38–01:39）

窗口 900×620 逻辑点、2× drawable，`screencapture -l` 按 PID 取窗；点击用真实鼠标移动/按下/抬起。

| 动作 | 读回 | 结论 | 图 |
| --- | --- | --- | --- |
| 启动、未点击 | 两块 C 环均已出现 | 图片首帧绑定已修（见下） | `01-first-paint.png` |
| tint → scale → rotate | `tint 1`、`scale 1.50`、`rotate 20°` | 白 C 变橙、红 C 变暗橙；1.5× 后仍在固定组内，无错误裁剪 | `02-tint-scale-rotate.png` |
| 点同 zIndex 的重叠区 | `equal 1`、`last hit equal-second` | 后写者绘制在上并接收点击，同值保持书写顺序 | `03-equal-z-overlap.png` |
| 点 Translate | `dx 24` | 可见按钮移到新位置 | `04-translate-on.png` |
| 点原布局左缘 | `dx 24` 不变 | 原位置不误中 | `05-original-position-miss.png` |
| 点可见右缘 | `dx 0` | 可见位置有效 | `06-visible-position-hit.png` |
| 三个开关复原 | `tint 0`、`scale 1.00`、`rotate 0°`、`dx 0` | 颜色/大小/角度/位置恢复 | `07-restored.png` |

单节点组与重叠子内容组持续以 `0.45 / 0.65` 隔离合成显示；顶/底 chip 的 `top` 也在另一轮
点击中从 0 变为 1。资源只做一次开/关观察：整轮日志恰有 2 次 preparation start、2 次 ready
（白/红各一次），多次 tint/scale/rotate 重建没有重复解码，见 `image-preparation.log`。
进程按 PID 关闭后无残留消费者。

### macOS 首帧图片绑定修复

此前启动首帧只画占位、要点一下才出现图标。原因是纹理加载可能在该场景 commit 之前完成：
completion 通知找不到已接受的 subscriber，accepted 节点保留空纹理，之后没有刷新再取它。
修在 `CjguiRestoreAcceptedComposableImageDemand`（`cjgui_internal_renderer.m:8991` 一带）：
仅当资源已 Ready 且 accepted 节点的 `imageTextureContentKey` 还不是该 cache key 时，
递增 completion epoch 并发布一次 viewport snapshot；已绑定场景不触发，避免刷新循环。
修复后启动首帧即显示两块 C 环（`01-first-paint.png`）。

## macOS 局部效果快路的变换边界（2026-10-19 收尾）

`CjguiEffectLocalPaintNodes` 只重新基址已平移的绘制输入：目标按未旋转的 body/support
计算，私有 clone 从零 geometry 起步且只回填平移与 clip，矩形 clip 也覆盖不了旋转后的
四边形。图片节点本就被该函数排除，所以普通图片演示不能证明这条路径。

本轮在预检中按绘制路径同样的归一化规则（非有限/非正的 scale 视为 1，非有限 rotation
视为 0）检查组内所有节点：任一节点有非单位 scale 或非零 rotation 即返回
`reason=non_translation_transform`，交给通用效果路径；纯平移（含小数相位）保留局部复用。
通用路径的输出范围与内容签名本已包含变换，恢复恒等后局部快路重新生效，不需要全局禁用缓存。

定向证据使用纯形状 2 节点组（无图片）：非等比 2×/0.5× + 45° 与 3×/0.5× + 90°
均退出局部快路，目标范围分别为 166×166、244×244（2× device px）；采样点按“先 scale 后 rotate”命中，
按相反顺序则不命中。恢复恒等后 80×80 局部目标重新生效，随后 32 pt 平移复用同一目标且
目标像素逐字节相同。既有纯平移生产夹具 `failures=0`；普通消费者完成
scale 1.50 → +20° → 复原的连续操作。详见
[local-transform-fallback-20261019](local-transform-fallback-20261019/README.md)。
**验收范围仅 macOS**；OHOS/Windows/Linux 的组合变换保持未验。后续平台若出现效果组
缩放丢失或旋转后被矩形裁剪，应先核对该平台的输出范围、私有绘制输入与缓存身份是否
携带变换，按框架/平台接入缺口处理，不能据 macOS 结果假定“都已经有了”。

## 能力 × 平台（2026-10-19 收口）

标记含义：**消费** = 真实输入/状态/像素；**实现** = 源码路径存在；**编译** = 构建或语法检查；
**未做** = 未接通。Windows 本轮只做到主树语法编译，未运行；OHOS 新计数/交互未真机重跑。

| 能力 | macOS | Windows | Linux | OHOS |
| --- | --- | --- | --- | --- |
| tint 乘色（RGB×RGB、alpha×alpha） | 消费（白/红+半透明边，开关还原） | 实现+编译 | 未做（缺图片管线） | 实现 MODULATE；双素材真机复验未跑 |
| 矩形 clip 链 | 消费 | 实现+编译 | 消费（Xvfb/llvmpipe） | 真机探针（既有） |
| 圆角裁剪 | 单节点圆角消费；clip 链每角圆角未全验 | 实现+编译 | 未做（scissor-only） | 单节点圆角 clip；clip 链每角未全验 |
| 任意形状裁剪 | 无 | 无 | 无 | effectMask 未暴露/未消费 |
| rotateDegrees | 消费（paint-only） | 实现+编译 | 消费（paint-only） | 真机探针（paint-only） |
| zIndex（同值保序） | 消费（top/equal） | 实现+编译 | 消费 | 真机探针 |
| effectGroup 隔离合成 | 消费；固定组内 1.5× 子节点不裁剪 | 逐节点 alpha，未隔离；编译 | 未做 | SaveLayer + 含组计数；新计数真机未跑 |
| backdrop | 探针通过 | 实现+编译 | 未做 | 真机探针通过 |
| translate（几何 sidecar） | 消费：可见命中、原位不中 | 实现+编译 | 消费 | 实现已接命中/文字/滚动；真机交互未跑 |
| scale | 消费（paint-only） | 实现+编译 | 消费（paint-only） | 真机探针（paint-only） |

zIndex 在共享模型 `paintOrder` 内做稳定插入排序，节点数组按绘制序下发给四端，
渲染器不再排序；effectGroup 的数组区间不因 zIndex 拆开（同区间内排序）。

### Windows 构建范围

冻结交付锚定 `a8ad478459c7f68588d49af82dba108ee8e1e856`（commit
`checkpoint: CJGUI R7 and shared framework work`），入口仍是
[Pharos Windows R7 current source/BUILD.md](../../../../../../artifacts/windows-pharos-20261005/delivery/Pharos%20Windows%20R7%20current%20source/BUILD.md)。
本轮不覆盖冻结交付、不启整套 Pharos relay 重编。受影响 native 用当前主树源码做 mingw 语法检查：
`cjgui_windows_renderer.c` 与 `cjgui_windows_wic.c` 在
`x86_64-w64-mingw32-gcc (GCC) 16.2.0` 下均 exit=0、无诊断，命令与时间见
`windows-compile-check.txt`。官方 Windows 来宾/SDK 流程未运行，故 Windows 只有“实现+编译”，
没有“正常消费”；不再写“没有构建脚本”。

### 未完成边界（不改名成完成）

- **OHOS 复验**：effectGroup 新计数、translate 命中/文字/滚动、tint 双素材都已在源码收齐，
  但本轮没有真机重跑；完整 ArkTS/HAP 构建仍被既有 `EntryNapiTextProxyBridge`/`Index.ets`
  错误阻塞。旧真机图只证明旧约定下的隔离合成、乘色外观和绘制变换，不证明新计数或交互。
- **Linux**：矩形 clip 链、rotate、zIndex、translate/scale 已在正常消费者像素验证
  （Xvfb `:99` + Vulkan llvmpipe，非物理 GPU）。tint 缺图片解码/上传与采样；
  effectGroup 需离屏目标+合成 pass；backdrop 需已绘帧采样；圆角需 SDF/几何改造。
  未用逐节点 alpha 冒充整组合成。
- **Windows**：effectGroup 仍把 opacity 乘到每个节点（重叠子内容二次混合），没有子树隔离；
  其余能力实现且编译通过，但运行/命中/画面未验。
- **圆角与任意形状**：`cornerRadii*` 已进 ABI/准备声明相等，但 Linux 未绘制、其他端未全验；
  `effectMask` 线性 alpha 只在 ABI/部分模型存在，未接通任意形状裁剪。
- **文字扩展字段**：已有 `textMaxLines`/`textOverflow` 是当前消费契约；
  追加的 `letterSpacing`、`lineHeightPoints`、`maxLines`、`ellipsisEnabled` 与 `cornerRadii*`
  已进入准备声明比较，但尚未被全部渲染器消费，不能按“已支持”宣传。
- **变换边界**：translate 是交互变换（命中/文字/滚动随可见位置）；rotate/scale 仍只有绘制，
  不改布局矩形、命中或文本编辑几何。macOS 的绘制顺序已由源码与本轮非等比像素用例确认为
  translate → 绕中心 scale → 绕中心 rotate；OHOS 须按实际 Canvas 矩阵合成解释调用顺序，
  本轮未跑非等比真机用例；Windows/Linux 本轮未运行该用例。三者均保持未验，
  不再写“四端按同一顺序”。
- **物理 GPU**：macOS 为 Metal 真窗口；OHOS 为真机；Linux 为 Xvfb+llvmpipe；Windows 未运行。

## 空间

本页证据由 3.0 MB 增至 5.1 MB（新增普通消费截图/日志 2.1 MB、编译检查文本 1 KB）；
本轮有限收尾再加入 `local-transform-fallback-20261019/` 1.3 MB（定向夹具/日志与
3 张连续操作截图），合计 6.4 MB。无 GiB 级产物，宿主 `df /` 收尾剩余 297 GiB。
来宾沿用既有 `~/cjgui-linux` 单工作目录，无新增复制树；本轮探针进程、消费者窗口与
Xvfb `:99` 已按身份停止。
历史探针源码已还原：Pharos `pdf_controller.cj` = `861c670e…`；
`range_text_window_app/src/main.cj` 现为保留的普通视觉场景，不再还原成旧基线。
Windows 冻结交付未改动，未提交 Git。
