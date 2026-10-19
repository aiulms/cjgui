## 咨询结论

这次 **RED 是连续本地输入跨 accepted 场景时失去延续身份**。它与 r9 的 mount 同值回声 guard 是两个问题；现有证据不支持撤回该 guard。

基线 owner v1 为 136B，第二行含 `alpha`；一次 `uitest uiInput text alphaH` 后，独立读回是 v4、134B，第二行只剩 `a`，末尾多出 `aH`。预期全文应为 137B，第二行是 `alphaH`，末尾不变。[原始 owner](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/55-preserve-at-r9-install/saved-user.owner.utf8)、[最终读回](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/58-final-partial-input-red-observation-r9/result.json)、[唯一输入及回包](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/57-final-human-agent-partial-restore-r9/exchanges.jsonl)。

| 证据 | 判断 |
| --- | --- |
| 旧 proxy 先产生 `6:10` 删除、再产生 `6:6` 与 `7:7` 插入；平台分别报告实际选区 `6:6`、`7:7`、`8:8`。[hilog](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/consultations/partial-input-continuation-sol-20260930/device-red.hilog.txt:27) | 首笔把 `alpha` 变成 `a` 是合法差分；不能把差分端点当作真实 caret。 |
| 首笔 owner 只接受到 132B 的 `a`，此时 native 缓冲已经收到后续输入；accepted 场景随即触发 `ctx 1→2` reconcile。[hilog](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/consultations/partial-input-continuation-sol-20260930/device-red.hilog.txt:167) | 这是本次断链的直接时序。 |
| kind-51 入队保留编辑投影版本和会话绑定代次；窗口的本地回显旗标只在 kind-28 接受后设置，旧投影续接也只认 kind-28。[native 入队](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:5540)、[窗口结算](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj:2306)、[续接解析](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj:5757) | kind-51 缺少对应的“owner 已接受本地前缀”路径，是源码确认的缺口。 |

**仍需一条区分日志**：现有 hilog 证明 `l/p` 已进入 native 队列、最终没有形成相应 owner 接受，却没有逐事件的出队投影、解析结果和具名判决。因此“它们在 accepted v3 后因旧投影被续接解析拒绝”是强推断，尚非逐笔直证。只给 kind-51 出队增加原投影、绑定、解析分支、owner 版本和判决原因的局部诊断即可区分；不要靠重试得到绿色。日志中也没有 `h` 的 native delta，需要区分它是在旧 proxy 退役期间未形成回调，还是更早的 SDK 输入行为。

## 现有架构内的最小修复

1. **建立窗口内部的本地延续凭证。** 首笔 kind-51 经 `CjguiTextSession.replaceRange16` 接受后，记录原 accepted 投影、完整字段绑定与焦点身份、文本会话代次、`decision.versionAfter`、有界镜像的覆盖范围及**精确全文后像**。后续旧投影 kind-51 只按 native FIFO 顺序续接：每笔先核对当前 owner `sourceVersion` 等于上一笔接受版本、镜像等于上一笔后像，再把该笔范围交给原会话仲裁，接受后更新凭证。`eventText` 只是插入片段，不能拿它充当全文。现有 [文本会话](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/text_session.cj:1992) 已提供逐笔仲裁、版本和镜像；无需新增 owner 操作或公开编辑协议。

2. **让 kind-51 的 accepted 回显携带一次性的本地接受事实。** 场景候选全文必须精确等于会话刚接受的镜像，且当前 owner 源版本仍等于该笔 `versionAfter`，绑定仍一致，才设置已有 `preservesActiveLocalText`。这样 owner 先回显 `a`、native 已到 `alp` 时，[native reconcile](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:7468) 只推进准入版本，保留活 proxy；待 `l/p` 各自仲裁后再接受后续前缀。接受失败、owner 规范化结果不同、镜像窗口移动而无法精确重基，或 Agent 写入插队时，立即撤销凭证，走已有拒绝与实际安装回执恢复。

