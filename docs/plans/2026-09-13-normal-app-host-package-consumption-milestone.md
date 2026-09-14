# 大阶段：通用应用宿主与正常包消费

日期2026-09-13；原执行任务01a08f82-b682-73c0-a9b0-25a27bc5ffd8，Terra/xhigh，原目录。指导只规划复核，实现由执行承担。

## 为什么做与完整结果

已有组件/布局、自绘与GPU完成反馈、文本输入、调度和低成本外部观察，至少被规则集/文档消费。现在普通应用仍依赖examples/shared_operation_window_app/native/macos_launcher.m，复制native编译/运行库/bundle/sign逻辑并声明foreign finish。此阶段把通用宿主和构建消费收进框架，使开发者用仓颉定义界面、状态、动作和可选外部接入即可运行，避免每个应用自管AppKit线程及FFI。

这是框架代码交付，不是发布包装或再做一个业务工具。完整成果：正式框架目录的共用macOS宿主与构建入口、清晰experimental应用API、两旧消费者迁移、一个按公开说明独立创建的不同布局消费者、正常冷构建/增量构建/启动关闭/资源与外部接续验证。

依据[设计导航](DESIGN_INTENT_INDEX.md)的正常包消费、平台桥接和输入主线；[传统避坑](../research/gui-framework-pitfalls-intelligence.md)第1/5/6节关于主线程生命周期、平台细节泄漏和API固化。六条主线已有运行证据但不代表成熟框架；优先降低正常消费难度，保留物理IME与文字复杂性欠项，下一候选为实际文本输入/无障碍完整性。保持仓颉核心、macOS、自绘/GPU、可选外部系统与编码可替换。

## 复用和代码范围

- 复用现有launcher主线程桥接、finish/退出清理、CjguiComposableUiWindow、TurnScheduler、controller与主题/资源能力；移动/提取通用实现到框架拥有的目录，不复制第二套事件循环。旧样例入口可留短兼容包装，不能仍作为新应用的隐含依赖。
- 提供最小可解释的应用宿主配置及运行入口：标题/尺寸/资源位置、controller、关闭决策和可选外部connection的组成。应用保有业务owner；宿主管主线程、安全创建、事件调度、部分启动失败清理、正常退出。原生句柄/平台对象不得泄露到公共仓颉API；应用不再需要自己声明foreign finish或知道launcher symbol。不要擅自扩为多窗口架构、导航产品或Agent壳。
- 共用构建/运行支持正常cjpm依赖与macOS本地bundle。由配置决定应用标识、资源与产物位置，SDK/工具链可显式选择；保留现有SDK15.4 workaround原因及明确失败，不硬编码用户HOME路径为唯一入口。build-only/运行参数明确分离。运行库依赖、本地临时签名和必要rpath统一处理，签名只表示本机可运行，不冒充公证/安装/发布。
- 修正目前每app复制native编译与打包的边界，可做有正确失效条件的复用；变更源码/header/SDK/编译选项后不能误用旧native产物。冷构建与无变化重建都能验证，不清空用户全局缓存，不重建worktree、不复制整个仓库。不为了模板加自制包管理器或治理平台。
- 迁移规则集和文档两个普通应用到同一宿主；它们的业务owner、授权、stream/版本、公开客户端、人侧交互及视觉行为保持。资源从bundle/配置正确定位，不依赖当前工作目录或样例绝对路径。输入框/动态列表/菜单/主题至少在消费者中继续真实消费。

## 独立开发者验收与性能

明确授权一个无实现上下文的Luna/Terra验收者，只给新的公开README和包位置，在同一仓库的隔离临时消费目录创建小型仓颉应用（不是worktree，也不复制已有应用或renderer/native源码）。自行选择不同布局，组合文字、输入、列表/按钮与状态动作；先纯GUI，再按文档启用最小授权外部操作。若公开能力不足回报缺口并由执行修正。此目录仅是消费证据，禁止对外发布。

