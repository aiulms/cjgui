# Experimental macOS 应用宿主

`CjguiMacosApplicationHost` 是当前普通 macOS 窗口的实验性框架入口。应用只在仓颉中保有 controller、领域状态、动作和可选的 shared-operation connection；框架宿主管理一个 AppKit 主线程进程、一个 `CjguiComposableUiWindow`、既有 `TurnScheduler`、部分启动失败清理与正常关闭。它不承诺稳定 ABI、安装包、公证、多窗口、完整 IME 或多平台。

## 最小消费目录

设 `CJGUI_ROOT` 为本仓库的 `runtime/cjgui` 目录。新应用目录只需要下列四个文件；不要复制 renderer、launcher、`Info.plist` 或其他 example。

`cjpm.toml` 仍声明框架 runner 生成的两个静态库。cjpm 1.1.3 会合并依赖与应用的同名 FFI 声明，runner 将两处都固定到本应用缓存，避免依赖里的共享路径优先胜出。它不要求应用声明或调用任何 foreign 函数，所有 native 实现在 `$APP_DIR/.cjgui/native/lib` 中由框架 runner 生成。

```toml
[package]
cjc-version = "1.1.3"
name = "my_cjgui_app"
version = "0.0.0"
output-type = "executable"
src-dir = "src"
link-option = "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc -headerpad_max_install_names"

[dependencies]
cjgui = { path = "${CJGUI_ROOT}" }

[ffi.c]
cjgui_internal_renderer = { path = "./.cjgui/native/lib" }
cjgui_macos_application_launcher = { path = "./.cjgui/native/lib" }
```

`cjgui_macos_app.sh` 是打包配置而不是 native 实现。`CJGUI_APP_DIR` 和 `CJGUI_RUNTIME_DIR` 由 runner 在读取它前设置；资源声明的文件会复制到 bundle 的 `Contents/Resources`。

```zsh
CJGUI_MACOS_APP_BUNDLE_NAME='MyCjguiApp'
CJGUI_MACOS_APP_EXECUTABLE_NAME='MyCjguiApp'
CJGUI_MACOS_APP_IDENTIFIER='org.example.my-cjgui-app'
CJGUI_MACOS_APP_DISPLAY_NAME='My CJGUI App'
CJGUI_MACOS_APP_RESOURCES=(
  "$CJGUI_APP_DIR/assets/status.png"
)
```

`run.sh` 保持为薄包装；它不编译 Objective-C、不复制 runtime dylib、也不调用 `codesign`。

```zsh
#!/usr/bin/env zsh
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
exec zsh "$CJGUI_ROOT/scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" "$@"
```

`run_macos_application.sh` 不内嵌任何作者机器目录。正常入口使用调用者已经选择的
`CANGJIE_HOME`，并将默认选择严格校验为 1.1.3；这既不相信随意的 `PATH`，也不覆写
用户全局 shell。一次性试用另一套工具链时才显式设置 `CJGUI_CANGJIE_HOME`，runner 会打印
实际 home 与 `cjc` 版本。它仍使用 `xcrun` 选择当前 macOS SDK：

```zsh
export CANGJIE_HOME=/absolute/path/to/cangjie-1.1.3
export CJGUI_ROOT=/absolute/path/to/cjgui
zsh /absolute/path/to/my-app/run.sh --build-only
```

未选择工具链时，runner 明确失败并要求设置上述其中一个变量；不猜测作者目录。显式 override
不会改变机器全局工具链，也不保证与本项目 `cjc-version = "1.1.3"` manifests 兼容。

需要复现旧工具链时，调用者仍可在自己的进程设置
`CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`；runner 优先尊重该显式覆盖，
不会修改系统 `MacOSX.sdk` 链接。

runner 需要 Python 3.11+ 的标准库 tomllib，以普通 `cjpm build --skip-script -i -V` 构建。AppKit/Metal sidecar 与 framework launcher 只生成到本应用 `.cjgui/native/lib`，不再写入或消费 framework 的共享 `native/lib`。fingerprint 包含全部 native source/header 的 SHA-256、clang/ar 二进制与版本、SDK settings 身份和实际编译选项；另核对 archive 内容哈希，SDK/宏/源或缓存内容变化都会触发正确重建与重新链接。普通构建默认用 `xcrun` SDK；显式 `CJ_GUI_SDKROOT` / `CJGUI_NATIVE_CLANG_FLAGS_APPEND` 仍参与身份，不把 testing 产物当普通产物。

