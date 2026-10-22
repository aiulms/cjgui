# Linux 普通应用构建与启动入口

更新：2026-10-22。范围：`scripts/run_linux_application.sh`（Linux 本机入口）、
`scripts/linux_application.py`（实现）、`scripts/build_sidecar.sh`（native 归档）、
`scripts/linux_guest.sh`（可选 SSH 运输）、`scripts/create_linux_application.sh`
（ui-only / mixed-form / edit-preview 建项）与 `scripts/resolve_source_closure.py`（显式诊断）。

本入口面向任意普通应用目录：显式接收应用、框架与工具链，每应用独立准备和编译，
运行本轮实际构建的二进制。它不保存作者机器地址、来宾目录或预编译样例；SSH 只是可选运输。

## 前置

- Linux 本机（`build` 会拒绝其他宿主；跨机请用 `linux_guest.sh` 运输后在 Linux 上执行）。
- Python 3.11+（`tomllib`）。
- 仓颉工具链：可 `source` 的 `envsetup.sh`，其中 `cjpm` 可用。
- `cc`、`ar`、`flock`、`pkg-config`，以及 `vulkan xcb x11 x11-xcb xkbcommon freetype2 harfbuzz fontconfig libpng` 开发包。
- `run` 需要调用会话里已有显示环境（如桌面会话的 `DISPLAY`，或 `Xvfb :99` 的 `DISPLAY=:99`）。

## 命令

```bash
scripts/run_linux_application.sh build \
  --app /abs/path/to/application \
  --framework /abs/path/to/runtime/cjgui \
  --toolchain /abs/path/to/cangjie/envsetup.sh \
  --output /abs/path/to/application-output

scripts/run_linux_application.sh run --output /abs/path/to/application-output -- --app-arg
scripts/run_linux_application.sh clean --output /abs/path/to/application-output
scripts/run_linux_application.sh diagnose --app … --framework … --toolchain … --output …
```

- `--app` / `--framework` / `--toolchain` / `--output` 均为 Linux 路径，必需且显式。
- `--framework-sources FILE`（可选）：只冻结列出的 `src/` 相对 `.cj` 路径；不传则冻结框架
  `src/` 下全部生产源码（排除 `*_test.cj`）。
- `--gcc-lib-dir`：编译器无法自报 libgcc 目录时显式给出。
- `--link-option`：追加到生成的链接参数；`--jobs`、`--timeout` 控制编译并发与每步超时。
- `run` 后的应用参数放在 `--` 之后；`run` 返回应用进程的真实退出码。
- `diagnose` 才执行闭包诊断：一次显式构建后把未声明符号与源码建议写入
  `closure-diagnostic.json`；不自动重试、不删除 target、不把建议直接纳入输入。
- `package --output … --destination … [--name …]`：重新核对 build receipt、全部输入哈希和
  二进制身份，生成相对资源、明确运行库依赖的 `.tar.gz` 预览包（`bin/main`、`lib/`、
  manifest、`run.sh` 与复现说明）。解压后不依赖原工作区、源码或构建缓存；系统库仍由
  目标机提供，不打包工具链或整个 SDK。

## 普通应用建项（ui-only / mixed-form / edit-preview）

```bash
scripts/create_linux_application.sh ui-only /abs/path/to/new-application \
  --framework /abs/path/to/runtime/cjgui
scripts/create_linux_application.sh mixed-form /abs/path/to/new-application \
  --framework /abs/path/to/runtime/cjgui
scripts/create_linux_application.sh edit-preview /abs/path/to/new-application \
  --framework /abs/path/to/runtime/cjgui
```

- `edit-preview` 为显式 opt-in：生成一个编辑主窗和一个共享同一通知 owner、字体注册表与
  生成区域的预览窗，经 `CjguiLinuxApplicationHostGroup` 泵送，不引入第二套平台栈或业务
  状态机。模板在 `templates/application/edit_preview/`，复制 `src/`（含
  `notification_generated.cj`、`preview_window.cj`）、`resources/fonts/`、Linux
  `cjpm.toml`、`run.sh` 和 README，并忽略 macOS `._*`/`.DS_Store`（共 8 个文件）；
  默认 ui-only 不增重。来宾已据此建项并编译 `4eaaa71d560f4058a6c879098facc2bc`，
  冒烟“启动→关预览→关主窗”取得 `EXIT=0`、descriptor removed，两窗
  `RENDERER_DESTROY` 与 `PREVIEW_FONT_EXIT` 均出现。
  **当前限制（out-r17）：** 关闭一次预览后主窗仍可点击和续写；但重开预览后再关闭它会在
  第二个预览会话销毁时 `free(): invalid pointer`（`EXIT=134`、descriptor present）。
  独立 C 复现排除了“共享实例＋主设备常驻＋两预览设备/字体 face＋重开”的最简外部
  形状（10/10、ASan 3/3、真实 `:0` 均 0）；仓颉最小双窗消费者也 3/3 绿，排除框架
  host/window/text 生命周期本身。剩余指向应用特有的共享 owner/生成区域/session
  或其解绑时序。
  根因未定位前不要把 edit-preview 的“关→重开→关”当作可用流程；默认 ui-only 不受影响。
  证据见 `evidence/font-styled-multiwindow-20261022/final-chain-20261022/` 与
  `evidence/font-styled-multiwindow-20261022/reopen-20261022/text-lifecycle-harness-20261022/`。