验证它从不同cwd启动可加载字体/图片等资源；真实人侧改动、外部读取修改、冲突/权限失败、关闭重开/取消关闭/启动失败均保持正确。两旧应用也正常运行，不能只编译模板。AppKit必须走正常主线程入口；之前viewport单测去掉window.start的替代证据应在正常宿主运行中覆盖实际长列表窗口创建、首帧和关闭，不以纯映射单测代替native生命周期。

按当前性能基线复测受宿主改动影响的无连接/连接idle及一组混合正常负载，保持明确就绪与预热、产物指纹、采样条件。确认没有重复调度/忙等、每帧同步readback、资源重复加载或旧endpoint残留。只需相关对照，不机械全量重跑旧180秒三种读取模式。开发者构建耗时/增量行为也记录事实，不把代码行数减少当运行性能证明。

运行相关core/client/两领域与native宿主探针、root build --skip-script、两个迁移app和独立consumer冷构建/正常启动，检查公共API稳定性标签、native跨模块影响和diff。独立验收必须读公共文档并实际使用，不预填内部符号。旧API兼容/弃用边界说明清楚，不承诺稳定ABI。物理IME/安装/公证/发布/多平台继续未验，不为这些阻塞独立代码。

## 接续纪律

只在当前阶段简记设计选择、旧资产去向与结果，不新开执行卡。按AGENTS同一失败场景两次实际修复后Kimi Code CLI kimi-code/k3只读交流；两轮仍失败立即回报指导，次数跨阶段累计。原目录不stage/commit/push、不切分支、不清未知进程。锁屏跳过具体桌面验收并继续独立实现/构建。完成全部代码、两消费者迁移、公开独立消费与相关性能验证后回报指导01a08f0f-e1ce-71c1-9a6e-4eee08308d61；实质阻塞可提前升级。

## 交付区

- 框架新增 experimental `CjguiMacosApplicationHost` 与标量
  `CjguiMacosApplicationWindowConfiguration`。host 只拥有一个
  `CjguiComposableUiWindow`、现有 TurnScheduler、可选 connection 和幂等 close；
  controller/domain 仍由应用拥有，公共仓颉 API 不暴露 AppKit、Metal 或 session
  token。正常 AppKit main-thread 入口移至 framework-native
  `cjgui_macos_application_launcher.m`，不再由普通应用 foreign 调用 finish。
- `scripts/run_macos_application.sh` 统一本地 sidecar/launcher fingerprint、`cjpm -i`
  构建、bundle resource、runtime dylib/rpath 和 ad-hoc 签名；SDK15.4 必须显式可用。
  规则集与共享文档仅保留薄 `run.sh`、bundle config 和应用自己的依赖声明；旧
  shared-operation example launcher、每应用 native 编译/Info.plist/foreign finish
  已不再是它们的依赖。无变化重建约 0.33–0.35s；source+native fresh 独立消费者
  build 为 12.92s。
- TDD 先以未声明 host 类型的 `macos_application_host_test.cj` 失败，再覆盖配置
  拒绝、启动失败清理、正常退出只 close 一次。最终 root 7/7、core 37/37、Python
  client 18/18、root `cjpm build --skip-script` 和
  `verify_macos_application_host_runner.sh` 通过；`git diff --check` 通过。既有
  `chmod` 与 `allowedFileTypes` deprecation warnings 仍存在，未伪称为本阶段新警告。
- 两迁移应用均从正常 bundle 路径创建实际 AppKit/Metal 窗口并完成首帧/readback；
  规则集的公开写入 exit 0、旧版本冲突 exit 4、应用有限运行 exit 0。文档无连接、
  文档连接、规则连接 idle 与文档编辑四个 2s cycle 均在明确 `WINDOW_READY` 和
  `MEASUREMENT_START` 后采样并 exit 0；报告
  `/tmp/cjgui-macos-application-host-perf.json` 的 SHA-256 为
  `164a8e8c13fc42352900804a4802e4d89d4e2b1a977f26b7af67b71845407147`。