cjpm 要求源码在模块目录内且为普通文件，既不接受模块外 src-dir，也忽略源码软链接。runner 因而在 `.cjgui/macos-build` 复用一份只读的 production `.cj` 构建输入快照及两份标准 cjpm manifest：原字段、profile 和 path 依赖保留，FFI 指向已核准的本应用库。这里只复制本次编译源码，不复制整仓、target、native、资源或历史，也不产生可编辑的第二套框架；按内容复用并按索引移除退役源。原源码仍是唯一修改入口。实际输出复用本应用 `target`，没有编译器包装或私有重链。原生 hook 已由 runner 完成，所以跳过冗余 build.cj，也支持含空格目录。

`.cjgui/macos-build/build-provenance.json` 保留原源／实际快照哈希、生成配置、归档身份和 linker 实际选择。验证读取 `-t` 的 archive/member 原始路径与 link map，再核对归档哈希；不以复制前 hash 或一个导出符号替代消费证明。输入或库在构建中变化会拒绝发布；只有同一 build key 和同一已验 executable 才复用旧链接证据。当前 App 在所有构建、消费核对、rpath 与签名步骤成功后才替换，失败保留上个 App。

同一应用的普通／显式 testing 构建仍由既有应用锁串行。框架根的普通 `cjpm build` 使用 `native/lib`。以下内部测试命令供完整源码仓使用，开发包不携带内部测试矩阵：

```sh
python3 native/scripts/verify_cjpm_mac_testing_link.py \
  --filter coarseWheelHandsOffToAncestorOnlyWhenInnerViewportCannotMove
```

该入口复用同一四成员 native 构建脚本的 `--testing` 模式，将测试库固定到 `native/testing/lib`，在一份受控输入图中生成普通 cjpm 配置并核实际链接来源。默认 finally 退休测试 target／输入快照，保留日志、精确源码和库身份；`--output` 可指定一个重复使用的证据目录。已经链接的选择用 `--skip-build` 执行，不为每个过滤项再构建。需要诊断时显式加 `--keep-build`，完成后回收该自有工作图。普通缓存与测试缓存互不替换；给生产 sidecar 追加 testing 宏会明确拒绝。

窗口 native 夹具沿用 `native/scripts/verify_composable_geometry_progress.sh` 的实际 AppKit／pump 入口，并链接同一明确 testing archive。裸 Cangjie 单元运行器的窗口生命周期问题单独保留，不用应用 launcher 替换其运行器后冒充通过，也不放宽生产 start／提交契约。相同 cjpm target 的 build/test 仍须串行，其他平台入口未扩验。

模板的应用测试也保留在该输入快照中。先 `./run.sh --build-only`，再在 `.cjgui/macos-build/application` 运行标准 `cjpm test --skip-script`（可加原 `--filter`）；使用同一目标，须等待前一构建/测试结束。若测试明确需要 native testing 宏，先以 `CJGUI_NATIVE_CLANG_FLAGS_APPEND` 显式运行普通入口，宏、SDK及实际库会被重新核准。开发预览不携带框架内部测试矩阵。

每次构建会先打印一行 `source_origin`（runtime、native、两项 path dependency）及每项
`resource_origin`。它们是这次构建实际使用来源的可审计记录，不是发布证明。`CJGUI_NATIVE_SOURCE_DIR`
仍是开发者的显式 native source 覆盖；要证明导出预览没有意外继承工作区，消费者应在该次命令清除
`CJGUI_NATIVE_SOURCE_DIR`，并断言这两类日志都指向预览目录，而不是禁用这个正常调试能力。

bundle 先在本应用 `.cjgui/bundle-staging/` 完整复制 executable、当前声明的 resources 和 runtime、完成 rpath/ad-hoc 签名，再原子替换 `target/release/*.app`；失败保留上一份 bundle。每个应用有自己的短时 build lock：同一应用不会互相观察半成品，不同应用仍可并行。声明删掉或改名的 resource、旧 executable 不会留在新 bundle 中。`CJGUI_USE_LAUNCH_SERVICES=1` 会以 `open -W … --args` 保留正常应用参数（例如有限测量运行）。这只证明本机 bundle 可运行，绝不是安装、公证或发布。

图片的相对路径会先解析为当前 cwd 的实际文件，否则从 `NSBundle.mainBundle.resourcePath` 解析。正常 bundle 应传 resource 的 bundle basename（例如 `"status.png"`），并从不同 cwd 启动验证；不要让 cwd 恰好存在同名开发文件掩盖 bundle 缺失。

## 创建与本地源码预览