- 默认 `ui-only` 保持轻量：两个文本字段、按钮、轻量弹层、公共图片节点和状态反馈。
  `mixed-form` 为显式 opt-in：手写区域与运行时生成区域共用一个通知领域 owner、字段与动作
  声明；生成结构由独立客户端按公开 catalog 提交，不重新编译。
  模板源在 `templates/application/ui_only/`；业务/UI 控制器与公共
  `cjguiCreatePlatformApplicationHost` 共用，平台差异留在宿主和构建适配。
- ui-only 建项复制 `src/`、Linux `cjpm.toml`、`run.sh`、README 和两张 starter 图片；
  mixed-form 复制 `src/`、`client.py`、Linux `cjpm.toml`、`run.sh` 和 README，不复制图片。
  目标已存在时拒绝，不复制 target、`.cjgui` 等构建产物。
- mixed-form 只消费既有框架与业务资产：`cjgui`、`shared_operation_core`、
  `examples/notification_threshold_application`。`client.py` 从 `cjpm.toml` 解析框架相对路径，
  用公开 `GeneratedUiSession`/`SharedOperationClient` 查询 catalog、提交结构、编辑同一草稿；
  支持 `inspect/create/read/reorder/reject`。生成区域不保存第二份业务状态。
- 新应用 `run.sh` 用 `CJGUI_CANGJIE_TOOLCHAIN`（envsetup.sh 或工具链目录）显式配置，
  默认 `all`（build + run），也支持 `build/run/package DEST/clean/diagnose`；输出默认为
  应用目录下 `.cjgui/linux`，可用 `CJGUI_LINUX_OUTPUT` 指定。
- 构建使用 `platforms/linux/framework-sources.txt`（主树显式源码清单）；该清单
  列出 Linux 普通应用与 mixed-form 消费所需的 66 个 `.cj`（含布局、图片、range、
  generated form/region/session），不把历史冻结目录当长期核心。本轮按主树 `dc27dff`
  共同源冻结校准；换框架版本时须同步核对清单。手工构建 edit-preview 时不要误用仓库
  父目录的 435 行清单：它包含 macOS Metal 源，链接会报 `cjgui_native_bridge_*` 未定义。
- 两个输入框显式声明 `pointerInteractive: true`，否则共同层会拒绝点击捕获；应用在首个
  accepted 场景（`acceptedNodeCount() > 0`）后一次性聚焦字段 A 并打印
  `CJGUI_UI_ONLY_FOCUS node=6`，`pumpOneTurn()` 返回 true 不算 accepted，之后不在泵循环
  里重复抢焦。
- Linux native 从 accepted 节点安装普通文本编辑代理（`TEXT_INPUT` / `INTEGER_INPUT` /
  `MULTILINE_TEXT_INPUT`）；左键命中文本或 Tab/ShiftTab 切焦时安装/复用代理、放置 caret
  并推送 FOCUS；点击/聚焦字段 B 后按键不再写入 A。owned/range 目标的点击保留原
  POINTER_BEGIN/MOVE/END 捕获，不被普通文本分流吞掉；空代理恢复按匹配的真实声明解析
  kind，不依赖调用方显式传入。换焦、节点退役、只读拒绝、accepted 值同步和归属都在后端
  完成，普通模态返回/页签书签的 restore 不再把代理无条件升级为 owned。
- 键盘：Tab/ShiftTab 按 accepted 顺序和 `inputScope` 切焦（X11 ISO_Left_Tab 同
  Shift+Tab），跳过禁用/只读；按钮 Enter/Space 激活，布尔切换；文本焦点在按钮获得焦点时
  释放，打字不写旧字段；弹层初始焦点由 `cjguiComposableDialogLayer(initialFocusNodeId:)`
  给出，Esc 在 native 发 `DISMISS_LAYER("escape")`，应用只在事件 36 中关闭弹层。组合输入
  中或带 Ctrl/Alt/Super 时不拦截 Tab。键盘 Enter/Esc 取消后共同层把焦点还回打开弹层的
  按钮，需 Tab/ShiftTab 回字段再续写（鼠标路径仍走上包 bookmark 恢复）；可见焦点由共同
  FOCUS 身份绘制。