- 无实现上下文的 Luna 独立消费者只读 `MACOS_APPLICATION_HOST.md`、root README
  和 linked public client README，在
  `runtime/cjgui/independent_consumer_tmp_20260913` 创建两栏文字/输入/按钮/
  状态 Dashboard。其首次 external 文档缺口促成最小 public connection 示例；
  后续还明确了 stable ASCII `semanticId`、动态 value 与 `container.add`（`children()`
  仅返回副本）。从 `/private/tmp` 运行当前 bundle 后，动态发现 GET_CONTEXT /
  GET_WINDOW_PROGRESS / SET_MARKED 与 target 4101；写入 exit 0、旧版本 conflict
  exit 4、未授权 target/action 都 exit 5、读回 version 1，并由 wait-window
  确认 scene/submission/frame 1→2。该目录仅为本地消费证据，未发布。
- 已如实保留未验边界：锁屏使 CUA 不能读取 AX 树或执行物理鼠标/键盘，因此未把
  SIGINT/TERM 当作正常人侧关闭；物理 IME、人眼呈现、窗口取消关闭、安装、公证、
  发布、多平台与稳定 ABI 未验。

### 复核收口结果（2026-09-13）

- `run_macos_application.sh` 的 native key 现为 `format=2`：逐项 SHA-256 覆盖
  renderer/bridge/launcher 源码和 headers、clang/ar 的路径、二进制和版本、显式
  clang flags 与 SDK 身份。保留 mtime 的 header 内容改动、显式 `-D` 改动都会
  重编；无改动会复用。故意使归档编译失败时，已发布 fingerprint 和 linked
  fingerprint 不变；成功后才强制该应用的 `cjpm -i` 重链，并由 `nm` 证明 renderer
  symbol 在可执行文件中。锁只在 `<app>/.cjgui` 内，同应用两进程得到一次 rebuild
  和一次 reuse，未残留 lock/staging；不同应用不共享锁。
- bundle 在 app-local staging 完成 executable、受配置约束的 resources、runtime、rpath
  和 ad-hoc signature 后才替换旧包。用临时配置实际验证：缺资源失败时旧 bundle 的
  manifest 和签名保持；改 executable 和 resource 清单成功后，旧 executable/resource
  不在新 bundle。`CJGUI_USE_LAUNCH_SERVICES=1` 已使用 `open -W ... --args`；规则集
  的 10 秒有限运行实测收到参数并以 0 退出。
- renderer 的 scene commit 不再覆写窗口标题。WindowServer 实测规则集标题在首帧和
  外部业务写入后的 frame 2 都是“CJGUI 规则集编辑器”；共享文档首帧为
  “CJGUI Shared Document”。独立消费者从 `/private/tmp` 启动时，实际由 bundle
  加载 `composable-beacon.png`，而非当前工作目录中的同名文件。
- 删除了未被生产 Host 使用的 `CjguiMacosApplicationRunner` / fake turn-source 生命周期
  测试。真实正常 bundle 探针覆盖了“窗口成功但 connection 启动失败”的幂等清理；规则集
  探针覆盖未保存内容拒绝 close 后仍可操作、丢弃后批准 close、connection descriptor
  消失及重复 close。它们走 production Host/controller/domain，但不是人手点击标题栏
  关闭按钮的证据。
- 统一测量器以 5 秒预热和 60 秒采样完成三组 idle 及一组混合负载。idle 报告
  `/tmp/cjgui-macos-application-host-idle-60s.json` 的 SHA-256 为
  `17d52fb4e5e23be7832c10d0d0796918bfbeb2e6b7277a9276f8cd8908a959f4`；混合报告
  `/tmp/cjgui-macos-application-host-mixed-60s.json` 的 SHA-256 为
  `7d82427f996539bc4a15074449d3c6ff9ecd8afb5e2c49519b09b3576393a920`。每个 idle
  cycle 均有 61 个样本并以 0 退出；混合规则集 1,001 项工作完成后不再持续提交 frame，
  文档 paced 读取在正常退出时有一次 `ConnectionClosedError`，没有被写成“零错误”。
  两个 connection cycle 由测量器在进程结束后验证 descriptor/socket 已清理；这证明
  该负载后的端点回收和观测到的稳定采样，不外推为全局无泄漏证明。