拿到开发包时先读包根README；源码仓的分发入口与包外前置见[开发预览快速开始](preview/MACOS_DEVELOPER_QUICKSTART.md)。`mixed-form` 是TEXT／INTEGER／BOOLEAN共用owner的手写／生成打印预设，[接入说明](templates/macos_application/mixed_form/README.md)提供完整创建与客户端命令。默认不开连接。

多视图表单沿用 FormBinding / GeneratedUiWindowRegion 的接受与范围输入路径。
控制器将手写和生成字段的 FOCUS 一并委派给 region，owner 为每个字段提供其实际
`draftFieldVersion`；其它字段或 Apply 的事务版本变化不应冒充该 TEXT 的新输入基线。
外部写入由同一 owner 泵送并触发正常窗口刷新，应用无需轮询/换焦点刷新。
全值写入的选区继续服从既有 source 政策，详见模板说明；不新增隐式 rebase。

框架随附四种最小 `cjpm` 骨架，而不是复制 example 或 renderer：`ui-only` 只包含本地 controller；可选的 `command-surface` 在同一 controller 上增加命令工具栏、上下文菜单、共用声明投影与只读 Inspector 接入，默认不启用时仍使用 `ui-only`；`collaboration` 额外包含一个独立领域、动态组件、资源、校验和可选的 descriptor-gated shared-operation connection。后者把当前任务的 `title` 和提交状态 `isMarked` 放在同一条 shared-operation resource：文本输入直接走 `SET_TITLE`，提交边界才检查空白并走同一资源的 `SET_MARKED`。外部获得授权后也只能发现并调用这些领域动作；controller 不保留第二份 draft、计数或状态。输入允许暂时清空，不能把每次删除误当成提交失败。

```zsh
export CANGJIE_HOME=/absolute/path/to/cangjie-1.1.3
zsh "$CJGUI_ROOT/scripts/create_macos_application.sh" ui-only /tmp/MyUiApp
zsh "$CJGUI_ROOT/scripts/create_macos_application.sh" command-surface /tmp/MyCommandApp
zsh "$CJGUI_ROOT/scripts/create_macos_application.sh" collaboration /tmp/MyCollaborationApp
zsh /tmp/MyUiApp/run.sh --build-only
```

要检验可迁移消费而非当前工作区偶然可用，可导出源码预览。导出物只含 buildable framework/core 源、必要 native source/资源、normal runner、模板与可选通用公开 client；`--profile macos-dev` 不含 examples、框架 tests、probes、target、workspace cache 或用户数据；默认 full 继续携带原有可选消费者及其源码测试。它是实验性源码预览，不是发布 SDK 或 ABI 承诺。

```zsh
zsh "$CJGUI_ROOT/scripts/export_framework_preview.sh" "/tmp/CJGUI Framework Preview" --profile macos-dev
PREVIEW="/tmp/CJGUI Framework Preview/framework/cjgui"
zsh "$PREVIEW/scripts/create_macos_application.sh" collaboration "/tmp/My Preview App" --framework "$PREVIEW"
zsh "/tmp/My Preview App/run.sh" --build-only
```

`preview-manifest.md` 保留来源、适用许可证说明与排除项。预览里的 `client.py` 只是 descriptor-gated 的通用本地协议 client；它不构成 Agent 或模型调用。真实模型接入仍必须自行发现对象、动作及参数、执行授权动作并读回，不能把固定脚本成功说成模型接入。

分发验收从最终包的新解压根创建应用，检查相对依赖、`source_origin`、`resource_origin` 和源码清单。新包本就不携带缓存；已有同源正常操作证据可复用，无须为每次导出再移动目录、清缓存或重跑旧长链。

## 仓颉入口

应用的 controller 继续实现 `CjguiComposableUiController`。宿主创建 window，应用只能取回这个仓颉投影对象用于绑定语义命令或组装可选 connection；没有 session token 或 AppKit 对象可取得。

```cangjie
let host = CjguiMacosApplicationHost(
    MyController(domain),
    configuration: CjguiMacosApplicationWindowConfiguration("My CJGUI App", 760u32, 500u32)
)
let window = host.window()

// 可选：应用仍拥有 domain、authorization 与 connection 的定义。
let connection = CjguiSharedOperationExternalConnection(domain, authorization, domain, window)
if (!host.attachExternalConnection(connection) || !host.start()) {
    host.close()
    return 1
}
while (host.isOpen()) {
    let _ = host.pumpOneTurn()
}
host.close()
```

