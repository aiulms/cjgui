# 组件实例与绑定生命周期：交付记录（完成，保留边界）

指导复核收尾：最终普通消费者的 `GET_CONTEXT` 已定位并修复。组件投影曾把带 `:` 的内部 business/local key 拼进 `semanticId`；公共协议严格拒绝该令牌，transport 又把无效快照误映射成 `response_too_large`。现改为只暴露 generation/slot 组成的 opaque 安全标识，并区分 `invalid_snapshot` 与真实 `response_too_large`；最终包的完整/定向读取、写入读回、冲突/未授权拒绝和窗口接手均已实际通过。

2026-09-13；对应[阶段任务](2026-09-13-component-instance-binding-milestone.md)。本记录区分已验证的阶段能力与没有被本阶段掩盖的系统边界；组件组合、绑定生命周期和独立消费已完成，不把 IME、VoiceOver 或历史 Escape 根因写成已解决。

## 已实现并针对性验证

- `CjguiComposableUiComponentRegistry`/`CjguiComposableUiComponentInstance` 提供每个 controller 自有、最多 64 个 live 实例和每实例 64 个 local key 的组合上下文。稳定业务 key 在重排时保留实例；同轮 duplicate key 明确报错；`retain` 支持临时隐藏；未 use/retain 的实例在 `finish` 销毁，之后同 key 重挂得到新 generation/node ID。没有 hash identity 或无界进程级实例表。
- 通用 vertical/horizontal 组件根可声明普通 `inputScopeId`。命令集新增完整替换 `replaceCommands` 与 `revokeCommand`：同 scope 重复 chord 拒绝，不同互斥 scope 可复用；当前 scope 优先，global 只在 base focus 时 fallback；候选 target 不在已接受 scene 或 scope 不匹配时替换失败且旧集保留。
- controller probe 使用两个公开组件实例实际触发同一 Cmd-K、动态隐藏恢复、删除重挂和命令替换；验证只作用当前实例、隐藏不改 ID、删除重挂改 ID。`adaptive_layout_public_consumer` 已接入两个同 chord 的 scoped 组件，普通运行循环在每次 accepted refresh 后替换完整命令集，隐藏第二组件时不保留旧 binding；不同业务的 `rule_set_window_app` 也以两个稳定 key 组合外观/资源组件并复用已有 controller owner action。README 现在明确列出两个普通入口、构建/启动方式、生命周期顺序与不支持的边界。
- 为历史 Escape `69` 增加 test-only FIFO trace。若收尾 Escape 再失败，输出 capture/pump 的 event kind/node/scene、pending 数、Cangjie accepted/submitted scene、focus/active layer、pump budget、native status 与 controller dialog 状态，能区分未入队、旧 scene、错误 target/layer 与 controller 未应用；不改变 production native ABI 或业务分派。
- Escape probe 另覆盖两条交错契约：Escape 在 dialog scene 捕获后、owner 先刷新移除 dialog 时必须因旧 projection 拒绝；nested menu 的 focus restore Tab 与随后 Escape 同 FIFO 时，pump 先处理无副作用 Tab、再关闭 dialog，而不关闭 base/错误层。两者均不依赖 sleep。

## 本轮证据

- `shared_operation_core` 的 `cjpm test`：42/42 通过，新增无效投影标识返回 `invalid_snapshot`、真实超过 8 MiB 快照返回 `response_too_large` 的分型覆盖。
- `zsh runtime/cjgui/native/scripts/verify_composable_ui_window_controller.sh`：通过（含新增实例、命令、Escape trace 与同窗口 30 秒恢复采样）；其公开上下文诊断为 `component_nodes=5`、`component_semantic_token_safe=true`，完整和定向读取均为 `snapshot`。
- `runtime/cjgui` 的 `cjpm build --skip-script`：通过；仅既有 `chmod` deprecation warning。
- 更新 trace 后，已编译 controller probe 独立进程重复 30 次：`runs=30 failures=0 residual_processes=0`。此前 `69` 没有在本轮复现，因此该结果证明当前序列稳定，不构成根因结论。
- 同一 controller 进程完成 30 轮焦点动作、隐藏/恢复、删除/重挂和完整命令替换：`min/mean/max=1/29/41ms`，`build/layout/submit delta=150/150/120`，queue 在收尾为 0（high-water 2），AX notification 63，live instance/command 均回到 2。随后保持**同一真实窗口**空闲 1,875 个 16ms bounded pump（约 30 秒），`idle build/layout/submit delta=0/0/0`，RSS 从 `108,036,096` 到 `107,544,576` bytes，累计 CPU 从 `345,624` 到 `682,884` micros。该数值是进程累计 CPU、allocator 允许 RSS 不完全回基线；本轮只证明负载撤除后没有残留实例/command/queue 或无业务重建，不把它写成全局内存无泄漏证明。renderer 私有缓存没有作为公开 count 暴露，未伪造一个缓存数。
- 独立 agent 仅按 README、三份公开 composable API 源和 `cjpm.toml` 在 `/private/tmp/cjgui-independent-component-consumer` 实际构建/运行：同 chord 的两个 scope 被 `replaceCommands` 接受，公开 `invokeCommand -> controller -> owner` 产生 owner readback，`revokeCommand`、动态移除和重挂新生命周期均通过。公开 API 没有强制设焦点接口，故独立 CLI 不能伪造 native focus 来逐一触发 scoped Cmd-K；这是当前 public CLI 边界，不以 test seam 冒充验收。
- 解锁后的实际 `AdaptiveLayoutPublicConsumer` 最终 bundle 已启动，AX 树展示两个 scoped 组件。独立公共 Python client 从应用发行的私有 descriptor 读取完整和 `--target 7101` 快照：均含资源、动态 action 和受授权关系；组件节点以 `component-<generation>-<slot>` 出现。对资源 `7101` 的 `SET_MARKED` 得到 `APPLIED true, VERSION_BEFORE 0, VERSION_AFTER 1`，完整和定向读回均为 version 1 / `isMarked=true`；陈旧 version 0 写入得到 `version_conflict`，未授权 `GET_CHANGES` 得到 `unauthorized_action`。同一真实窗口显示 `shared operation version = 1`，刷新后经标准 close 控件退出且 descriptor 被删除。这是“外部 descriptor → 完整/定向 GET → owner CAS 写入 → GET/window 接手 → 拒绝/清理”的最终包证据。
- `adaptive_layout_public_consumer` 和 `rule_set_window_app` 已按最终源码重建、资源存在性与签名验证通过。Adaptive 打包清单显式携带两张 beacon，示例仅传 bundle-relative 文件名，避免把源码树路径带入 `Contents/Resources` 解析。第二个规则集消费者此前用其普通 Host 的临时未命名领域执行 `--verify-host-close-decisions`，真实创建窗口、改变 owner、拒绝一次未保存关闭、丢弃后接受关闭并清理 endpoint。安装、公证、发布未运行。

## 明确遗留（不阻塞本阶段交付）

1. 历史 Escape `69` 在重启 30 次和确定性 FIFO 交错中未再出现；新的 capture/pump trace 已能把下次失败归为平台未入队、stale scene、错误 target/layer 或 controller 未应用。它不是根因解决，也不将相关系统输入链路标绿。
2. 独立公开消费者已编译运行并做 command/removal/readback；其没有公开的“强制 native focus”接口，故不把 test seam 当作逐 scope 键盘验收。无快捷键菜单动作仍与 shortcut command 分离，不为样例扩 native API。
3. 系统中文 IME/VoiceOver、安装、公证和发布未运行；本轮未 commit，且没有修改 `runtime_state.cj`。