- K3 事件按事实记为**无效咨询、累计有效轮次 0**：此前唯一一次命令使用的选择器是
  `--model k3`，不是规则要求的 `kimi-code/k3`；CLI 报 `k3` 未配置，且 local
  session-storage 路径为 `ENOENT`。现存记录没有保留可核验的“同一具体源码失败场景”
  或两次同场景改动/验证，故不能倒填为已满足触发条件；本收口中出现的 runner link
  检查和文档 probe 类型错误也是两个不同场景，各自一次修复即通过。没有获得建议、没有
  重试不可用 CLI，也没有静默替换模型或据此修改行为。


### 指导复核与当前阶段接续

接受独立Luna从公开文档完成消费与cold/incremental构建、公共读写证据。指导静态审阅host/runner/native/source tests；当前阶段继续，不把两秒smoke和源码grep称完整运行回归。

1. `run_macos_application.sh`的fingerprint只有路径/flags字符串，源码靠mtime判断。保留mtime的内容变更、同路径compiler/SDK替换可能漏编。落实实际源/header/相关选项与工具链身份的失效键；测试保留mtime但内容改变、header/选项变更、无变化复用。归档构建失败不得发布“有效fingerprint”，并保证cjpm确实链接更新后的native库。只处理本应用构建产物，不清用户缓存。
2. Resources只逐个cp，移出配置或改名的旧资源仍残留；同bundle改可执行名也会残留旧文件。建立framework-owned产物的清单或临时bundle构建/成功替换，使产物与配置一致，失败不伪装为可运行新包。并发构建同应用避免半成品互相覆盖，保留不同应用并行能力。`CJGUI_USE_LAUNCH_SERVICES=1`当前open -W未传应用参数，验证并修复有限运行/业务参数传播。
3. 宿主配置title只在start设一次，而CjguiCommitComposableSceneOnMain仍每次setTitle为CJGUI Composable UI。用不同应用标题、首次与后续业务刷新实测，保持配置意图。不同cwd资源不只证明文件复制：实际加载图片/资源并检查替换/移除后行为，复用当前资源路径，不写样例专用分支。
4. 当前macos_application_host_test的正常/失败cleanup测独立CjguiMacosApplicationRunner+FakeTurnSource，而实际Host没有使用它。两份started/closed不能互相当证据。合并必要生命周期实现或把测试落到实际Host边界，避免仅为测试保留平行公共运行时。实际主线程宿主覆盖window成功而connection失败、拒绝关闭后继续操作、正常批准关闭及重复cleanup、重开按公开支持语义；异常退出边界说明。native生产路径探针可在锁屏先验证，物理按钮不冒称通过。
5. 两秒idle只是smoke；沿已建立统一ready/5秒预热，至少60秒idle对照和一组稳定混合输入/业务负载，核验无重复调度/资源泄漏与endpoint清理。重用原测量器，不再另造短测替代基线。独立消费者继续验修正后的标题、资源和本地交互接续，不只外部协议。
6. K3环境问题需补触发它的具体失败场景、累计两次改动/验证、调用参数中模型别名（不含凭据）与实际错误；`k3`和规定的`kimi-code/k3`不能混淆。未获得建议不得计为有效K3轮次。CLI不可用不反复撞环境，也不静默换模型；把未解决的代码问题立即给指导诊断，独立工作照常继续。

上述是同一正常包消费大阶段的完整收尾，保留已完成消费成果，不增加业务功能或新治理台账。原目录Terra/xhigh，K3累计及无Git写入保持。完成或实质升级主动回报。