配置的 `title` 是窗口标题 owner：初始首帧与后续业务 refresh 都保持它，场景提交不改写成 framework 固定文案。若应用要请求关闭而非无条件 teardown，可调用 `host.requestClose()`；它走 controller 的 `requestWindowClose()` 决策，拒绝时 Host 仍可继续 pump，批准时收敛到 normal close。`close()` 已幂等，并关闭 window、可选 connection 和 AppKit loop；一个关闭后的 Host 不支持原地 reopen，重开应构造新的 Host/connection，并只交付新 descriptor。若参数解析或领域初始化在尚未创建 `host` 前失败，调用 `CjguiMacosApplicationHost.stopApplicationLoop()` 后返回非零。不要自行声明 old `finish` foreign 函数，也不要另写 sleep/accept 事件循环。

## AppKit 访问必须在主线程

宿主把仓颉入口放在**工作线程**运行，AppKit 的窗口与视图操作只能在**主线程**执行。
从工作线程直接改窗口状态（例如设置 `NSWindow.appearance` 以让标题栏跟随主题）会让进程在
AppKit 内部断言失败：崩溃报告写明 `Must only be used from the main thread`，栈经
`NSView setAppearance:` 与 `NSWindow _windowDidChangeAppearance`。

处置方式：应用侧的 native helper 把这类调用 `dispatch_async(dispatch_get_main_queue(), …)` 到主线程
再执行，并在主线程内读回状态确认（例如 `window.effectiveAppearance`）。
CJGUI 已对部分接口做了主线程转发（见窗口标题接口）；新增任何触碰 AppKit 的能力时应沿用同一约定，
或在宿主侧提供通用的"主线程执行"入口。

## 最小授权外部操作

外部 connection 不是第二份应用状态：先选择一个真实
`CjguiSharedOperationDomain` 作为业务 owner，再从可信入口得到 caller 与一次
授权的 capability。下面的最小例子复用 core 提供的
`CjguiSharedOperationList`，其 `version()` 是 controller 的 UI revision 的一部
分；因此外部 `SET_TITLE` 或 `SET_MARKED` 成功后，下一次宿主 turn 会投影同一个 domain 的新
内容和状态。生产应用应由登录、用户批准或其他业务 ingress 生成 capability，不能把
示例值当作通用凭据。

```cangjie
import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

let targetId: Int64 = 4101
let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
    CjguiSharedOperationRecord(targetId, "外部可标记项目", false)
]))

// 这只是可重复的本机 demo 值，不是凭据。生产应用必须改为由可信
// ingress 在本次授权时提供的 opaque capability，且只通过私有 descriptor 交付。
let capabilityFromTrustedIngress = "demo-only-authorized-local-capability"
let authorization = CjguiSharedOperationExternalAuthorization(
    "local-dashboard-agent", capabilityFromTrustedIngress,
    ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
        CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
        CjguiSharedOperationExternalActionScope("SET_TITLE", ArrayList<Int64>([targetId]), false),
        CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([targetId]), false)
    ])
)
let host = CjguiMacosApplicationHost(
    DashboardController(domain),
    configuration: CjguiMacosApplicationWindowConfiguration("Dashboard", 820u32, 560u32)
)
let window = host.window()
let connection = CjguiSharedOperationExternalConnection(domain, authorization, window)
if (!connection.enableWindowProgressReads(window) ||
    !host.attachExternalConnection(connection) || !host.start()) {
    host.close()
    return 1
}
if (let Some(info) <- connection.connectionInfo()) {
    getStdOut().writeln("CJGUI_DASHBOARD_READY DESCRIPTOR_PATH ${info.descriptorPath}")
    getStdOut().flush()
}
while (host.isOpen()) {
    let _ = host.pumpOneTurn()
}
host.close()
```

`DashboardController` 读取 `domain.snapshot()` 以构造文本/按钮，并让
`uiSceneVersion()` 包含 `domain.version()`（可再加自己的本地 revision）。这样人
侧动作和外部动作都只改变同一个 domain；不要因为 connection 存在而复制一份
`title`、`isMarked` 或版本字段。`CjguiSharedOperationExternalConnection` 的第三个参数是
window 的只读投影 provider，不是 native handle。

组件的 `semanticId`（例如 `"dashboard-domain-status"`）必须稳定；动态文字放在
`cjguiComposableText` 的第三个 `value` 参数。把显示文字塞进 `semanticId` 或把
动态值留空，会破坏稳定身份，也不能作为“领域变化已投影”的证据。

若 connection 要发布 window projection，所有组件 `semanticId`、field/action/layer
标识都必须是 ASCII token：以字母或 `_` 开头，其余只用字母、数字、`_`、`-`，例如
`"dashboard-add-item"`。显示用的空格、CJK 或动态文本必须放在 label/value；不安全
标识会让投影 fail closed，公开 `GET_CONTEXT` 不会返回部分树。

