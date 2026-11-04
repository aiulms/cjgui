# ui-only starter（Linux 建项入口）

平台中立的纯 UI 起始应用：两个文本字段、按钮、轻量弹层、两个公共图片节点和一行状态
反馈。业务与界面只由 `UiOnlyStarterController` 持有；窗口宿主用
`cjguiCreatePlatformApplicationHost` 取得，因此同一份 `src/` 由各平台宿主和构建适配
消费，不复制平台业务或状态机。

本源码从现有 macOS ui-only 起始模板的 UI/业务控制器提取，宿主创建改为公共工厂；
macOS 模板自身的收敛不在本轮写集。

## 建项

```bash
runtime/cjgui/platforms/linux/scripts/create_linux_application.sh ui-only \
  /abs/path/to/new-application --framework /abs/path/to/runtime/cjgui
```

建项会复制 `src/`、Linux 清单和 `run.sh`，并带上 `composable-beacon.png` 与
`composable-beacon-coral.png`；不复制 target、`.cjgui` 或其他构建产物。目标已存在时
拒绝，不覆盖。

## 构建与启动

```bash
cd /abs/path/to/new-application
CJGUI_CANGJIE_TOOLCHAIN=/abs/path/to/cangjie/envsetup.sh ./run.sh          # build + run
CJGUI_CANGJIE_TOOLCHAIN=... ./run.sh build                                 # build only
CJGUI_CANGJIE_TOOLCHAIN=... ./run.sh run -- <app args>                     # run receipt
CJGUI_CANGJIE_TOOLCHAIN=... ./run.sh package /tmp/app-preview.tar.gz       # preview package
CJGUI_CANGJIE_TOOLCHAIN=... ./run.sh clean                                 # retire target
CJGUI_CANGJIE_TOOLCHAIN=... ./run.sh diagnose                              # explicit diagnostic
```

`run.sh` 通过清单里的相对框架路径找到
`platforms/linux/scripts/run_linux_application.sh`，使用
`platforms/linux/framework-sources.txt`（主树明确源码清单）构建。输出根默认为
应用目录下的 `.cjgui/linux`，可用 `CJGUI_LINUX_OUTPUT` 指定；工具链不写死，必须由
`CJGUI_CANGJIE_TOOLCHAIN` 给出。GUI 运行需要调用会话已有 `DISPLAY`。

## 读回与改动

每次接受的字段编辑或按钮点击都会向 stdout 打印一行
`CJGUI_UI_ONLY_OWNER a_hex=… b_hex=… count=… revision=… dialog=…`，并附
`image_version=… image_width=… image_height=… image_mode=…`；状态行渲染的是同一个
controller 状态。只改 UI 文本或布局后重新 `build`，native sidecar 指纹不变，不应重编
native。

两个输入框在清单里声明 `pointerInteractive: true`，否则点击会被共同层的指针捕获规则
拒绝。启动后应用等首个 accepted 场景（`acceptedNodeCount() > 0`）再一次性聚焦字段 A 并
打印 `CJGUI_UI_ONLY_FOCUS node=6`；`pumpOneTurn()` 返回 true 只表示宿主已打开，不算
accepted 证据，之后焦点由共同窗口和平台后端负责，不在泵循环里重复抢焦。

Linux native 在 `focus_composable_node`、左键文本命中和 Tab/ShiftTab 切焦时从 accepted
节点安装/复用普通编辑代理（`TEXT_INPUT` / `INTEGER_INPUT` / `MULTILINE_TEXT_INPUT`），
按键复用已有编辑事件通道；点击或 Tab 到 B 会真实切焦并放置 caret，不会继续写入 A。
换焦、节点退役、只读拒绝、accepted 值同步和 owned/普通归属都由后端按真实绑定声明处理，
应用只保留业务状态。

键盘操作：

- `Tab` / `Shift+Tab` 按 accepted 顺序与 `inputScope` 切焦，跳过禁用、只读和零尺寸节点；
  X11 的 Shift+Tab 可能是 `ISO_Left_Tab`，后端与 `Tab+ShiftMask` 同等处理。
- 文本字段获得焦点可继续编辑；按钮、布尔、页签等获得焦点时文本代理立即释放，此时打字
  不会写入旧字段。按钮用 `Enter`/`Space` 激活，布尔用 Enter/Space 切换。
- 弹层内按 `Esc` 发 `DISMISS_LAYER("escape")`，应用在 `eventKind == 36` 中关闭弹层。
  弹层把字段 A 声明为 owner（`cjguiComposableDialogLayer(..., "ui-only-note-a", 6, ...)`），
  取消/Esc 后由共同模态返回事务恢复字段 A 及其文字选区；模板不再在 CANCEL/Esc 中手工调用
  `focusAcceptedNodeById`，避免用一次聚焦把 caret/选区重置到开头。可见焦点由共同层按
  FOCUS 身份绘制，应用不需要复制焦点状态机。旧“焦点回按钮”说明及对应旧包证据已被此接线
  取代，以本段和本节末尾的双窗证据为准。
- 系统组合输入进行中或带 Ctrl/Alt/Super 时不拦截 Tab；应用不处理 IME 组合本身。

