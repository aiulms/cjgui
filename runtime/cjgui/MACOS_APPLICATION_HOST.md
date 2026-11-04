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

如需显式比较仓颉优化级别，可在应用自己的 `cjpm.toml` 的 `[package]` 中设置 `override-compile-option = "-O2"`，再从普通 `run.sh --build-only` 构建。该选项覆盖源码依赖的编译选项，使用前要核对依赖已有的必要选项；不设置时沿用工具链默认值。runner 会保留此设置，并将应用及本地依赖的清单和源码纳入构建身份。用构建日志中 `cjpm -V` 打印的每个参与包的实际 `cjc` 命令核对选项：只看到应用一条不足以证明依赖也使用了该级别。原生 clang 的编译选项另有独立 fingerprint。

比较不同优化级别时，为每个配置使用独立的自有应用和 `target`，或在保全所需产物后只退役该应用自有 `target` 再构建；同一 target 的构建必须串行。runner 在写入构建快照前检查最后一次已验证的编译配置与最近一次准备的配置，配置变化或非空 target 身份未知时会拒绝继续，并保留已有产物。旧记录若没有显式编译配置，即使原始清单哈希相同也不能证明依赖对象的优化级别；迁移时须先保全所需产物，再准确退役该应用自有 target 或使用独立应用目录重新构建。测试专用图也拒绝复用无显式配置的旧对象。跨配置构建失败后，即使切回原配置，部分对象也可能来自失败的尝试，同样须先准确清理或使用独立目录。同配置下的源码修改仍可增量构建。build key 改变会使旧链接证据失效，但本入口不把它当成增量依赖对象全部重编的证明。优化构建的正确性、构建成本与运行收益需由对应应用验证；这里不改变默认级别。

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

### 系统文本编辑与应用命令

普通可编辑 TEXT 字段和范围文档沿现有 TextKit 输入代理处理 ⌘A、Shift＋方向键扩选、
⌘C／⌘X／⌘V。手写字段使用 FormBinding，生成字段使用 GeneratedUiWindowRegion 的
同一 owner／字段绑定；应用无需另存一份剪贴板正文、选区或编辑状态。复制不提交正文；
剪切和粘贴经原编辑路径提交，是否允许写入仍由当前字段与 owner 决定。

快捷键、系统 Edit 和上下文菜单继续消费应用的真实命令声明与完成协议。
应用显式声明的 ⌘Z 优先于原生 fallback，一次按键只交给一个处理者。
Undo／Redo 的历史归应用已接入的权威 owner；接入普通字段不等于自动获得业务撤销。
`mixed-form` 的 Apply／Cancel 属于业务草稿，另有可选的界面文档历史；两者都不能当作
正文 Undo 栈。完整源码仓的[共享文档样例](examples/shared_document_window_app/README.md)
展示已有 workspace 历史的 ⌘Z／⇧⌘Z、保存与关闭。

同一字段的兼容生成重排沿稳定 key、owner 与字段身份保留选区和输入绑定；改变 owner
后必须消费新接受的绑定，旧 owner 或退休目标不能转投到新对象。外部操作走已有授权字段、
范围或命令入口，成功后从实际 owner 读回，再继续原生输入。不要通过重新聚焦、重放按键
或应用维护的旧正文修补版本冲突。全值写入后的选区仍按各入口已声明的政策处理。

范围文档的 READ_RANGE 与 REPLACE_RANGE 使用目标正文的 `documentVersion` 和 UTF-8
字节范围；GET_CONTEXT 的聚合 VERSION 可因选区变化单独推进，不能替代正文版本。
窗口交互观察中的选区使用 UTF-16，必须按对应正文转换。表单继续使用其字段／草稿版本
和已接受的范围票据，不能把不同 owner 的版本互换。冲突、只读、不可用或退休拒绝后，
应重新读取实际目标及原因，由调用者决定下一次操作，不能自动重投编辑动作。

系统剪贴板由本地用户的系统编辑动作使用。可选 shared-operation connection 只开放
应用已授权的资源和动作，默认不授予外部读取或写入系统剪贴板的权限。

数据传输声明绑定按当前候选场景的一份节点快照扫描；空声明直接返回空绑定。
声明的语义目标、可用性、只读状态、格式、重复绑定及 epoch 继续逐项校验，
应用无需缓存场景或维护另一份节点索引。场景节点快照的公开副本契约保持不变。

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

<a id="business-work-sessions"></a>
## 可选业务工作会话（Experimental）