组合树时使用 `container.add(child)`。`children()` 返回的是防御性副本，仅可用于
读取；在 `children().add(...)` 上添加节点不会改变 container，也就不会构造出
预期的列表、输入框或动态文本。

启动成功后只把输出的 `DESCRIPTOR_PATH` 交给已授权本地调用方。公开客户端先
动态发现 action/target，再调用，不猜测 socket 或 capability：

```sh
python3 "$CJGUI_ROOT/shared_operation_core/client.py" "$DESCRIPTOR" describe
python3 "$CJGUI_ROOT/shared_operation_core/client.py" "$DESCRIPTOR" get
python3 "$CJGUI_ROOT/shared_operation_core/client.py" "$DESCRIPTOR" invoke VERSION SET_MARKED \
  --target 4101 --arg isMarked=BOOLEAN:true
```

同一旧 `VERSION` 重复调用应得到 exit status `4` 和 `version_conflict`；未声明的
action 或未授予的 target 应得到 exit status `5`。关闭 host 后 descriptor 与
socket 失效；重开必须只使用应用新发出的 descriptor。完整客户端退出码、descriptor
隐私与发现格式见 [shared-operation client README](shared_operation_core/README.md)。

## 按工作就绪等待（experimental）

普通主循环可使用 `host.pumpUntilWork(timeoutMs: UInt32.Max)`；多窗口的
`CjguiMacosApplication` 使用 `application.pumpUntilWork(turnBudgetMs: 16u32,
timeoutMs: UInt32.Max)`。沿用同一 owner 线程、事件队列、窗口注册及关闭路径。
旧 `pumpOneTurn` 仍保留有界等待，已有消费者无需迁移。

`turnBudgetMs` 是一轮 owner 工作的协作预算；`timeoutMs` 限制空闲等待，不能抢占
已开始的原子业务操作。`UInt32.Max` 表示没有调用者等待期限。真实动画、惯性、待完成
场景或焦点工作仍按原有活动周期推进；外部请求、原生输入、文字／图片完成和关闭
使用既有工作 revision 唤醒。应用不要另加轮询、sleep 或 worker 上的 owner 执行。
多窗口共用一次等待，任一存活窗口就绪均可唤醒它。

macOS 的 drawable 获取使用每个 view 自有的串行队列和既有单个在途 slot；
一个窗口的 `nextDrawable` 等待不会占住其他窗口的获取队列。取消、尺寸／代次变化
和关闭仍由原 slot 与 lease 校验结算，迟到结果不能重新激活窗口。资源完成唤醒
owner 后，宿主在原无刷新事件泵的尾部消费该窗口的 deferred work，再返回调用者；
这不新增事件泵，也不改变业务 FIFO。此处证明的是获取隔离与就绪刷新，
不代表所有窗口的完整反馈已达到 16/32ms。

宿主为 `CjguiSharedOperationExternalConnection.ensureOwnerWorkNotifier` 安装一次
静态通知入口。通知仅提示原队列有工作，可以合并；完成、拒绝、超时和关闭仍由原
请求生命周期决定。原生内部 ABI `CJGUI_OWNER_IDLE_WAIT_VERSION=1` 在原 condition 上
增加 `owner_wait_idle_work`：支持绝对期限／无期限、工作提前到达和关闭唤醒；旧
`owner_wait_work` 的 16ms 上界不变。原生通知不持有窗口指针。该 ABI 需与同版
`owner_turn_budget.cj`、宿主和 renderer 配套编译，不能单独替换 transport。

本段交付验证范围为 macOS；其他平台的专用宿主和通知适配需各自验收，不能以共同
声明存在声称已支持。普通单行字段的方向键、扩选和删除由现有 AppKit adapter 在
当前回调完成，选区及精确编辑范围仍进入原 owner 队列；多行／呈现正文沿用安装源票据。

## 验证边界

至少分别做一次 fresh build、无变化的 incremental build，以及从另一个 cwd 的普通启动。应用启动时应确认 `WINDOW_READY`（如应用输出该观测）和真实首帧；有外部 connection 时再用公开 descriptor/client 验证授权、读回、失败启动和 close 后 endpoint 清理。测量普通窗口时复用 `examples/window_perf_baseline.py` 的 app-emitted ready、5 秒预热和不少于 60 秒采样；它不替代物理 IME、人眼像素、安装、公证、发布或多平台验收。
