# 来源、建项、构建与升级

## 三层身份

`identify.py --app APP` 沿 `cjpm.toml` 的本地 path 依赖寻找 CJGUI，包括应用领域库的间接依赖。
workspace 根会遍历声明的字面路径 members，并保留缺失成员/未解析模式的警告；这是来源发现，
不表示 build-members/test-members 都会使用这些依赖。核某个应用构建和运行时用它的成员目录；多来源不能任选一个。
新应用先按选定 SDK 建项再运行；错误路径、空路径或缺少/损坏的应用清单以非零退出报告错误，
有效应用的远程/未识别依赖仍保持 unknown，不把两者混为“没用 CJGUI”。
读取其附近的 `source-manifest.json`、`source-lock.json`，以及应用
`.cjgui/macos-build/build-provenance.json`。脚本只观察，不构建、不找最新包、不改依赖。
`supporting_dependencies` 列出共享核心的实际路径与 manifest 哈希；与框架所属核心路径不一致时
保留混用提示，结合构建来源核对，不能静默替换其中一项。
远程依赖、特殊 workspace 或缺信息来源可能无法自动解析：按实际构建配置补核，保留未知。

| 层次 | 可用依据 | 不能推出 |
| --- | --- | --- |
| 当前参考源码 | 依赖路径；manifest 逐文件 SHA 与导出/原始来源；lock 的范围和格式 | 实际构建已使用、运行已加载 |
| 实际构建 | provenance 中 source/prepared input、native archives、link map/trace、executable SHA、构建工具与配置 | 仅凭 `verified: true` 保证当前文件未变；签名后 bundle 与构建 executable 字节相同 |
| 运行实例 | 精确 PID/启动身份、实际 executable/bundle、启动或公开连接证据、该实例的正常消费结果 | 由包名、窗口标题、日期或磁盘上另一个新 App 推断当前运行的是它 |

初次定位可只读元数据；交付来源有疑点或需要证明复制完整时，用
`identify.py --app APP --verify-files` 核逐文件哈希。构建报告可显式指定
`--build-provenance FILE`；已有运行观察可用 `--runtime-evidence FILE` 留其依据。
运行观察为 JSON 对象，可含 executable、executable_sha256、pid、bundle_id、platform、observed_at；
这里只输出允许的身份字段，不自动查进程或验证其真实性，勿放 descriptor/凭据。
构建报告标为 metadata_report，recorded_verified 只表示原记录声明；
current_verification=not_performed 不会因运行观察中填了 PID 就升级为已验。
脚本报告文件存在、声明或哈希吻合仍不替代实际运行验证。复制树可能保留绝对旧路径，
不能把不可达路径改指当前树后声称原构建已证实。

format 2 lock 覆盖交付闭包，旧扁平 lock 只覆盖其列出的 `.cj`；其缺少 native/脚本覆盖不是错误的“完整锁”。
没有清单的旧包/捕获副本可继续使用已核对的公开 API，身份标为不完整，必要时只核本次输入。
Git HEAD、目录名、日期仅为线索；checkout 有未提交修改时尤其不能替代内容身份。

## 查同版公开说明

- 导出包：`SDK/README.md` 为快速开始，框架在 `SDK/framework/cjgui`。
- checkout：`FRAMEWORK/preview/MACOS_DEVELOPER_QUICKSTART.md` 为源稿，
  其中 `framework/cjgui/...` 与 `consumers/...` 是**导出后**路径；checkout 命令使用
  `FRAMEWORK/scripts/...`，消费者使用 `FRAMEWORK/examples/...`。
- 通用构建与生命周期：`FRAMEWORK/MACOS_APPLICATION_HOST.md`。
- 字段与可选协作：`FRAMEWORK/templates/macos_application/mixed_form/README.md`。
- 其余模板若没有独立 README，直接读同版模板 `cjpm.toml`、`run.sh` 和应用 `src`；不杜撰入口。

## 创建与构建

先查所消费版快速开始中的平台/工具链要求与支持边界。当前公开 macOS 创建器提供
`ui-only`、`command-surface`、`collaboration`、`mixed-form`；旧版是否存在各选项以其脚本为准。
选择覆盖需求的最小模板：纯本地手写字段/controller owner/工作会话保存用 ui-only，命令/Inspector 用 command-surface，
同 owner 的手写/生成字段用 mixed-form；不为纯 UI 任务启用协作。

```sh
zsh "$FRAMEWORK/scripts/create_macos_application.sh" ui-only "$APP"
cd "$APP"
./run.sh --build-only
./run.sh
```

父目录须存在、目标目录须不存在；支持带空格路径。工具链按使用者环境设置
`CANGJIE_HOME` 或加载其 envsetup，不硬编码作者路径。不要继承无关的
`CJGUI_NATIVE_SOURCE_DIR`；若有意覆盖，分别记录源码与 native 来源。
正常 runner 固定本应用的 native 归档、编译配置与来源证据，沿用它处理资源、rpath 和签名，
不写第二套链接/打包脚本。同一应用 target 的 build/test 串行。
构建遇错先核工具链、两项框架依赖、来源覆盖和现有报错；不要直接删共享缓存或冻结 SDK。
已有试用出现框架 unused 警告且构建成功；不能按某个固定警告数量判成功，也不把所有新警告都称为正常。
先看退出码与 error，再区分应用新增问题和同版已知框架 warnings。

若正常 runner 报 `compiler configuration changed or is unknown for a nonempty target`，
先查本版 `MACOS_APPLICATION_HOST.md` 的编译配置/target 说明与本应用的 prepared、verified provenance。
首次编译失败也可能留下尚无 verified provenance 的非空 target；这不是编译器缺陷的充分证据。
仅当本版说明适用、确认路径属于本应用且没有在用实例时，保全可用 bundle 与必要失败日志，
再按说明隔离或退役**该应用**的临时 target 后正常重建。不能把它推广为每次编译失败都清缓存，
也不能删除用户旧交付、SDK 或归属不明产物。保留重试成本与报错易理解性的反馈。

## 升级

只在用户授权的升级任务中选择候选。保留旧包与可用产物，比较受影响的公开签名/配方，
同步核应用及其领域库的 `cjgui`、`cjgui_shared_operation_core` 依赖，以及 `run.sh` 的框架根。
不要用新模板覆盖应用业务源码。用正常 runner 构建，按改动做编辑/读回/保存或关闭短链。
旧 workaround 在**实际构建确含修复且该应用对应消费通过**后退出；SDK 与 checkout 分别核对，
具体见[反馈指南的退出条件](feedback.md#正式回接与知识更新)。仅主树修复时继续保留旧版适用范围。
首次构建只需一次必要编译；无新修改/失败/疑点，不反复整包验证。