- ui-only 的正常链：鼠标链 `alpha` → 点击 B `beta` → 回 A 打开/取消弹层 → 续写 →
  `alphaz!`/`beta`；键盘链 `alpha` → Tab B `beta` → ShiftTab → 按钮键入不写 → Space 开 →
  Enter 取消 → ShiftTab×2 → `alpha!z` → Enter 开/Esc 关；两条链均精确读回两字段、画面
  一致、正常关闭，见 `evidence/application-scaffold-20261020/RESULT.md` 第二、三包。
- 图片行同时声明两张公共 `cjguiComposableImage`：A=`composable-beacon.png`
  （身份 `ui-only-beacon-a`，140×90），B=`composable-beacon-coral.png`（身份
  `ui-only-beacon-b`，150×96）。Tab 至「替换图片」按 Space/Enter 只递增 A 的版本并
  切换 fit/fill，「移除图片」隐藏 B；owner 回执带
  `image_a_version/image_a_mode/image_b_visible/image_b_version`，应用不持有资源状态机。
  Linux 图片域用系统 libpng 做有界异步解码（2 worker、pending 4、在途 64 MiB、每请求
  预留 16 MiB、ready 8 项/32 MiB、记录 16、最大边 2048）；ready 满时只淘汰无引用项，
  仍无空间则该项进入可重试 FAILED（`reason=ready_capacity`），引用释放后自动重试。
  每张图片的上传 staging 在该次上传的 fence 完成后释放，不再随缓存纹理保留；
  退休纹理同时要求“该代上传序号已证明”和“最后使用它的 frame 提交已完成”，
  维护点在图片 pump/begin_frame，只轮询真实 fence，不等设备、不依赖额外绘制帧。
  `CJGUI_LINUX_IMAGE_TRACE=1` 输出 create/settle/evict/预算与容量失败，
  `CJGUI_LINUX_GPU_TRACE=1` 输出 release_staging/retire/reclaim 与关闭时的
  `image_usage`；本负载的证据、资源账与边界见
  `evidence/application-image-reclaim-20261021/RESULT.md`。

可选 SSH 运输（不设默认地址；应用、框架与输出仍是 Linux 路径）：

```bash
scripts/linux_guest.sh --guest user@host -- build \
  --app /linux/app --framework /linux/runtime/cjgui \
  --toolchain /linux/envsetup.sh --output /linux/app-output
```

运输只发送工具脚本；构建与运行发生在 Linux 上。

## 输出、隔离与锁

`--output` 是一个应用独占根，必须与源码根分离，且不能是符号链接。布局：

```
output/
  output-owner.json          # 应用归属；不同应用不能复用同一输出根
  .lock                      # 输出根互斥锁
  inputs/packages/…          # 冻结的源码快照与生成的 cjpm.toml
  inputs/native/…            # 冻结的 Linux native 源码与头文件
  native/lib/…               # 本应用私有 native 归档（含 sidecar 锁）
  target/                    # 本应用私有 cjpm target
  bin/main                   # 本轮成功构建后提升的二进制
  build-receipt.json         # 成功收据与全部输入身份
  last-build.json            # 最近一次构建结果（含失败退出码）
  logs/                      # native/build 原始合并日志（有上限）
```

- 锁从输入准备一直覆盖到编译和收据发布；`run` 在应用完整运行期间持有该锁，避免同一
  输出根的并发构建/运行。旁路直接调用 `build_sidecar.sh` 时另有私有目录锁。
- 每步 `--timeout` 使用绝对 deadline；stdout 已 EOF 也只等剩余时间，耗尽返回 124，
  不会因子进程提前关闭输出而绕过超时。
- `SIGTERM`/`SIGHUP` 先转为受控退出：入口终止并等待本次构建或运行的自有子进程（子进程
  忽略 `SIGTERM` 时升级终止），确认收回后才释放输出锁；清理期间的重复 `TERM`/`HUP`
  延后处理，不打断进程组回收或提前解锁。`run` 在应用启动后若回执写入失败，也先清理该
  子进程再退出，不留下脱离锁的进程。
- 若进程组在清理后仍存活，入口写 `logs/residual-process-group.json` 并回退出码 2；
  之后的 `build`/`clean` 取得输出锁后先核对 marker，组仍活则拒绝复用该输出根，组已消失
  才移除 marker 并继续。抛错不等于继续持锁。
- 每次构建先撤销旧的成功收据，再开始准备；失败、缺二进制或源码在构建期间变化都不会
  留下可运行的旧授权。
- `clean` 只退役本应用 `target/`，保留快照、native 归档、二进制和收据。

## 身份与退出码

`build-receipt.json` 记录准备文件与生成配置的 SHA-256、native 归档与二进制的 SHA-256、
构建 ID、工具链环境脚本、链接配置路径。`run` 启动前逐一核对；任一输入变化即拒绝运行。