3. **收紧同值判断。** 对拥有范围会话的字段，`ownerValue == editingText` 本身不能证明本地回显；当前 native 分支会据此保留 context。[native 同值分支](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:7479)。Pharos 的 `uiSceneVersion()` 是控制器结构修订，且该控制器未实现可选业务 owner 修订提供者，不能用它识别 Agent 的同值换版。[产品控制器](/Users/jiangxuanyang/Desktop/Pharos%20Mark/apps/pharos_mark_ohos/application/src/pharos_ohos_controller.cj:15)。范围会话应以已有 owner `sourceVersion` 和本地接受凭证判断；无凭证的新版本即使文字相同也要撤销旧 context。候选提交前及延迟票据结算时都要复核版本，防止 Agent 在两者之间插入写入。

4. **保持选区为独立平台事实。** [plain change](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:8875) 当前先把 caret 设为全文末尾；这是独立风险，但本次实际 getter 已报告 `6/7/8`，不能用它解释本次断链。修复时使文本差分后的 caret 仅为待观察状态，由同 context、同绑定的实际选区观测确定；旧 context 的回调和已排队 kind-33 不得覆盖新选区。[选区入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:8997)、[窗口采纳](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj:1996)。不要用 `delta.nextEnd`、延时或 debounce 代替该观测。

## 必须先立的判别反例与验收

- **连续输入跨帧 RED**：冻结原 v1 全文及 `[5,10)` 的实际安装事实，只输入一次 `alphaH`。让首笔 accepted 发生在其余输入仍在队列时；每条已产生的 kind-51 都有一次会话判决与 owner 结果，最终精确 137B、第二行 `alphaH`、末尾原样，accepted 场景和实际 getter 的选区也对应同一版本。若该次平台逐字产生六笔，才断言 v1→v7；不要用版本数代替全文。
- **重复文本与非空替换**：在 `aaaa` 的中间插入 `a`，全文差分可能合法地选末尾插入，实际 caret 却在中间；断言全文与 getter 分开。在非空选区替换多字符时断言精确 owner 后像、逐笔版本和真实选区。
- **拒绝与外部交错**：首笔 owner 拒绝时，凭证不得建立，后续旧队列不得写入，恢复必须等平台实际安装回执。首笔接受后让 Agent 分别做异值、同值但升版本的写入；旧队列逐笔具名拒绝，owner 外部结果和新 context 保持，不能因 native 缓冲领先而一概 preserve。
- **跨 context 选区**：旧 proxy 的实际 getter 回调和已排队选区事件晚于 reconcile 到达时，均不能改新 context；新 proxy 的实际安装观测才可采纳。保留 r9 同值 mount 回声、真实 different-text onChange、marked/preview 和既有恢复票据负控。
- **验收层级**：先保存这份生产 RED 并做窗口生产接缝 fixture，建议与 [现有窗口 fixture](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/fixtures/window_restore_adoption_snapshot_test.cj:5) 并列，串起 kind-51 入队、跨 accepted、逐笔 owner 仲裁和拒绝回执；再用 [native 差分测试](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/test_ime_range_delta_native.py:28) 与 [context reconcile 测试](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/test_generated_reorder_editing_context.py:1) 守各自接缝。最后才在固定 HAP、同 PID 的 normal Pharos 跑**一次**真实系统输入、完整 owner 读回、accepted 画面及选区、滚动可见范围；源码夹具通过不能替代这一步。

对 `h` 的最小 SDK 对照是一个独立的系统 `TextArea`：同样先安装 `[5,10)`、同样执行一次 `uiInput text alphaH`，仅记录逐键、全文 onChange、实际 selection getter、focus 和组件退役时间；再与保持单一活 proxy 的修复版比较。它只用于判明旧 proxy 退役时是否吞了该键，不作为 CJGUI 接入依赖。

**执行边界**：本次没有改文件、构建或操作设备/桌面，也没有运行上述验收。已尝试启动指定的 `gpt-6-sol/max` 临时只读 Codex CLI 会话，但 CLI 初始化要写 Codex 状态数据库，当前只读沙箱以 `attempt to write a readonly database` 拒绝；以上是当前会话基于指定源码和日志的咨询，不能冒称独立 Sol 运行结论。