## 命名双窗消费者（`--two-windows`）

Linux 额外提供两个薄编辑窗，共用同一个 owner 和业务状态，用
`CjguiLinuxApplicationHostGroup.requestOpen("editor-a"/"editor-b", factory)` 登记；controller
由每代窗口的 factory 创建，窗口 id 与 controller/region/字体生命周期一一对应。启动：
`./run.sh run -- --two-windows`，窗口标题为 `字段 A · 薄编辑窗` / `字段 B · 薄编辑窗`。

- **初焦按窗口代次一次**：每代 accepted 场景就绪后只调用一次 `focusAcceptedNodeById`（A=6、
  B=7），打印 `CJGUI_UI_ONLY_WINDOWS focus=a|b id=…`；不在泵循环里逐回合抢焦，重开的新代次
  才算新一次。
- **输入隔离与返回**：A/B 各自输入互不串写；Tab / Shift+Tab 在同一 owner 的 accepted 顺序
  内切焦；弹层 owner 为当前字段，取消后恢复该字段的 bookmark（含反向选区归一后的范围），
  下一键以操作前正文和范围精确替换，不由字数推断。
- **跨窗系统 IME**：一窗处于组合态时切到另一窗，提交/取消只作用于当前绑定；提交文本进入
  当前字段，取消不改值。
- **最小化/恢复/缩放**：X11 `UnmapNotify` 只标记不可绘制，不销毁会话；另一窗仍可输入和
  处理外部操作。`MapNotify` 恢复时发送当前逻辑尺寸 RESIZE 和 EXPOSE，用最新 accepted 场景
  重绘，不伪造隐藏期间的 present；`ConfigureNotify` 后点击/外部操作按新布局命中。
- **按需更新**：两窗静置时 CPU、场景与绘制提交不增长；只有真实输入、恢复或缩放才产生新的
  accepted 场景/绘制。不删除光标或组合反馈来换数字。
- 关闭一窗后另一窗继续；重开得到新窗口 id 和新代次初焦，旧 id 的关闭返回 `stale_window`；
  系统关闭两窗后整体退出（`settled=true windows=0`）并逐个销毁渲染会话。该消费者不持有
  字体/图片资源，资源终态另见通知应用与 edit-preview 证据。证据见
  `platforms/linux/evidence/public-host-desktop-r28-20261022/`。

历史键盘链（2026-10-20，早于本轮弹层 owner 接线；“焦点回按钮”已不代表当前行为）：
`alpha` → Tab B `beta` → ShiftTab A → Tab/Tab 按钮（键入 `x` 不写字段）→ Space 开弹层 →
Enter 取消（当时 A=`alpha!`，焦点回按钮）→ 在按钮上键入 `z` 不写 → ShiftTab×2 回 A →
`z`（A=`alpha!z`，B=`beta`）→ Tab/Tab Enter 再开 → Esc 关闭（A 不变）→ 正常关闭，见
`platforms/linux/evidence/application-scaffold-20261020/RESULT.md` 第三包。当前弹层返回、
精确选区与双窗连续链以 `platforms/linux/evidence/public-host-desktop-r28-20261022/` 为准；
同一旧文件第二包的鼠标点击 `alphaz!`/`beta` 证据仍成立。

## 公共图片（Linux 本地 PNG）

图片栏同时声明两张公共 `cjguiComposableImage`：A=`composable-beacon.png`（身份
`ui-only-beacon-a`）、B=`composable-beacon-coral.png`（身份 `ui-only-beacon-b`），各在
150×96 裁切框内显示。「替换图片」（Tab 第三次到达）只递增 A 的版本并在 fit/fill 间
切换；「移除图片」（第四次到达，B 可见时存在）只是不再声明 B 节点。解码、版本、纹理、
缓存与回收都由框架图片域负责，controller 只改业务声明，没有第二套资源状态机。

Linux 当前只支持本地 PNG（系统 libpng）：2 worker、pending 4、在途 64 MiB（每请求预留
16 MiB）、ready 8 项/32 MiB、记录 16、最大边 2048。完成队列满时 worker 等待而不是
丢结果；ready 全部被引用时第 9 张进入具名 `FAILED reason=ready_capacity`，释放引用后
自动重试。失败是具名状态，不每帧重解码、不全局等待设备；图片上传 staging 在该次
上传 fence 完成后释放；退休纹理要求本代上传序号与最后使用它的具体帧提交都已完成，
由图片 pump/begin_frame 轮询维护，不依赖额外绘制帧。

owner 回执包含 `image_a_version/image_a_mode/image_b_visible/image_b_version`。素材解析
顺序：场景相对路径依次按 cwd、可执行文件目录、`CJGUI_LINUX_RESOURCE_DIR` 解析为稳定
绝对路径。诊断可设 `CJGUI_LINUX_IMAGE_TRACE=1` 打印 create/settle/evict，
`CJGUI_LINUX_GPU_TRACE=1` 打印 release_staging/retire/reclaim 与关闭时的
`image_usage`；多图真实链、线程/关停反例与资源账见
`platforms/linux/evidence/application-image-reclaim-20261021/RESULT.md`。