退出码：构建/诊断返回真实失败码（`cjpm`/编译器原码，超时 124，日志超限 125）；
参数、路径、工具链等准备错误或清理后残留进程组返回 2；`run` 返回应用自身退出码；
`SIGTERM`/`SIGHUP` 返回 143/129。中断时 `run-result.json` 记录被终止子进程的真实结果和 `interrupted` 信号；
生成配置不可手改，需要变体时修改原应用/框架清单后重新构建。

## 边界

本入口只解决 Linux 上普通应用的准备、构建与启动，不改变平台功能范围。它不自动同步
源码、不推断缺失文件、不清理其他任务或他人输出，也不替代渲染/输入验收；显示环境与
窗口操作仍由 Linux 会话或测试驱动提供。

## 已验预览包（2026-10-22）

`~/CJ GUI Delivery/run space/cjgui-notification-linux`（目录含空格）由既有 `package`
入口生成：`run.sh` 只补包内 `lib/`，启动前用 `ldd` 报缺失系统库。已在 openEuler 26.09
aarch64 的真实 Xorg `:0` 用 `env -i`（仅 PATH/HOME/DISPLAY/XAUTHORITY/locale/XIM）启动；
外部客户端建项后手写与生成区域共用同一草稿，owner 读取成功，`driver2 close` 正常关闭，
wrapper 记录退出码 0。二进制 `4e93ae67…`，build id `2cf582e3…`，manifest `50b4dbb3…`，
冻结 66 个 `.cj` 与 build receipt 106 个输入。

- 范围：X11 + Vulkan(llvmpipe)、公共滚动区/焦点 reveal/对话框、owned 与普通文本、
  系统 XIM 预编辑与 caret spot、外部 SharedOperation 读写。
- 组合边界已用真实反例核对：同文双字段切焦、生成绑定替换、组合期间外部改值；
  空格提交后 owner 分别为原值/原值/外部值，旧预编辑未混入。组合期间窗口缩放、外部
  样式属性刷新或无关生成树重排不打断合法预编辑；被拒绝的生成结构候选（`unknown_field`）
  也未被组合重绘提升，预编辑继续，见 `evidence/ime-candidate-spot-20261022/` 的
  `reject-candidate/`。Escape 取消后画面立即只余 accepted 文本。
- 候选 look-up 窗：根截图与窗口树核对。旧候选把 XIM spot 预翻译成 root，ibus-x11
  又平移一次 client window 原点，滚动后候选窗整体落到屏幕外；平台桥改为按窗口内像素
  发送，最终候选上候选窗几何等于窗口原点+spot，随字段和滚动移动、贴在 caret 下方。
  候选窗仍由 IBus/UKUI 绘制；窗口局部截图看不到它（独立 override-redirect）。
  证据 `evidence/ime-candidate-spot-20261022/RESULT.md`。
- 不宣称：Wayland、Android、硬件 GPU、其他发行版。
- 唤醒已接通（2026-10-22）：Linux 共享调度门为真，`pumpOneTurn` 安静窗最多阻塞
  250ms；传输通知、图片完成、输入与关闭都走既有 self-pipe + X11 `poll`，动画/活动
  由共享 `ownerIdleWaitAllowance` 压到 16ms。同一 :99 空闲 10s 实测 0.30% CPU、
  3.9 次自愿切换/s、外部只读中位 0.26ms（candidate2 为 2.00%、53.8/s、12.37ms）；
  输入到 owner 读回 43ms，关闭 44ms。最终包 `f1cfe4b2…` 在同一 :99 复测为 0.30%、
  3.9 次/s、中位 0.29ms、RSS 176MB、关闭 26ms，确认 spot 修复未改变调度路径
  （`evidence/ime-candidate-spot-20261022/final-perf/`）。
  真实 `:0` + IBus 的独立包已在最终候选 `f1cfe4b2…`（包 `1ee32ceb…`）上重跑完整
  长表单链（缩窗/滚动/Tab 揭示/preedit+提交/弹层/外改即续写/生成 Apply/owner 全读回/
  关闭），候选窗贴 caret 的根截图核对见 `evidence/ime-candidate-spot-20261022/RESULT.md`；
  旧候选 `92065ad8…` 的同链留在 `evidence/longform-wake-20261022/RESULT.md`，四项组合
  身份反例见 `evidence/composition-final-20261022/RESULT.md`。Mac 同源短链已由本线用
  冻结共同源在隔离主机树实跑（WeType `nihao`→`你好` v1→正常关闭退出 0；非 Sol
  候选/交付包），见 `evidence/mac-samesource-20261021/RESULT.md`；冻结
  transport/清单/app 源仍在 `evidence/ime-candidate-spot-20261022/frozen-inputs/`。
  详见 `evidence/wake-20261022/RESULT.md`。