`CjguiComposableUiWorkSession(path, schema, maximumBytes, validatePayload)` 为应用选择的业务载荷提供
`load()`、`save(payload)`、`isDirty(payload)`。结果的 `ok/reason/payload` 分别表示是否完成、拒绝原因和
完整校验后的载荷；只有成功载入或保存才更新持久基线。应用负责稳定 owner 身份、已应用值、未应用草稿、
必要版本/选择的格式和恢复规则。界面结构文档与业务会话独立，载入不隐式 Apply。

保存先检查完整 envelope 字节预算，再调用应用校验器和编码；载入有界读取，并在同一次完整 schema/业务校验
通过后采信文件基线。复用 `CjguiTextDocumentFileBinding` 的协作文件锁、原字节复查和同目录原子发布；
检测到外部改写、损坏或不兼容 schema、超限和 I/O 失败时拒绝，保留旧文件及当前业务工作。
这沿用既有文件绑定的并发边界，不是对不配合写者的文件系统原子 CAS。格式带长度/UTF-8/schema 校验，
没有校验和或篡改认证。校验回调应为纯校验；一个 session 由应用的同一工作 owner 顺序使用。

框架不解释业务字段，也不保存 native 窗口、端点、票据或输入法会话。新进程先恢复应用允许的业务状态，
再正常创建宿主和新的对外身份；未启用的应用不增加文件或连接要求。

- [mixed-form](templates/macos_application/mixed_form/README.md)：显式 `--work-session PATH`，只保留卡片 A/B，
  草稿与已应用值分别恢复，正常菜单/工作区/关闭入口保存，人和公共客户端可继续操作。
- [UI-only](templates/macos_application/ui_only/WORK_SESSION.md)：同一接口保存应用自定义的注释、计数和业务版本，
  不启用公共 endpoint；无参数保留原入口与关闭行为。

该 API 当前为 Experimental，实际消费范围为 macOS；其他平台未由本轮验证。已有构造/方法签名保持，
文件 schema 由应用显式版本化，不承诺替应用迁移未来 schema。

### 多个关闭检查的衔接

`CjguiUiDocumentCloseGuard.discardUnsaved()` 把放弃许可绑定到各 workspace 的表面身份、已接受版本/摘要及保存基线。
`settleAndReport()` 保留原有一次消费语义；`inspectAndReport()` 为应用级多窗口探测提供不消费的检查，仍结算并拒绝 pending/mismatch。
`cancelDiscard()` 显式撤销许可。应用在取消、保存失败或关闭意图结束时负责清理；内容或关联版本改变时旧许可自动失效。
混合消费者把业务许可绑定到自己的完整载荷，使用已有应用退出 provider 协调参与窗口，不在框架内引入业务状态机。
这些 API 为 Experimental，不表示宿主 deferred close 前任意迟到事件已取得新的运行验收。

### 退出与命令可用性扩展（Experimental）

本包新增的三个可选消费接口均按 Experimental 对外说明；它们不是稳定 ABI 承诺，也不暴露 native handle：

```cj
public interface CjguiMacosApplicationExitDecisionLifecycle {
    func applicationExitDidCommit(): Unit
    func applicationExitDidCancel(): Unit
}

public interface CjguiComposableUiWindowCloseLifecycle {
    func windowCloseDidCommit(): Unit
}

public interface CjguiComposableUiCurrentCommandAvailabilityProvider {
    func currentCommandAvailability(commandId: String,
        target: CjguiComposableUiLayoutNode): ?Bool
}
```

退出仍经过原有 Bool 请求／业务许可边界。`CjguiMacosApplication.requestApplicationExit(): Bool` 表示提出或推进退出意图；
`CjguiMacosApplicationExitDecisionProvider.requestApplicationExit(): Bool` 是应用给该意图的许可。任一都不表示窗口已经关闭。
宿主重新核对参与窗口身份、场景／owner 版本与原生 preflight，再调用 native batch commit；只有该共同提交成功后，
才通知 `applicationExitDidCommit()` 并退休窗口。应用拒绝许可时所有窗口与 connection 保持打开，当前意图结束，之后可发起新请求；
preflight 尚未就绪或 native batch commit 失败时，宿主不逐窗退休或提前关闭 connection，仍保留待处理意图以便重试。
`applicationExitDidCancel()` 由显式 `cancelPendingApplicationExit()` 通知，应用可借此撤回此前暂存的窗口许可。

