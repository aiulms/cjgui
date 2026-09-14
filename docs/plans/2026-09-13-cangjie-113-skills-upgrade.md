# 仓颉 1.1.3 与技能配套升级

2026-09-13，用户要求核对上游issue与CangjieSkills更新。指导已核实来源，执行负责下载/验证/接通，不另开GUI产品路线。

## 已核实

- [编译器 #859](https://gitcode.com/Cangjie/cangjie_compiler/issues/859)中维护者liujiajie称1.1.3已修复新版macOS SDK链接问题，issue仍开启。[官方下载页](https://cangjie-lang.cn/download/1.1.3)列出2026/05/29发布、mac-aarch64 tar.gz及SHA256入口。
- 本机编译器仍是 `/Users/jiangxuanyang/cangjie-toolchains/cangjie` 下的1.1.0。CJGUI normal runner仍默认MacOSX15.4.sdk。当前未在1.1.3重现hello/FFI/GUI，不提前移除workaround。
- 六个旧cangjie技能均由`~/.agents/skills/`软链接到`repos/CangjieSkills/.agents/skills/`。仓库干净，本地main为`7a3db09`（2026-04-02）。上游已无main，原fetch refspec因此失败；远端默认为cangjie-1.0.5，不能盲目pull默认分支。
- 已精确fetch `origin/cangjie-1.1.3`，提交`4b844f29e82b32ecf2171c36659b9e8ea9e2f595`。此分支发布目录为`.agents/skills/cangjie-coding`，整合旧多技能为渐进查询脚本与只读SQLite知识库。SKILL明确面向1.1.3、stdx1.1.3.1。当前没有切换分支、替换软链接或激活新技能。README声称的效率提高不作为本机验证结论。

## 执行与验收

在当前组件一致提交阶段的安全收口点进行配套升级，先检查活动编译/写入，不能在旧任务构建中间改变全局PATH/技能。当前开发继续；新工具链可并存准备，这不是复制CJGUI工作目录或创建worktree。

1. 从上述官方页面取得mac-aarch64 1.1.3下载与SHA256，核对实际包后解压到独立版本工具链目录，保留1.1.0原路径。所有候选验证用显式envsetup/工具绝对路径；不一开始覆盖全局安装或用户shell设置。
2. 用新工具链且清除进程内SDKROOT/CJ_GUI_SDKROOT覆盖，记录实际xcrun默认SDK、cjc及bundled linker版本，复验原hello链接/运行；再以15.4作必要对照。复用labs现有FFI探针与CJGUI核心/normal Host，验证native桥接、静态库、程序生命周期和公开读写；记录原始构建与源码版本。旧缓存与新工具链产物隔离，必要清理由实际项目输出范围限定，禁止全仓清理或影响用户运行应用。
3. stdx若被项目实际使用，核对清单/匹配版本再升级，不因skill有setup脚本就改所有依赖。按明确工具链版本重新构建相关产物并验证；不推定1.1.x二进制可混用。
4. 新技能使用已核实的cangjie-1.1.3固定提交，提取发布目录即可，无需复制6000+源文档或改旧仓库分支。遵循skill-installer的保留已安装目录原则，GitCode源用git archive等适用方式，勿套默认GitHub脚本或npx默认分支。记录来源/ref/hash；审阅入口和检索脚本，做一次批量检索确认Python兼容与知识库可读。优先让执行任务显式读取新技能路径验证；确认编译器版本一致后再启用`cangjie-coding`入口并将六个旧软链接可回退地移到备份目录，避免同时给AI冲突版本。只动已核实的这六个链接，不覆盖其他技能。
5. 候选验证通过后更新项目工具链入口/构建说明，使执行任务显式使用1.1.3；尽量保留用户全局旧环境不变。若默认SDK全链验证通过，才调整当前构建脚本默认SDK选择，同时保留显式覆盖/旧SDK回退。这类SDK变更属于本任务范围，需真实normal bundle而非只hello通过。候选失败则保留旧默认、给根因/证据与下一方案，不阻塞原组件阶段独立工作。
6. 更新issue账本、BUILD_FROM_ZERO、当前ACTIVE工具链简述和技能导航，区分上游声称修复、本机hello/FFI、最终GUI验证；无需新治理表。告知用户实际切换了哪些入口及回退路径。skill可发现性在后续任务上下文核对，不能保证运行中的模型自动忘掉旧技能。

指导只审核/文档/指派，实现/工具链构建验证由原Terra/xhigh执行。用户已有更新意图授权，无需逐步骤请示。不得关闭用户应用、对外回复issue、stage/commit/push或发布。完整升级或实质阻塞报告指导；不把下载、fetch或安装skill当配套升级完成。