单窗 `CjguiComposableUiController.requestWindowClose(): CjguiComposableUiDispatchResult` 也保持请求语义；
`shouldClose` 许可不是 native 关闭完成。只有原生逻辑关闭提交后才调用该窗口 controller 的
`windowCloseDidCommit()`。Mixed consumer 将 per-window 许可保留到这一接缝；应用级许可则由
`CjguiMacosApplicationExitDecisionLifecycle` 在实际 batch commit／显式取消时清理。

当前命令可用性只补充同一已接受场景中原先声明的命令。只有 controller 版本已变化、目标仍是可接收输入且非只读的
accepted node 时才查询 provider；provider 收到原始 `commandId` 与已接受目标，必须确认它仍映射到同一 owner 和 action，
不能把输入转发到新 owner。返回 `Some(true/false)` 提供当前可用性；返回 `None` 保留原声明的
`isEnabled && canReceiveInput()` 判据。它不创建命令或重定向目标；accepted-scene target 与只读门仍由框架校验，
应用必须在 owner/action 映射退休或改变时返回不可用，不能借此复活旧绑定。

实际消费在 [mixed-form](templates/macos_application/mixed_form/README.md)：`MixedApplicationExitDecision`
实现应用退出许可与生命周期，`MixedFormController` 实现窗口关闭生命周期和当前命令可用性。后者只处理
`preset.APPLY_DRAFT`／`preset.CANCEL_DRAFT`，检查 accepted node、action 与当前卡片 owner；隐藏工作区、帮助页、
owner 不匹配或动作不可用时拒绝，未知命令返回 `None`。宿主现有 Bool 入口和普通关闭路径保持兼容。

单窗口应用可用同一业务 controller 显式启用 Host 退出许可，并把“用户在守卫中选择继续”接回既有 Host：

```cj
let host = CjguiMacosApplicationHost(controller,
    configuration: CjguiMacosApplicationWindowConfiguration.standard(),
    exitDecisionProvider: Some(controller))
controller.bindHostContinuations(
    { => host.requestApplicationExit() },
    { => host.cancelPendingApplicationExit() },
    { => host.requestClose() })
```

`requestApplicationExit()` 的 `Bool` 是消费方许可，不代表原生 Quit 已提交。业务守卫返回 `false` 后，Host 保持
窗口和 connection 可用；应用可以显示保存、放弃、取消。取消调用 `cancelPendingApplicationExit()`，由已有
`applicationExitDidCancel()` 清理此退出意图。保存成功或用户明确放弃后，应用用已绑定的 continuation 请求 Host
继续当前业务意图；这不是重新投递 Cmd-Q，也不是另一条绕过窗口/owner preflight 的关闭路径。只在应用已实际提交
native 退出后，Host 才调用 `applicationExitDidCommit()`。

窗口级 `CLOSE` 与应用级 Quit 必须分开：单窗口 app 可在原输入 pump 完成后调用 `host.requestClose()`，让 Host
通过 controller 的 `requestWindowClose()` 运行相同的未保存策略；CLOSE handler 不能直接返回 `shouldClose: true`。
`host.requestClose()` 返回 true 只表示本地请求已接收。它不会把局部窗口请求升级成应用级退出；应用退出也不会替
其他 app 或用户进程作决定。多窗口应用仍需由自己的 provider 评估全部参与窗口，不能把单窗口 controller 直接当作
全局业务裁决器。

本轮证据范围：退出决策 testing ABI 目标的 5 个定向用例、shared-core socket reservation 的 2 个用例，
以及独立 native production-source fixture 均有各自结果；testing ABI 不代表 HID。Mixed normal consumer
结果证明指定输入／双窗关闭链、保存与 endpoint 清理，不证明 VoiceOver、16/32ms 性能或资源循环验收。
direct window refresh 预算回归为 1 RED → 1 GREEN；normal 资源循环仍待验。逐项身份与范围见
[public-contract-review.json](artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/public-contract-review.json)。

## 验证边界

至少分别做一次 fresh build、无变化的 incremental build，以及从另一个 cwd 的普通启动。应用启动时应确认 `WINDOW_READY`（如应用输出该观测）和真实首帧；有外部 connection 时再用公开 descriptor/client 验证授权、读回、失败启动和 close 后 endpoint 清理。测量普通窗口时复用 `examples/window_perf_baseline.py` 的 app-emitted ready、5 秒预热和不少于 60 秒采样；它不替代物理 IME、人眼像素、安装、公证、发布或多平台验收。
