# CJGUI 鸿蒙后端：基础链收口与系统文字接入

更新：2026-09-26。本文是鸿蒙当前执行包的完整任务提示词；执行已由用户安排，持续推进并集中交付。用户确认固定路线，并要求必要返工与下一轮新能力一起推进。**当前接续以页末「第五次指导复核与当前完整工作包」为准；前文及执行自报保留为历史依据。原 A–E 的必要验收继续承接，只暂停依赖具体失败的路径，其余工作继续。**

## 第一阶段基线目标与路线（原 A–E）

你负责 CJGUI 框架的鸿蒙后端。工作目录 `/Users/jiangxuanyang/Desktop/cangjie`。Pharos Mark 继续在独立目录开发 macOS 编辑器，两条线并行。

本包唯一目标：**同一套仓颉 CJGUI 组件、布局、场景、身份及共同操作核心，在鸿蒙正常 HAP 中形成“自绘显示 → 人操作 → 真实 owner 修改 → 画面更新 → 外部读取/授权修改 → 人接续”的完整链，并经受 surface 生命周期变化。**

固定路线：仓颉持有组件、应用状态和业务规则；鸿蒙宿主提供平台生命周期、surface、系统服务；窄原生桥承担必要事件转换、文字资源与 GPU 提交。macOS 与鸿蒙共享上层定义和业务操作，各有平台实现。外部智能系统与人的操作遵守同一业务规则和授权。

**用户确认的宿主方案（2026-09-25）：仓颉核心 + ArkTS 薄壳 + XComponent + 原生绘制后端。** 仓颉负责组件、布局、场景、命中、业务 owner 与共同操作；ArkTS 负责官方装载入口、应用生命周期和 XComponent 挂载；原生桥负责平台事件、文字/GPU 资源及帧提交。高频布局和绘制路径保持在仓颉核心与原生后端之间，宿主适配集中封装进框架入口与模板，普通消费者主要用仓颉开发。

当前包继续上述主线。纯仓颉 Canvas 保留为已有构建实验，本包不追加 Canvas 后端实施或并行验证。后续若官方 SDK 提供可验证的仓颉原生宿主接入，可替换薄壳并复用核心和原生后端；替换以生命周期、输入和绘制契约等价为依据，不以语言替换直接宣称性能收益。路线核实依据见[仓颉优先宿主复核](../research/2026-09-25-cangjie-first-harmonyos-host-review.md)，其中动态问题以报告标注的源码快照为准，执行时核对最新代码和证据。

第一消费者固定为简洁的“设置与计数”小应用：中文标题、数值、增加/减少按钮、启用开关和状态提示。给计数设置明确范围；启用状态影响动作可用性。它用于检验公共框架，可复用上层源码在 macOS 运行。它不是编辑器，也不是新的一套 GUI 框架。

本包必须包括中文文字显示、按钮/开关、布局裁剪、触摸交互、版本化外部操作与生命周期。系统可编辑文本、IME、复杂富文本、完整控件库、编辑器移植留待后续阶段；本包不放假可编辑文本框。文字显示要进入自绘场景，ArkUI 仅承载宿主，不用覆盖式 ArkUI Text/Button 代替 CJGUI 控件。已有 C++ 双卡片实验可复用平台机制，其 C++ owner 不成为新的业务真相。

## 开工读取与真实基线

依次读：

1. `AGENTS.md`、`runtime/cjgui/ACTIVE_DIRECTION.md`、本文。
2. `docs/core/GUI_PROJECT_DIRECTION.md`、`docs/core/AI_NATIVE_UI_SEMANTICS.md` 的平台边界，以及 `docs/plans/DESIGN_INTENT_INDEX.md` 的相关资产。
3. `docs/plans/2026-09-20-harmonyos-cangjie-handoff.md`、`labs/ohos_cangjie_smoke/README.md` 与脚本。
4. `labs/ohos_gui_smoke/` 的 surface/EGL/生命周期实现；随后按需要读当前 CJGUI 场景、窗口、文字测量、事件、共同操作实现。

基线要正确解释：9 月 20 日真正运行的是仓颉 ArkUI 示例；当时 CJGUI 的交叉编译成功不等于 CJGUI 已运行，也不覆盖此后新增的范围文本及样式 run。`labs/ohos_gui_smoke` 有平台实验代码，但不是 CJGUI 消费证明。复用既有安装与工具链，不从头反复排查已解决的环境问题；对本次实际使用的 SDK、ABI、模拟器与源码快照作一次核对。

首次写仓颉前，必须读 `/Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md`，按其 `scripts/search_docs.py` 检索语法、FFI 和工具链。鸿蒙 API 以本机 SDK 头文件/示例及相应版本官方文档为准，不把 macOS API 换名字当作移植。

## Laya：必须实际使用的辅助判定

用户明确要求你会用并实际使用 Laya。它是本地分类/排序辅助，不是代码生成器。你仍对方案、实现和验收负责。

本机 2026-09-25 已核实：

- 健康入口：`GET http://127.0.0.1:8000/health`。
- 判断入口：`POST http://127.0.0.1:8000/v1/systemone`，JSON 顶层为 `state`、`questions`。
- 服务实现：`/Users/jiangxuanyang/Desktop/Kimi_Agent_AI 自动化开发思路/laya-lab/serve_local.py`。
- 已安装环境：同目录 `.venv`；已有服务使用 `mps`。PATH 中没有 `laya` 命令不能判断为未安装。
- 指导本次实际 POST 返回 HTTP 200、`model=laya-rl-agent`、`answers.route.type=choice`；单次短请求约 0.245 秒，只说明该次调用情况。

### 必须调用的节点

1. **开工方案**：把已知事实、候选平台边界、待确认假设做短摘要，判断问题类型和应先验证的链路，再咨询架构顾问。
2. **方案存在分歧**：为每个候选写可检验条件，使用 Laya 排查顺序参考；选项必须包含“信息不足”。
3. **出现新失败族**：先收集实际日志/状态，再让 Laya 分类为构建/装载、场景、输入、owner、生命周期或信息不足；按顺序做可区分实验。
4. **整包交付前**：检查证据摘要是否混淆“编译、装载、显示、输入、业务写入、生命周期”，找遗漏与矛盾。

同一事实没有变化时不重复询问；相关问题合并短请求，不按每次编译或每个函数机械调用。`state` 只包含与本次判定有关的事实和假设，按模型实际上下文限制组织，避免整仓/长日志截断。请求、原始响应和“采纳/不采纳及理由”放入本包证据目录，阶段记录只做链接。

下面是当前已核实的请求形状。写入本包证据目录的 `laya-request.json`，替换事实与选项后调用：

```json
{
  "state": "鸿蒙已收到场景，屏幕内容没有更新。owner版本已增加，提交回执尚未核对；没有证据说明surface仍有效。",
  "questions": {
    "first_check": {
      "type": "choice",
      "instructions": "按现有事实选择最应优先补充的检查，不把假设当结论。",
      "criteria": {
        "scene_surface": "核对场景提交结果、surface代际与当前呈现目标",
        "owner": "核对业务操作是否进入真实owner",
        "input": "核对输入是否到达目标控件",
        "insufficient": "信息不足，需要补充关键事实"
      }
    }
  }
}
```

```bash
curl --fail --silent --show-error --max-time 20 \
  http://127.0.0.1:8000/v1/systemone \
  -H 'Content-Type: application/json' \
  --data-binary @laya-request.json > laya-response.json
```

检查 HTTP 结果和 JSON 结构：`answers.first_check.type` 应为 `choice`，`choice` 必须属于提交的选项，`probabilities` 应为合法数值。错误、空输出或畸形响应记作调用失败，不当作判断。概率只作排序参考，不能替代源码、反例、运行结果或授权。

**强制升级条件优先于 Laya 分类。** 本次指导实测中，Laya 把尚含跨平台公共契约/状态归属的开工问题选为 `technical`；我们仍要求架构顾问先审。你也应写出不采纳理由，不为迎合评分改动事实或降低验收。

服务不可用时，先核实已有服务和上述本地安装。端口空闲时可用该安装的 `.venv/bin/python serve_local.py` 作一次有界启动；端口被占用时核对命令路径、工作目录和服务身份，仅处理确认归属的准确进程。本机 `laya-ctl.sh stop/restart` 按端口结束监听者，不能直接用于恢复；身份不明则保留占用者、记录不可用。仍不可用时继续独立工作，报告明确写“Laya 暂不可用”；不能写成已使用，也不能因此取消必要顾问咨询。不把 Laya 加入 CJGUI/HAP 的运行依赖。

## 顾问分工与停止盲试条件

沿用用户已确定的 Codex CLI 咨询方式，与主执行模型品牌无关：

- 架构、算法、跨平台公共契约与状态归属：`gpt-6-astra`，次高思考档；当前配置为 `max`。
- 既定契约内的复杂技术、ABI/FFI、线程、GPU/surface 生命周期根因：`gpt-6-sol`，次高思考档；当前配置为 `max`。

**首次后端方案在实施前，先用 Laya 辅助整理，再向 Astra 发一次聚焦只读咨询。** 交付最小场景/输入/文字/资源边界、线程与所有权图、现有源码位置、复用方案和反例验收。先确认当前接口哪些可复用、哪些含 macOS 假设，避免按历史 FFI 总数逐项补空实现。要求顾问给出可区分检查、实现顺序、失败边界和验收依据。顾问不代写当前工作区，也不启动全量重测或桌面操作。

开工用 `codex debug models` 核对所指定型号与实际次高档。只读咨询模板（从仓库根执行，问题目录按实际替换）：

```bash
mkdir -p labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/platform-contract
codex -a never exec -C /Users/jiangxuanyang/Desktop/cangjie \
  -s read-only -m gpt-6-astra -c 'model_reasoning_effort="max"' \
  --json \
  -o labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/platform-contract/answer.md \
  - < labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/platform-contract/request.md \
  > labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/platform-contract/events.jsonl \
  2> labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/platform-contract/stderr.log
```

技术问题改用 `gpt-6-sol`。材料通过文件/stdin 提交，保存退出码、答复与会话 ID；有新证据的追问复用该问题会话，并按当前 CLI `resume --help` 核对参数。

普通语言问题先查仓颉技能；普通问题两次实质修复无进展即合并咨询。公共契约、核心并发、FFI/GPU 生命周期不明确时提前咨询，此类问题第一次实质修复失败后不盲猜第二方案。同一问题跨轮累计；首次咨询加一次有新证据追问仍无可靠方案，集中升级指导，其余独立工作继续。

## 工作包 A：后端入口和同源核心运行

- 核实 macOS 编辑器当前正在修改的公共文件，确定本次源码快照、工具链与独立构建目录；旧探针副本只是输入快照，公共实现回到框架。
- 选定本包实际需要的宿主/surface、场景提交、文字测量/绘制、事件与释放接缝；平台实现分开，业务不进入原生桥。
- 优先复用已有 XComponent/EGL/GLES 实验，依据当前 SDK 与 Astra 结论固定一条实际可运行的路线。已有通路不能满足真实契约时，记录原因后调整后端，避免同时铺多套渲染路线。
- HAP 必须实际装载并调用本次 CJGUI 仓颉代码，先证明组件/布局/状态/动作的返回值与版本；再接自绘。追踪到实际执行的共享源码和产物，不能仅以 ELF 文件存在或没有链接错误宣布成功。
- 能力集合只发布已实现部分；未支持能力返回明确结果，不用空成功函数通过启动。

## 工作包 B：真实自绘控件与输入

- “设置与计数”页使用 CJGUI 组件树、布局、稳定身份、裁剪、共同样式和业务 owner。
- 显示中文、ASCII、数字及至少一个混排样例。平台文字测量与实际绘制保持一致，布局由真实度量支撑；查看实际截图中的文字、按钮与边界，修正缺字、裁切、坐标比例问题。
- 触摸经过鸿蒙事件 → 平台坐标转换 → CJGUI 命中/事件 → owner → 新场景。控件位置改变或窗口尺寸变化后，仍按实际布局正确命中。
- 记录 surface 尺寸/scale、控件身份、业务版本、已接受场景与提交结果。布局接受、GPU 提交/完成和画面可见分别说明。
- 验证范围越界拒绝、禁用动作拒绝及恢复；失败不产生部分业务写入，随后合法输入仍能继续。

## 工作包 C：外部同源操作

- 复用 CJGUI 共同操作的字段/动作、授权、期望版本、结果与读回语义；平台传输可薄适配，业务规则仍只有仓颉 owner 一份。
- 完成独立客户端链：发现/读取 → 授权修改计数或启用状态 → 窗口显示实际结果 → 人再点击 → 外部读回新值。
- 反例覆盖旧版本、无效授权、未知动作/非法参数；拒绝后内容与版本按契约保持，正常请求可恢复。
- 连接方案以模拟器和普通应用沙箱的实际能力确定。`hdc` 只负责安装、驱动、取证和必要调试转发；若外部连接依赖调试转发，明确标为模拟器开发通道，普通已安装应用的连接方案仍待后续验证。
- 保留客户端请求/结果及同一运行实例身份，授权凭据脱敏。脚本调用不冒称真实模型消费，本包不强制调用真实模型。

## 工作包 D：生命周期、资源与响应

- 定义应用、窗口/surface、场景、GPU 资源的归属和代际；旧 surface 的排队输入/完成回调不能修改重建后的实例。
- 实测创建、resize、前后台变化、surface 销毁/重建、正常关闭；重建后原 owner 内容按已定应用生命周期契约保留并能继续操作。不能以整进程重启替代 surface 恢复。
- 验证受控的旧代输入/回调、提交失败与恢复；已接受业务内容不被失败候选污染。受控注入与自然系统事件分别标记。
- 在同一进程内至少做 10 次可重复的重建/恢复循环，记录活动资源、事件积压和关闭后收敛；有意保留的缓存单列，不用缓存预算冒充总内存峰值。
- 记录输入→owner、owner→场景接受/提交的同请求单调时钟数据及取样边界。正常交互和连续操作后空闲分别测，空闲不得持续重建/提交。平台存在周期唤醒时记录来源与频率，不把“零提交”写成“零空闲开销”。
- 本包建立模拟器基线及热点归因，不宣称真机性能或与 macOS 同速。明显忙等、主线程同步长阻塞及生命周期泄漏需在本包处理。

## 工作包 E：可复用交付与并行回归

- 给出框架内明确的鸿蒙后端/构建入口与独立示例；普通仓颉消费者通过该入口构建，不把实现仅留在一次性探针副本。具体目录在开工方案里一次确定。
- 提供一条可复现的构建、安装、启动及取证入口，保存 HAP、实际依赖来源、源码指纹和工具链版本。验证失败必须返回失败，环境阻塞与产品失败分开。
- 相同应用定义/owner 在 macOS 与鸿蒙各运行一次核心交互；允许宿主入口和平台呈现细节不同。公共契约修改需验证 macOS 已有消费者，文字相关变更额外检查 Pharos 所依赖的对应接缝。
- 鸿蒙构建目录与 macOS 的 `cjpm target` 分开。同一共享文件由一个执行者写入；先保存明确快照再同步，避免编辑器正在改文件时 `rsync --delete` 得到混合版本。最终汇合时只补验快照后影响本链路的差异。
- 优先用 `hdc` 驱动模拟器，减少与 macOS 编辑器争用宿主键鼠；需要宿主桌面时与正在使用桌面的执行者错开，遵守现有授权和实例保护规则。
- 开始实施时在 ACTIVE 增加本包的鸿蒙并行状态并保留 macOS 线状态；详细进展记本文执行记录，原始证据放 `labs/ohos_cangjie_smoke/artifacts/cjgui-backend/`。不复制整份历史日志到状态首页。
- 原目录开发，保留并行改动；本包不包含 Git 提交、推送、发布或旧自动化恢复。

## 集中验收与交付口径

整包完成必须交出：

1. **核心真运行**：当前 CJGUI 仓颉核心实际装载/执行，版本与来源可追踪。
2. **画面真消费**：该核心产生的场景驱动鸿蒙自绘，中文、数值、按钮和开关清晰可用。
3. **双入口同内容**：人→外部→人操作同一 owner，精确字段读回，拒绝反例成立。
4. **生命周期可恢复**：尺寸/前后台/surface 重建后继续操作；旧代不串新代，关闭资源收敛。
5. **平台可复用**：公共后端入口、独立消费者、同源 macOS 回归与可复现 HAP；不是仅演示壳成功。
6. **工具有实际参与**：Laya 的请求/原始响应/采纳理由，以及必要 Astra/Sol 咨询与落实后的验证。

报告用“已验证 / 已实现未验 / 环境阻塞 / 下一阶段”四类，逐项附日志或截图位置。未完成的核心链不能通过改成“预验证”而宣告本包完成。源码、编译、正常 HAP、工具驱动输入、人工输入、模拟器/真机、提交/实际呈现分开表述。

成功后可宣布“CJGUI 首个鸿蒙自绘共同操作链可运行”，范围止于上述能力。下一阶段承接系统文字编辑/IME、范围文本、图片资源和更完整的输入/可访问性；Pharos Mark 的鸿蒙产品移植另行安排。

## 执行记录

执行已由用户安排；2026-09-25 用户确认继续“仓颉核心 + ArkTS 薄壳 + XComponent + 原生绘制后端”。指导已完成宿主路线复核，尚未进行本包整体验收。执行者在此接续记录方案落实、重要失败和最终证据索引，不逐工具调用堆日志。

### 执行模型实施记录（2026-09-25，ZCode/GLM，A–E 完成）

方案取舍（含 Astra/Laya 采纳）：

- **装载模型定稿**：官方 Hybrid 单模块（ArkTS + src/main/cangjie + src/main/cpp 同模块）。ArkTS import 经 `ark_interop_loader` 完成仓颉运行时初始化；C++ 桥 dlsym 已加载库调原始 @C `cjgui_ohos_app_main(ingress)` 注册 ingress 函数指针并启动仓颉 spawn 应用循环。曾尝试「ArkTS entry + 仓颉 HAR」两模块拆分：构建成功但 HAP 缺仓颉运行时库（插件 `MoveCangjieLibs` 只处理 HAP 模块自身），按官方 Hybrid 模板收敛为单模块。
- **渲染路线**：OH_Drawing on-screen GPU surface（`OH_Drawing_GpuContextCreate`(16) + `OH_Drawing_SurfaceCreateOnScreen`，RGBA_8888/PREMUL；UNKNOWN 格式被拒）。渲染线程单线程拥有全部 OH_Drawing 状态（仓颉 M:N 不保证 OS 亲和）；present/measure 事务化、有界等待、超时不提交。
- **外部通道**：`shared_operation_transport` 私有 unix socket 硬编码 `/tmp`（沙箱不可写，connection.start() 失败）→ 采用 Astra 预案：应用内 loopback TCP 监听 + 公开 `connection.dispatchPayload()`（授权/版本/业务仍在仓颉 connection）；帧格式与官方一致（`<字节数>\n<负载>`）；主机经 `hdc fport`，标记模拟器开发通道。
- **Laya**（开工两问均判 insufficient）：load_model 采纳（先最小实验再定案）；render_route 的候选排序不采纳为实施顺序。`artifacts/cjgui-backend/laya/kickoff-adoption.md`。
- **Astra 咨询**（gpt-6-astra/max，exit=0）五点修正全部采纳并落实：`consultations/platform-contract/adoption.md`。

重要失败与修复（全部闭环）：

1. hvigor 静默跳过 CMake：`src/cpp` 旧布局不被 CodeMap 识别 → 迁移 `src/main/cpp`。
2. 仓颉运行时库不入包：escape SDK 对 compatibleSdk≥23 不复制 → `package_runtime_libs.sh` 按 NEEDED 闭包打包（libboundscheck/libc++.so 从 NDK 补；libc++.so 是 linker script 须用实体顶替；SDK 的 libohos.*.so 是 mock 桩，打包会遮蔽系统真身）。
3. XComponent 注册：本 SDK 头只剩 NodeHandle 变体 → `napi_unwrap` 解注入对象。
4. 启动期 SIGABRT（IllegalSynchronizationStateException）：`Mutex.condition()` 要求持锁调用，静态初始化期不可用 → 传输桥改锁保护+短轮询。
5. SIGSEGV（`__dynamic_cast` 符号冲突）：渲染器 C++ dynamic_cast 解析到 libcangjie-std-ast 同名符号 → 改枚举标签分发。
6. 增量提交语义：configure 清空候选导致未变化节点丢失/事件 projectionVersion 失配 → 播种自已接受场景并统一推进版本（Astra 预警项，实测踩中并修复）。
7. 外部 INVOKE 后画面不刷新：`windowRefreshRequested` 无人消费 → 宿主循环代为消费并 `window.requestRefresh()`。

最终证据索引：`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/`——verification/verification_summary.md（集中验收六项+分类收口+诚实边界）、external_chain_evidence.json、lifecycle_cycles.log（10 销毁+11 创建代际）；consultations/、laya/、snapshot/（指纹 94dd3833…）、build/、run/、screenshots/（a1 探针、b1 首帧、b5-b7 触摸递增、c1-c2 外部可见、d1-d3 循环后、e1 macOS 同源）。macOS 同源回归：examples/settings_counter_window_app + client.py get/invoke（v1/count11、stale version_conflict）。

保留边界：系统可编辑文本/IME、范围文本、图片资源、非空命令菜单/数据传输、悬停按压视觉层、真机与性能基线、普通已安装应用的沙箱外连接留待下一阶段；显示器实际呈现以模拟器 framebuffer 截图为准。

## 指导复核与接续要求（2026-09-25）

**结论：上述执行记录为执行者自报，A–E 整包未通过指导验收。** 仓颉核心装载、组件场景驱动自绘、公开请求进入共享 owner，以及同进程 surface 挂载/卸载已有实际进展；固定路线继续。下列返工与原定公共交付由页末接续包承接，基础系统文字输入同步推进；未验收只阻塞具体依赖，不能阻止整个下一阶段开工。

本次审查读取源码、原始请求/日志、截图和构建产物；未重跑构建、应用或性能测试。源码审查发现的竞态与关闭问题需先建立受控运行反例。读取的 host/renderer 指纹分别为 `0ed00d230e0fa2f354bf1b68a282ad070e6bd1d386f6b7b9c0d7806eea55369c` / `36ebb91ec49daba1e346a1433fd32723d2221be84466a3ccefd01e7e7cfd21a4`，后续修复按实际新指纹对照。

### 1. 并发请求必须绑定各自结果（P1）

源码：`labs/ohos_cjgui_app/entry/ohos_transport/src/ohos_transport.cj`，`call` / `takeRequest` / `putResponse` 与 listener。

每个连接独立 spawn，但所有请求共用一个 `pendingRequest` 和一个 `pendingResponse`。B 可覆盖尚未被 owner 取走的 A；任意等待者可取走别人的回包。超时不撤销待处理请求，也没有区分晚到结果的身份。owner 串行并不能保证传输请求归属。

实施思路：使用有界请求队列，每项带应用实例、单调请求 ID、绝对单调 deadline、状态及独立结果。由 owner 取具体请求并完成对应票据。最小串行实现也必须显式排队或返回 busy，不能无条件覆盖共享槽。区分「尚未执行而取消」「已经应用但调用方未收到结果」，后者不能谎称业务拒绝；按票据查询或明确不确定结果，避免重试二次应用。关闭时拒绝新入队，唤醒等待者并关闭 listener/client；核对实际 bind 地址与 loopback 声明一致。

反例：两条真实 socket 并发发送不同动作并在 owner 取队列前设闸，分别核对请求、回包及精确业务结果；A 超时后再投 B，释放 A 的晚到执行/结果，证明不串包、不丢请求且无未报告的二次写入；队列满与关闭中请求有明确终态。

### 2. 超时、提交与 surface 退役需有共同的提交边界（P1）

源码：`entry/src/main/cpp/ohos_renderer.cpp`（`WaitableJob`、`executePresent`、`present_composable_scene`）与 `cjgui_host_bridge.cpp`（`ingressSurfaceActive` / `onSurfaceDestroyedImpl`），路径均相对上述 lab。

当前 `waitFor` 超时返回错误，但任务无取消状态，渲染线程之后仍可 `SurfaceFlush`；调用方保留旧 accepted，画面却可能来自失败候选。超时任务有意不释放，队列/存活数量也没有上限。surface ingress 仅在锁内复制裸 window 指针，离锁排队后没有引用保护、退役屏障或提交前代际复核；旧任务成功后仍能晋升 accepted。

实施思路：为任务定义 queued/running/提交中/终态及唯一票据，以 RAII/共享所有权确保调用方超时后工作线程仍能安全回收。取消确认、平台提交和 accepted 晋升须有明确的一次性裁决点。仅多加一次 `if cancelled` 无法消除检查与 Flush 之间的竞态。排队或可取消准备阶段超时应确认取消后再报告拒绝；已进入不可取消平台提交的任务，不能在结果未定时返回“拒绝且不可能显示”。若现有同步 ABI 无法表达该状态，先聚焦咨询提交协议，说明返回边界与兼容处理后落实。

Surface 使用可验证的 lease，至少关联应用/session、组件与 window、surface generation；窗口存活保障须依据本 SDK 可用的引用/同步退役机制，不能只给裸指针增加编号。销毁先退役，取消旧代排队任务，平台资源在其所属渲染线程释放；旧代完成不能提升新代 accepted 或帧号。尺寸变化也需可辨别的几何修订。

反例：① 阻塞 Present 至超过等待上限，API 返回拒绝后再放行，验证无晚到 Flush/accepted 变化且任务回收；② 取得 lease 后暂停、销毁重建再释放旧任务，验证旧代不访问退休目标、不推进计数，新代可正常提交；③ 连续多轮超时/失败后任务、队列和资源收敛。若平台提交已不可取消，该分支必须用真实终态或明确未定状态验收，不能沿用“已拒绝”口径。

### 3. 正常退出与 surface 暂时消失分开处理（P1）

当前 `StopHost` 只写日志，`AppShutdown` 只清前台标记；native 的 close/stop 标记没有消费路径，`ShutdownJob` 未被投递。`renderer_destroy` 只清 session 容器。仓颉 owner 循环、阻塞中的 TCP accept、GPU surface/context 与渲染线程尚未形成停止链。

实施思路：surface 卸载保留应用 owner，真正 Ability shutdown 则进入一次性应用停止协议：停止接单 → 请求 owner 退出并处理待决票据 → 唤醒/关闭传输 → 在渲染线程释放 surface/context → 线程退出确认 → 清除当前启动身份。明确每步完成者，避免 UI 回调与等待者互相阻塞。相同进程再次打开应创建新实例身份并能工作。

反例：正常关闭 Ability 但保留进程，记录 owner/listener/session/job/GPU 资源退出；随后同进程重开并完整操作。杀进程清空资源不能代替此验收。

### 4. 真实绘制消费共同颜色与裁剪（P2，原 B 必需项）

`ohos_renderer.cpp::layoutText` 当前将文字色写死为 `0xFF000000`，没有消费节点 `textRed/Green/Blue/Alpha`。共同应用定义是浅色字，`d0_external_count11_visible.jpeg` 与 `d3_cycles_tap_final.jpeg` 却是深背景黑字；这不是已验收的暗色效果。绘制循环也未消费节点 clip 字段，需要补齐原定裁剪契约。

接通 accepted 节点的实际前景色和裁剪到 OH_Drawing；测量与绘制共用字体/宽度语义，颜色不能由后端重新指定。用同一控件切换两种已声明颜色，核对场景值与窗口像素；再缩小内容区，让越界文字、按钮背景及命中范围按既有裁剪规则一致变化。修复属于通用后端，不只修改示例背景掩盖问题。

### 5. 完成原 D/E 交付并重新绑定证据

- **同实例 C 链**：当前保存的 `external_chain_evidence.json` 为一次串行探针输出，不能支持摘要所称两次完整 run 与 `15@v9 → 人点击 → 16@v10`。`c1` 是初值画面、`c2` 是模拟器桌面；`d0`/`d3` 确有应用计数，但不能仅凭文件名补齐中间因果。修复后在同一明确实例保存外部修改前后请求、实际画面、工具触摸以及精确公开读回；每轮单独存档，摘要引用实际值。
- **原 D 基线**：真实尺寸变化、前后台、受控旧输入/提交失败、10 次恢复中的资源/事件积压、关闭后收敛仍需补齐；记录同请求输入→owner→accepted/submit 的单调时钟样本，普通负载、连续操作和 idle 分开。模拟器响应基线是本包任务，不能并入“真机性能”延期。先记录周期唤醒的真实开销再决定改进，不凭零提交宣称零空闲成本。
- **公共后端消费**：`platforms/ohos` 当前只有 README，实际入口还硬依赖 `artifacts/cjgui-backend/snapshot`。保留已工作的实现，收敛为框架拥有的宿主/后端/构建适配，实验应用消费该入口；构建输入应来自明确的框架版本/导出，验收 artifacts 只存证据。独立副本从公共入口构建时无需作者实验目录或历史取证目录。
- **最终产物身份**：manifest 覆盖核心、应用、桥接、ArkTS、构建脚本、依赖及相关生成输入。保存的 HAP 与当前 build HAP 已存在差异（含仓颉应用库和 ArkTS 字节码）；重新冻结最终输入及 HAP hash，安装/日志/截图绑定该产物，不能把旧截图当新包通过。
- **入口失败判定**：`build_and_run.sh` 目前对必需库用 OR 匹配、缺失只警告，启动后打印历史日志就返回成功。改为逐项验证依赖闭包，按本轮启动身份断言核心、场景与所请求验收结果，缺库/未启动/旧日志冒充均返回失败，并有相应负对照。
- **工具结论按实际记账**：现有 Laya 开工记录有效；尚未见新失败族与交付前的要求记录。针对本次并发/生命周期事实合并作一次有内容的 Laya 辅助判断；由原规则对应顾问聚焦审阅请求归属、提交与退役/关闭协议，再实施。交付前按实际证据摘要复核，保留原始答复及采纳理由；不追写虚构的历史调用。

本次返工与公共后端交付继续组成一个完整工作包。沿用共享核心、设置与计数 owner、官方装载和固定渲染线程；已有成功用例按新改动影响复用，集中验证改变的边界及最终完整链。完成后逐项报告“原先缺陷如何复现、修复后如何被区分验证、最终产物身份、仍未验范围”。本节补充原 A–E 验收要求，不启动新的独立任务或恢复暂停自动化。

## 当前接续包：必要返工与基础文字编辑同步推进

**用户最新决定（2026-09-25）：修上一轮的问题时，同时推进下一轮能力；只有确实依赖未修底层的实现或验收才等待。** 指导据此将本次安排为一个完整包：上述五类返工、原 D/E 公共交付，连同下述基础文字编辑一并实施。发现问题是开发过程的一部分，验收结论用于明确依赖和风险，不作为全线停工闸门。

### 新能力与复用范围

下一项选择**鸿蒙基础单行文字编辑与系统输入法接入**。组件/布局已有基础，语义动作已有 owner，当前最直接的通用缺口是人能真正编辑文本。文字接入同时检验输入、绘制与资源生命周期，公共构建交付承接普通开发者入口；图片、复杂菜单和更完整生成组件移植后续按实际需求安排。

- 复用 `runtime/cjgui/src/composable_ui.cj` 的 `cjguiComposableTextInput`、`composable_ui_window.cj` 的身份/事件/编辑接续机制、`shared_operation_core/src/shared_editing_form_contract.cj` 及既有字段规则。macOS 文字桥作为行为对照，鸿蒙按实际 SDK 实现系统服务适配。布局、业务与字段规则继续由仓颉持有，ArkTS 保持宿主职责。
- 在设置与计数共享应用增加一个真实名称字段，字段定义、校验、版本及修改操作只维护一份。即时生效或草稿/应用模式由应用明确选择，人的输入与外部操作消费同一入口；系统组合态与业务已应用值分开。相同仓颉定义在 macOS 与鸿蒙消费，作为跨平台复用证据。
- 完成单行输入、点击定位光标、选区替换、插入/删除、焦点切换与禁用。明确仓颉字符串、平台偏移与字形命中之间的转换单位，用中文、ASCII、emoji/组合字符验证，避免拆坏字符或把视觉位置当字节索引。
- 接通系统输入法的键盘显示/隐藏、编辑内容与选区同步、组合输入提交/取消、光标/候选位置，以及失焦、后台和关闭时的处理。以本机 SDK 头文件和官方示例核实接缝；复用系统输入法服务，自绘仍由 CJGUI 提交。平台编辑缓冲是交互投影，不另建业务 owner。
- 外部更新正在编辑的字段时，沿既有编辑契约明确版本、选区与组合态处理；旧输入上下文在换绑、禁用、重建或关闭后失效。随后合法的人类输入必须能够接续。不得靠清空字段或强制每次重建应用规避连续性。

### 按依赖推进

| 工作 | 可以立即推进的部分 | 必须等待的具体依赖 |
| --- | --- | --- |
| 共同名称字段与编辑规则 | 仓颉 owner、声明/校验、偏移转换、同进程公共操作反例、macOS 对照 | 独立外部客户端验收等待请求归属修复 |
| 系统输入适配 | SDK 接缝核实、输入上下文与事件转换、选区/组合态逻辑和受控测试 | 重建、失焦交错与关闭反例等待对应 lease/退出协议落实 |
| 自绘文字、光标与选区 | 字色/裁剪返工一起做，接入候选与 accepted 投影 | 超时后显示/命中一致性验收等待提交协议修复 |
| 人—外部—人接续 | 先用同进程真实 owner 入口验证版本和冲突规则 | 最终 socket→owner→画面→系统输入链等待传输及相关呈现边界修好 |
| 公共构建与证据入口 | 提取平台入口、完整 manifest、失败负对照、独立消费与计时点 | 最终 HAP 汇合验收等待本轮相关实现就绪 |

某个依赖修好并通过针对性反例即可继续它的后续工作，无需等全部旧项完成或等待指导再次放行。若新证据表明某条开发路径本身会访问已退役对象、污染状态或依赖尚未确定的公共契约，暂停该路径，继续表中其他工作，并在现有执行记录写明具体依赖。

“同步推进”指工作安排可以交错或合理并行，不要求多代理同时改同一文件。主执行者统筹 native 渲染/宿主写集、同一 target 构建和模拟器使用；独立字段、测试与构建适配可拆完整工作包。沿用 Laya 辅助判定与现有顾问咨询要求，将新输入上下文和提交/退役之间的契约问题一起带入聚焦审阅。

### 集中验收

1. 修复上述返工反例并完成原 D/E 仍缺的基线与公共消费；已有未受改动影响的证据沿用，不逐小步重跑全套。
2. 同一实例：工具驱动系统键盘编辑名称 → 公开读回精确字段 → 外部授权改名 → 自绘显示实际结果 → 用户侧继续选区替换/输入 → 再次公开读回。输入驱动类型如实标注。
3. 系统输入法真实组合输入、提交/取消与焦点转换单独留证；直接注入已完成文本或程序化组合仅覆盖各自路径。环境确实无法驱动时记录具体未验范围，继续其余工作，不将 IME 标成通过。
4. 文字编辑中的拒绝、禁用、surface 重建、后台/前台及正常关闭由针对性反例覆盖；旧上下文不写新字段，合法输入恢复，资源收敛。
5. 最终同源 HAP 完成输入和基础链，名称字段的 macOS 同源核心交互也通过。源码/单测、受控注入、系统输入、提交与画面证据分别列明。

完成后一次集中报告返工结果、新增能力、最终产物和真实欠项。独立新能力已完成而某项仍有具体阻塞时，保留可验收成果及依赖说明；不把整个包改成只有返工，也不将未通过项目记成完成。

### 接续包实施记录（2026-09-25，ZCode/GLM，返工与新能力同步推进）

#### 咨询与 Laya（先于实施）

- **Laya 第二次判定**（`artifacts/cjgui-backend/laya/rework-{request,response}.json` + `rework-adoption.md`）：first_fix=insufficient（采纳为"交错推进"佐证）；commit_timeout 的 block_until_done（0.38）**不采纳**——与 P1 反例①（超时必须返回）冲突且有 owner↔渲染线程互等死锁风险；采纳"queued/running 超时=确认取消拒绝，committing 超时=PENDING 未定"组合。
- **Astra（gpt-6-astra/max）请求归属**：`consultations/rework/request-attribution/`。票据队列协议（Pending→Executing→Done/Cancelled、Cancelled≠Abandoned、单次认领不预标、server_busy、三个桥接原因码、自连接唤醒 accept、Closed 判据、R1–R8 反例）全部采纳。
- **Sol（gpt-6-sol/max）提交/退役/关闭**：`consultations/rework/commit-retirement-shutdown/`。票据阶段机（committing 线性化点=Flush 前最后屏障、PENDING=20、三处取消检查点、Flush 后代际复核、surface 卸载≠应用退出、关闭链五步归属、测试宏注入建议）全部采纳；"版本化 present 输出票据"简化为每 session 单未确认提交+查询（偏差已记录）。

#### 返工结果（缺陷→修复→区分验证）

1. **传输并发归属（P1）**：旧实现共享 pendingRequest/pendingResponse 槽（B 覆盖 A、等待者互抢）。重写为票据队列（`ohos_transport.cj` v2）：一帧一票一连接、每票独立结果槽、owner 单张认领、超时三态（not_executed/outcome_unknown/closed）、server_busy、requestStop/awaitClosed 自连接唤醒。**区分验证**：`transport_concurrency_evidence.json`——并发对立动作恰好一应用一冲突且版本精确 +1；6 并发同版本恰好 1 成功（版本增量=成功数）；旧版本 version_conflict；外部 EDIT_NAME 精确读回。
2. **提交边界（P1）**：WaitableJob 加阶段机（queued/running/committing/Done/Cancelled）；三个取消检查点（出队/资源就绪/Flush 前同锁屏障）；Flush 后代际复核（旧代不得晋升）；committing 超时返回 PENDING(20)（核心白名单不含→保留 accepted 不重试）。**区分验证**：反例①②的注入钩子（阻塞 Present）未接——设计已落地（阶段机+取消点+PENDING 路径可观测），受控反例脚本列为未完项。
3. **关闭链（P1）**：requestApplicationStop 置位 → pump_event 优先返回 CLOSE_REQUESTED → 核心 discardSession → owner 循环退出 → transport requestStop+awaitClosed → ohos_renderer_shutdown_render_thread（ShutdownJob 等待渲染线程 teardown surface/GPU context 后确认）→ bridge AppShutdown 编排。**区分验证**：编译+运行链路验证（正常启动/停止不再残留 owner 泵日志）；"同进程重开"反例因模拟器无 graceful-destroy 驱动手段（aa force-stop 杀进程）列为未完项。
4. **颜色/裁剪（P2）**：渲染器消费节点 textRGBA（不再写死黑）+ 完整裁剪链（clipConstraintCount 1..4 或退回单 clip，圆角 ClipRoundRect）。**区分验证**：计数 10 金黄（文本色生效，`h*` 截图系列）；越界裁剪反例待做（列表/滚动消费方进入时）。

#### 原子名字段与新能力

- **字段定义/规则/版本**：settings_counter_application 增 name 字段（1–32 UTF-16 码元，越界 name_out_of_range，即时生效模式），EDIT_NAME 动作+授权 scope；人的 28 事件与外部 INVOKE 走同一 execute/版本契约。
- **系统输入法接入**：C-API IME（TextEditorProxy+Attach）在本镜像 Set* 为崩溃桩（SEGV 证据 `cppcrash-…152900952.log`、`…153600640.log`），按任务允许改走 **ArkTS TextInput 代理**：透明输入框覆盖名称区（系统键盘/组合/候选/焦点由平台保证），onChange=预览（编辑缓冲视觉层+末帧重绘）、onSubmit/onBlur=提交；焦点请求经 napi threadsafe fn 由渲染器命中触发。组合下划线绘制于 CJGUI 自绘字段（`h1_ime_preview_composing.jpeg`）。
- **人→外部→人链（同实例）**：人编辑 commit→owner v1「鸿蒙鸿蒙。」→外部精确读回→外部 EDIT_NAME 改名→v2「外部改名-山海」**画面更新**（`h3_external_rename_visible.jpeg`）→人重新聚焦，编辑缓冲从新值起步（`h4_refocus_buffer_synced.jpeg`）。**已暴露并记录的缺陷**：人在编辑中被外部改名后的首次提交被 stale-identity 契约拒绝（明示状态"事件 28 原控件已刷新"）——符合 macOS 同款语义，但"编辑中无感接续"需接通核心 pendingLocalText 机制（鸿蒙桥未喂 preservesActiveLocalText），列为未完项。
- **输入路径如实记录**：文本输入经 `uitest uiInput inputText`（程序化注入，覆盖 TextInput→onChange→预览/提交链）；**系统 IME 真实组合输入**（物理键盘敲键→IME 组合→候选）未能在工具路径捕获（键盘点击坐标空间误差与输入法内部组合时序），组合预览的绘制/取消路径由 onChange 预览链证明；此边界如实标注。

#### E 交付

- **框架自有快照**：`runtime/cjgui/platforms/ohos/snapshot/`（指纹 `35f2e76c…`），构建输入不再依赖 artifacts 取证目录；`build_and_run.sh` 改从该快照同步。
- **严格构建入口**：逐项校验 9 必需库闭包（缺一即失败）；启动断言（本轮日志必须含 owner 启动+场景提交）；负对照=缺库即退出（未注入伪造库测试，列为未完）。
- **最终身份**：HAP sha256 `687f678067e94e7af60f1c22d3316500a6b901da7e32687eb8278cebdeb72364`（`build/entry-default-unsigned-FINAL.hap`）；源码 manifest 395 项（`build/source_manifest_final.txt`）；启动/运行日志绑定该产物。

#### macOS 同源回归

同一 domain/controller 在 macOS（AppKit/Metal）：EDIT_NAME 应用（name_changed）+ 精确读回（UTF-16 十六进制 `6D61634F53…`）+ 空值越界拒绝（name_out_of_range）+ 旧版本 version_conflict——与鸿蒙同语义同拒绝码。

#### 未完成清单（具体依赖）

1. 提交边界受控反例（阻塞注入钩子）——依赖测试宏构建变体；协议已落地可观测。
2. 同进程重开反例——依赖模拟器 graceful-destroy 驱动手段。
3. 编辑中外部改名"无感接续"——依赖接通核心 pendingLocalText/preservesActiveLocalText 机制。
4. 裁剪反例（越界内容/命中随 clip 变化）——依赖滚动/列表消费方进入。
5. 系统 IME 物理键盘组合输入留证——依赖可驱动的真实键盘事件路径。
6. build_and_run 缺库负对照注入。

## 第二次指导复核与当前完整工作包

2026-09-25。指导只读核对实际工程 `labs/ohos_cjgui_app/`、平台快照、现有原始证据与截图；未构建、未运行模拟器或重跑测试。当时结论：**路线保持，首轮接续有真实进展，整包仍进行中；提交/关闭/传输/输入存在源码缺陷，不只是等待环境补验。** 本节保留为第二次复核记录，当前实施依据已更新至页末第三次复核。

### 已保留成果与证据更正

- 票据化方向与正常并发 CAS 证据保留：现有 JSON 支持请求独立回包、同版本竞争恰好一次应用，不覆盖取消、慢连接、关闭重开。
- 字色已经消费真实节点值；平台自有核心快照移除了 artifacts 作为核心源码输入。395 项 manifest 与所列当前文件逐项相同，FINAL/last/当前 build HAP 同为 `687f678067e94e7af60f1c22d3316500a6b901da7e32687eb8278cebdeb72364`。所列文件一致不等于完整构建输入已经覆盖。
- `h3_external_rename_visible.jpeg` 实际是空名称框与“事件28的原控件已刷新”；`h4_refocus_buffer_synced.jpeg` 才显示“外部改名-山海”。后者能证明重新聚焦时的可见值，不能替代继续输入、成功应用、再公开读回这一段。
- ArkTS TextInput 可继续作为系统文字服务代理，CJGUI 仍负责自绘和仓颉 owner。现有 `onChange` 全量文本预览不是系统组合态证明；C-API 两次崩溃只保留为本机复现，尚不足以断言平台 API 是未实现桩。若继续该归因，补最小官方契约用法、链接来源与原始 faultlog；这不阻塞代理路径实施。
- 当前 `macos_regression_evidence.md` 仍为旧计数操作，新名称字段回归原始请求/结果待补。普通模拟器基线、公开平台消费与真实 IME 项继续承接。

### A. 任务、提交与 surface 生命周期返工

源码重点：`entry/src/main/cpp/ohos_renderer.cpp` 的 `WaitableJob`、所有 `waitFor()` 调用方、`executePresent`、`present_composable_scene`、shutdown；`cjgui_host_bridge.cpp` 的 surface ingress 和应用停止入口。

已确认的实现问题：

1. `waitFor` 已由 Bool 改成状态码，但测量、自然高度、caret 和 shutdown 仍用 Bool 判断，OK=0 被当失败。必须逐调用方改成显式状态判别，验证成功和超时两侧，而非只修 present。
2. queued/running 超时只改 Cancelled，present 随即 delete 仍被队列/线程引用的裸指针。取消检查和进入 Committing 分两次加锁，取消可插入两者之间后仍 Flush。
3. PENDING=20 没有可查询的原票据与核心结算路径；核心仍回滚候选，native 晚到 Flush 可能与 accepted/命中分离。
4. ingress 复制裸 window，退役只设置 active；Flush 后检查的 boundGeneration 是该任务自行绑定值，没有保护宿主当前 lease。
5. `AppShutdown` 只置前后台标记，未调用已解析的停止函数。worker 删除 ShutdownJob 却不 finish/notify，等待者又访问并删除；线程退出确认与重启身份复位尚未闭合。

实施方案：

- 队列、执行者、等待者与结果表共用明确的票据所有权，等待超时只结束等待，不能释放工作线程仍访问的对象。终态与回收各有唯一责任方；队列、在途和终态保留有界。
- 在同一临界区完成“确认未取消 → 转入 Committing”，返回可提交许可；未取得许可不得 Flush。准备可取消与平台提交不可取消分开。
- 将 pending 纳入实际 window/session 提交契约：保存候选和票据身份，通过 owner 正常循环取得最终结果，一次性 commit/rollback 并校准 accepted/命中。只增加 native 状态码不能构成交付。并行 Mac 正在使用公共接缝，先确定最小兼容方案和写集，再做针对性回归。
- surface lease 包含应用/session、component/window 与代际，依据 SDK 建立实际存活引用和退役屏障。退役先停止新使用，旧任务在合法存活范围结束，资源由所属渲染线程释放；提交裁决核对真实 lease，UI 回调不等待需要 UI 自己完成的工作。
- 真正关闭接通停止请求、owner 退出、传输与在途任务收敛、GPU teardown、线程 finish/join，之后释放启动身份；surface 暂时卸载仍保留 owner。

反例：queued 超时、最后取消点交错、Flush 内超时后最终结算、旧 lease 取得后销毁同尺寸重建、连续失败后的回收、measure/caret OK 与失败、空闲/queued/committing 三时机 stop→await→同进程 boot。通过自有测试入口调用同一生产停止协议，不必等待模拟器新增 graceful-destroy 命令。测试宏和可控闸门是本包实施工作，不记成外部环境依赖。

### B. 传输的真正有界与重开隔离

`entry/ohos_transport/src/ohos_transport.cj` 仍有三类缺口：accept 后无上限 spawn、header 无换行可持续增长；等待者取消不扣 queuedBytes/移除队列，claimNext 又跳过 Cancelled；Closed 只等 listener，旧 worker 通过全局 ctx 可进入新实例。

在创建 worker 前落实连接额度；读入前限制 header/帧大小，使用整帧绝对单调期限及关闭检查。统一锁内取消、出队和额度释放，任一路径只结算一次。worker、票据、lease、listener 的终结回调固定绑定其创建 context；Closing 不能被新 ctx 替换，Closed 包含 listener、连接、执行票据全部终结。

验证：超过连接上限的滴流与无换行 header；暂停 owner 让两批各8票超时后恢复，正常请求能再次应用；旧连接半帧→stop/await→重开→补旧帧不得进入新 owner。保留正常 CAS 证据，重点补这些此前未覆盖的反例。

### C. 新能力：通用系统文字代理与双字段接续

把现有名称演示升级为可被普通仓颉应用复用的文字服务适配，与 A/B 交错推进。当前原型的问题包括：ArkTS 每次聚焦把代理文本设为空、代理几何写死为 y=380、焦点出口写死 name；提交/预览不带会话身份，而 native 选择任意第一个 editing session；没有选区或真实组合态同步，所有 onChange 都被标成组合预览。仅接 pendingLocalText 不能解决这些问题。

- 复用已有字段定义、核心 pendingLocalText/身份与自绘机制。以不透明编辑上下文标识连接平台代理与 accepted 控件，至少关联 session、节点/绑定、编辑代际与基版本；所有延迟焦点、文本、选区、组合与失焦回调携带并校验该上下文。
- 从当前 accepted 值和选区初始化代理，几何随 accepted bounds、窗口密度和内容原点更新。平台绘制的代理承担系统文字服务，CJGUI 显示同一交互投影；名称/业务字段不进入后端硬编码。
- 分清普通编辑变化、系统组合预览、提交和取消，提交/失焦重入只结算一次。即时应用或显式提交模式由应用明确声明，拒绝后恢复可解释状态；不凭 onChange 事件虚构系统组合区间。
- 接通选区、点击定位、替换、删除、中文/emoji/组合字符的单位转换。外部改值后保留合法本地草稿或显式冲突，并能继续编辑成功；旧会话回调不得改写新焦点或另一字段。
- 增加一个独立仓颉消费方或 UI-only 双字段表单：不同名称、几何和规则由应用声明，使用同一后端。验证 A 编辑→切 B→A 晚回调、禁用/移除/重建，以及外部改值后人的第二次提交与精确读回。该项检验通用能力，不以增加业务界面功能为目标。

系统 IME 单独验收：通过系统键盘/候选形成真实组合过程并提交/取消；程序化 inputText 仅记录对应路径。工具确实不能驱动的部分保留未验，不等待它才推进其余工作。

### D. 绘制与命中一致，补原性能基线

现有 clip fallback 仍读 clip0 而非单 clip 字段，零尺寸约束被跳过；hitTestAccepted 完全不检查 clip。统一绘制与命中的有效裁剪，空交集必须不可见且不可命中，圆角边界按既有核心语义消费。

用现有容器即可建立文字/按钮跨边界、空交集、圆角、尺寸变化夹具，无需等待新的滚动/列表组件。核对像素、场景与内外触摸的结果；测量成功路径回归后再确认绘制/光标几何一致。

补原 D 的真实 resize、前后台、恢复、普通操作与连续文字输入基线，记录同请求 input→owner→accepted/submit 单调时钟、样本、周期唤醒和资源收敛。模拟器数字如实列出，不替代真机性能，也不把零提交当成零唤醒成本。

### E. 公共平台消费与可信构建验收

- 将宿主、renderer 与构建适配收敛至框架拥有的公共平台入口；lab 消费该入口。当前只把核心快照搬到 platforms 不等于完成后端独立消费。
- 实际 ELF 依赖闭包加明确系统库白名单驱动校验，ZIP 路径精确匹配。当前脚本列8库却报9/9，且漏 app 实际使用的 transport/domain 库；从实际依赖得出集合。
- 启动前分配运行标识，记录安装 HAP 指纹、本轮 PID/实例与日志起点；当前 START_TS 未使用、grep 历史 hilog 可假绿。补“缺必需库”和“新启动失败但旧日志成功”负对照。
- manifest 补脚本、配置、链接桩、打包依赖及工具链身份。冻结最终产物后绑定安装、日志、截图和消费者；独立目录从公共入口构建运行。
- macOS 名称字段补当前同源定义的原始读写与拒绝证据。人→外部→人最终链必须落到最后一次 owner 变化和精确公开读回，截图命名或重新聚焦不代替最后一步。

### 执行、依赖与收口

主执行者维护一个完整目标，沿用现有成功资产。A 的生命周期反例先于依赖它的最终交互验收；B 的协议测试、C 的字段/代理上下文与独立消费者、D 裁剪夹具、E 构建负控均可独立推进，互不形成全线停工条件。

本次指导已给出实施方案与判别反例。对实际 pending 公共契约和 lease 方案，用原 Astra/Sol 咨询材料附上此次代码差异聚焦复核；顾问结论必须与实际调用方逐项接通。Laya 用于具体方案辅助选择，不能把建议、注释或通过编译当成状态机已运行的证据。按 AGENTS 协调共享写集、target 构建和模拟器，不唤醒旧任务或自动化。

仅在 A–E 必需项及最终同实例链达到要求时收口；不能把测试闸门、同进程关闭入口、简单裁剪夹具当外部环境阻塞。集中报告已交付、源码缺陷修复前后反例、精确欠项和最终产物身份；沿用未受影响证据，避免逐小步重复全套。

## 第三次指导复核与当前完整工作包

2026-09-25。依据第二轮报告，指导读取当前平台源码、应用调用方、T0–T8/B1–B4 原始记录和构建入口，并重新校验哈希；没有编译、重跑产品测试或操作模拟器。**路线继续，整包进行中。当前存在源码缺陷与未交付能力，不能概括成“源码都修好了，只差测试”。** 本节取代上节的当前实施清单，前文保留为历史与原始要求。

### 本轮接受的进展与证据边界

- `JobRef/shared_ptr`、取消检查与进入 Committing 的同临界区许可、显式状态码判别有实质改进；旧的裸 job 释放问题不再原样派单。受控时序及调用方的最终行为仍须验证。
- 连接准入、header/整帧限额、取消扣账、worker 固定 context 已接入。B3 日志确实是两批各8票的**服务端**取消与恢复后应用成功。B4 实际只等半帧到期，没有关闭重开；B1 未严格断言拒绝数，B3 将客户端超时也计入未执行，B4 将 socket timeout 当关闭，须收紧。
- `effectiveClips` 已共用于绘制/命中；宿主/renderer/脚本已有平台归属。保留这些成果，继续补实际裁剪反例和独立消费。
- 正常 run `run_20260925_174710` 的462个清单输入逐文件哈希全部相符；当前 build 与 last HAP 同为 `c7fa95d96faf5822035e71323dfcdadb2b12b0d9cd9591f1bd78f07f5d3a5d33`。`FINAL.hap` 仍是上一轮 `687f6780…`，只作历史产物；新的验收通过统一 run 身份关联，不能混用。
- C 暂不收口。T4 的 `match=1` 来自 native 编辑缓冲查询，不是 owner 确认。T7/T8 止于“事件28的原控件已刷新，输入未应用”及外部值显示，未完成合法人的再次写入，也不能直接把这条原因改称业务 `version_conflict`。现有脚本只操作 name，定义了 alias 坐标不等于验证了第二字段。

### A. 原候选结算、surface 存活与真正关闭

当前主写入口为 `runtime/cjgui/platforms/ohos/host/`，lab 下 C++ 是同步副本；核心变更先核对 `runtime/cjgui/src/` 与平台 snapshot 的对应版本，并协调 Pharos Mark 的共享写集。

**A1：PENDING 要恢复原事务，不能再建一份候选。** 当前核心 `notePresentPending()` 仅置刷新标记并返回 false；下一轮重新 `beginSceneRefresh/beginCandidate`，原 identity 候选尚开着，因而在到达 native 结算前拒绝。首次启动还会把 false 当失败直接销毁 session。原生虽保存了票据，完整调用链仍不成立。

实施：把待决提交作为窗口/session 中明确的事务记录，保存原 root/paint scene、participant、identity/viewport/资源候选及原版本、原票据与实例身份。在正常 pump 中先查询该票据的终态；Pending 继续等待，Accepted 对原候选恰好提交一次，Rejected 对原候选恰好回滚一次。新 owner 变化保留为下一次刷新，不能在未定候选上重新 begin/build 或替换 participant。首次启动增加可观察的 starting-pending 状态，等待最终结果后再进入可交互状态；现有同步 macOS 成功/失败语义保持兼容。关闭中的未定票据也须有归属和终结路径。

判别：闸门分别卡住首帧和正常窗口 Flush，让等待方拿到 PENDING；期间插入新 owner 修改，再放行。要求旧候选仅结算一次，随后新版本正常提交，无 `identity_candidate_already_open`、首帧误销毁、重复提交或 native/核心 accepted 分叉。同时覆盖 native 最终失败与 close 交错。

**A2：surface 需要真实存活许可。** 当前 `leaseValid` 检查后即用裸 window 创建/绘制，`busyGeneration` 到 Flush 前才置位，且位于测试闸门之后；destroy 最多等400ms就返回。这只能部分限制晋升，不能保证创建、绘制、Flush、teardown 期间句柄存活。

实施：宿主在同一同步边界内完成“验证当前 lease → 获取平台对象引用/使用许可”，许可带应用/session/component/window/代际，覆盖所有使用阶段。退役先禁止新许可，旧引用由明确线程在最后一次使用后归还。当前 SDK `external_window.h` 已提供 `OH_NativeWindow_NativeObjectReference/Unreference`，并标明非线程安全；先验证对象类型、串行调用及配对规则。**保住对象引用不等于 surface 始终可提交**，仍须按平台退役语义校验提交许可/返回码，不把检查有效或等满固定时间当销毁许可。UI 回调与 renderer 的退役协议须避免循环等待。

判别：在取得 lease 后、创建/绘制中、Flush 前和不可取消提交内分别销毁并同尺寸重建。记录许可/引用获取释放、退役和最终提交身份；旧代不得推进新代 accepted 或命中，资源只回收一次。测试入口是本包实现内容。

**A3：surface 卸载与应用停止分流。** 当前 `Index.ets` 的 XComponent `onDestroy` 仍调用 `stopHost`，而它现已真正请求应用停止；`g_appStarted` 又只有置 true，没有关闭完成复位。因而原 `CYCLE×10` 不再能沿用为当前版本生命周期证据。

实施：surface 卸载只退役 lease，owner/传输会话存活；Ability 退出或明确应用 stop 才停止接单并收敛 owner、连接、票据和 renderer。用明确启动/运行/停止中/已停止状态避免提前重开；只有实际退出全部确认才释放启动身份，启动失败也须恢复可重试。创建新应用实例时换代，旧回调不得影响新实例。不要只复位 Bool 而漏掉仍活线程或 Cangjie owner。

判别：同进程连续卸载重建保持 owner/version且之后能触摸和外部修改；空闲、queued、committing 三时机真实 `stop→await→boot` 分别成功并回收全部自有任务。两个生命周期路径分别取证。

### B. 安全的测试接缝与传输终结

**B1：先隔离新增暂停闸门。** `serveFrame` 在正常 submit/授权之前 `contains("PAUSE_CLAIM")` 即暂停认领；没有测试构建条件，普通字段值包含该串也可能被吞掉。移除条件注释不构成隔离。

实施：使用显式测试构建的独立控制接缝，默认普通 HAP 不编入/不注册该能力；测试构建也须严格解析并限制在本轮验证者，避免正常业务帧被截获。测试 finally/退出回收复位闸门，保留反例可复跑能力，而非归档后只能删除全部驱动。普通产物验证无凭据、错误凭据及合法字段字符串包含该词时都不能暂停认领，合法写入仍按正常业务规则处理。

**B2：修关闭时队列遍历失效。** `requestStop` 对 `c.queue` 做 for 遍历，`settleCancelledLocked` 同时从该 ArrayList 删除元素；迭代失效异常又可能跳过解锁。锁内改为安全的逐张取出/结算或先分离队列，并保证异常退出释放锁；Pending取消、Executing结算及额度扣减继续各做一次。

验证：暂停认领后放入1张和多张 Pending票，直接调用生产 stop，全部得到确定的未执行关闭结果，队列/字节/连接/在途归零；真正 awaitClosed 后同进程重开。保留一条旧半帧连接，关闭重开后补发，旧请求不能进入新 owner。

**B3：让脚本能识别反例失败。** B1 门控同时占满连接后精确断言拒绝及占用上限；B3 客户端本地 timeout 只能记未知/失败，不能计服务端 Cancelled；B4 区分 EOF/reset 与仍活超时。新增真正 stop/reopen 段；原半帧到期证据保留并按其实际范围命名。

### C. 新能力继续：可复用双字段文字代理

复用已经建立的上下文编号、accepted 几何与初值、失焦一次结算、核心文字延续标记；把完整代理交接放到平台实现/模板中，由两个不同字段及独立消费者消费。应用仅声明字段、布局和规则。

1. **固定回调归属。** 当前 `onChange/onSubmit/onBlur` 在执行时读取可变 `this.imeCtx`，迟到 A 回调可能携带 B 的新编号绕过校验；50ms 焦点请求也没校验原上下文。每个代理挂载实例捕获不可变 context/edit generation，回调与定时器按创建时身份发出并验证，旧事件不能提交或结束新字段。验证 A→B 后放行 A 的 change/blur/focus 回调，B 的草稿与焦点不变，B 随后正常提交。
2. **空值不是所有权信号。** renderer 当前用 `editorRetired && !node.value.empty()` 让出画面，并把空值解释为延续本地缓冲。已有 ABI 的 `preservesActiveLocalText` 才是明确依据；消费该标记及相应候选/accepted身份，不用内容是否为空推断 owner。新增允许空值的独立字段：外部清空、合法提交空值、拒绝旧草稿，画面与公开 owner 同为空且旧字不复活。现有 name/alias 都禁空，不能覆盖此反例。
3. **选区与组合状态真实接通。** 初始化并同步平台选区，消费已经导出的 selection 入口；普通 onChange 与系统 marked/preview 范围分开，不能把任何改变都转成全文 composition、把光标强制移至末尾。用本机 SDK 对应回调取实际组合状态，清楚约定 UTF-16/UTF-8/核心范围的转换。验证中间插入、选区替换/删除、emoji与组合字符、提交/取消和切字段；系统 IME 真正组合的证据独立记录。
4. **完成成功接续。** T7/T8 保留为旧输入拒绝与画面恢复反例；其后再聚焦拿到外部新值/新上下文，人在真实控件修改并成功提交，经公共 `GET_CONTEXT` 等 owner 读口精确断言字段与业务版本，画面显示同值后还能继续编辑。name与alias均覆盖，不能只查询 `imeEditingContext.editingText` 或以桥接 rc=0 代替业务应用成功。

将公共代理、可选传输与宿主从 lab 私有装配提取到平台消费入口；独立双字段/UI-only消费者可同时承接 E，避免再造平行业务模型。

### D. 裁剪夹具与平台响应基线

沿用已经统一的 `effectiveClips`，现在建立静态容器夹具：跨边界文字/按钮、空交集、圆角外点、尺寸变化。分别断言像素、命中与 owner 改动，补 draw/hit 一致的证据。此项不依赖新增完整列表/滚动库。

A 的正常生命周期稳定后，补真实 resize、前后台切换和恢复；对普通触摸、连续输入及外部请求记录同请求的 input/入队→owner→accepted/submit 单调时钟、样本与分段计数。停止操作后的线程唤醒、队列与资源收敛单列；模拟器性能不外推真机或物理显示。布局/文字/资源调度/语义动作/普通接入六条主线本包均有消费或验收落点，暂不扩大控件库，以这条通用平台链为优先。

### E. 独立平台交付与不会假绿的验收

- `host/`、脚本迁移成果保留；transport 与通用 ArkTS 代理继续迁入框架拥有的入口。让独立目录消费者传入自己的应用定义、输出目录及身份，公共脚本不再必须读仓库 `settings_counter_application` 或向旧 lab 的 artifacts 写入；纯 UI 消费者可不启用外部传输。
- 当前闭包校验已遍历 ELF，但 `unzip` 失败被 continue、`llvm-readobj` 失败藏在 process substitution 中，均可能被当“无依赖”。每个精确 ZIP 成员必须成功提取和解析；系统依赖清单有明确 SDK 来源，核对 SONAME/NEEDED/ABI。负对照实际移除一个被依赖的现有库、损坏一个必需 ELF、让解析器失败，均必须拒绝；追加虚构必需库只证明显式名单分支。
- 启动断言当前仍只 grep 全局日志，`hilog -r` 失败被忽略，PID虽保存却未用于判定。让应用发布本轮实例/启动标识，并与安装 HAP、进程、日志起点绑定。保留旧成功记录但新启动失败/清日志失败时不得假绿；不能把常量 `cleared_before_launch=1` 当实际清理成功。
- 源清单采用可处理含空格路径的逐项枚举，完整覆盖模板/工程配置/脚本/链接桩/依赖与工具链。冻结普通产物和测试变体的不同身份；最终安装、截图、读回及性能指向各自相同产物。构建负控外层可以返回“反例符合预期”，但同时保留被测入口实际非零结果，不能混作正常构建成功。
- 补 macOS 当前同源 name/alias 的公开读写、拒绝和窗口反馈；共享 PENDING/文字标记若改动，回归实际触及的公共接缝。沿用其余已接受基线，集中完成最终独立包消费。

### 实施顺序与交付

先移出生产暂停入口、修关闭队列；A 的候选结算与 lease/停止状态是高风险主写集，按已有方案及这次反例推进。C 的平台代理/选区/独立字段、D 裁剪夹具、E 脚本失败分类与独立消费准备同步交错；最终生命周期、输入与产物汇合验收等其具体依赖就绪，其他工作持续。

本次已给出设计思路和判别标准。将 PENDING 的完整核心调用链、surface存活与 stop边界带入既有 Astra/Sol只读咨询会话聚焦复核（沿本文前述型号与次高档规则），不以“本轮没有再改旧方案”跳过已暴露的契约问题；顾问不得代写并行工作区。Laya按新事实辅助判断，零区分度照实记录，注释/概率不替代隔离与运行验证。

按完整 A–E 目标持续实施、自验和集中报告。状态只写 ACTIVE，详细证据留本文执行记录；源码缺陷、未交付能力、测试未跑和真实环境限制分开。任务开始前读取仓颉技能，构建及模拟器由主执行者统一协调，保持用户指定执行模型与当前暂停安排。收尾报告每项前后反例、成功的人→外部→人链、最终产物身份和精确欠项，避免把剩余实施工作改名成“缺测试入口，等用户”。


---

<a id="review4-current-package"></a>
## 第四次指导复核与当前完整工作包

2026-09-25。依据[第三轮执行报告](2026-09-25-harmonyos-backend-first-chain-execution-report-3.md)、`rework3/pending-transaction` 与 `rework3/surface-stop` 顾问答复、当时源码及原始日志复核。**路线不变，整包继续；当时A1是实现进展与普通启动证据，尚未完成PENDING真实路径交付。** 本节保留第四次复核的详细方案，进度与当前实施依据由页末第五次复核更新。指导当轮未编译、重跑产品测试或操作模拟器。

### 已接受进展与当前风险

- 鸿蒙 snapshot 已保存原候选事务，区分完整刷新/交互投影；native 拆开 present、query、ACK，终态保留至确认。这一方向保留，不推倒重来。StartingPending、关闭收敛、异常收尾和受控延迟链尚未闭合。
- `requestStop` 已先分离队列再逐票结算，并用 `finally` 解锁。测试传输接缝已有 `@When` 构建隔离，普通 cfg=off；这些源码问题不再按旧状态重复派单。
- 原始 B 日志证明 12 连接中 4 被拒、8 存活，以及生产 stop 时 4 张 Pending 全部得到服务端确定未执行。半帧该次实际读到 EOF。**SETTLE 只到 `LIFECYCLE=1 / CONNS=1`（Closing），不是 Closed；没有同进程重开证据。** 脚本仍允许 timeout 假绿，须修。
- 只读重算 run `run_20260925_212552` 的464项清单输入全部相符，当前 build/last HAP 同为 `97392a7dd56ebfa95aaedb245100e7c2613eaac984e2c6f9b10c1847b2a29722`。普通变体的四项启动 marker 与12节点首帧记录保留。设备为模拟器，这不是物理真机验证，也不覆盖 PENDING、surface退役或当前 macOS 回归。
- **最高优先级是新增共享 ABI 不一致**：C 头的 `CjguiInternalRendererFrameObservation` 新增 `ticketId`，64位布局32→40字节；共享 `src/runtime_renderer_session.cj` 仍为旧结构，只有鸿蒙 snapshot 同步。普通 macOS present 经 `present_clear` 的新 `sizeof` 清零会越过旧结构边界。结论来自源码/ABI静态推导，未运行触发。

### A. 先修共享 ABI，再完成原事务与平台生命周期

**A0：共同核心与 ABI 的单一来源。**

先同步所有 C/仓颉 ABI 镜像和真实调用方，或采用兼容的版本化输出结构/入口。不能仅以两个 C 头 `cmp` 相等认定跨语言兼容。核对 struct 大小、alignment、字段 offset、嵌套 receipt，以及 native 实际写入字节；加入尾部 canary 判别，再以当前同源库运行 macOS clear/普通场景/失败返回和编辑器相关消费者。此项在使用本轮新 native 库做 macOS 桌面测试之前完成。

通用 PendingPresentTransaction、启动/关闭及回执处理回到共享核心，以明确的平台适配保持同步 macOS 行为；定向合并以保留 Pharos 正在修改的事件/输入路径。鸿蒙 snapshot 是构建快照，来源/差异和再同步步骤必须可重现，不能独立演进为第二套核心。回归 query/ACK 的同步无票据兼容结果、READBACK_FAILED 与确定失败原语义。

**A1：原票据完整状态机，接到所有实际调用方。**

1. 按已有 Astra 方案实现贯穿 host/window 的 `StartingPending → Ready/Failed` 与 `ClosingPending → Closed`。首帧 false 当前仍走 discard；即使 destroy 拒绝，discard 仍清 session token，必须修正。只有启动请求接管与真实 ready 分别可观察；host 继续 pump 原事务。重复 start 不创建第二会话。
2. close 必须持久记录关闭意图。当前遇 Pending 只写诊断返回，不能完成“一次 close 请求，放行后自动收敛”。停止新业务/候选后，保留 owner 结算者、session及原票；取消可取消任务，committing 等真实终态，Accepted按已接受事实收尾，Rejected回滚原候选，最终资源释放确认后清身份。关闭态不再恢复焦点/挂代理。超时保持未完成。
3. 将“native已终态”“核心接受/回滚已完成”“ACK已完成”分开。当前 `tx.settled=true` 后 participant/focus 收尾抛异常，下一轮会直接清 tx，却未 ACK native 旧票；ACK返回也未检查。收到 Accepted 后不再回滚，但异常必须进入不可回滚的终止收敛路径，保留原票与阶段，避免重复回调或把旧票绑定新候选。ACK失败可重试原ACK，不得开放新候选。
4. 原事务保留完整身份/版本/候选持有/来源；等待期间 owner、resize、资源、交互、viewport请求分别有 revision，旧结算只消费原请求，不清掉后来滚动或编辑。全入口共用结算门；依赖 accepted身份的输入不得在未定时重命中新场景。native投递前登记票据，未确认时 configure/set/present 不覆盖原候选；单owner与其他入口的线程前提写清并用适用反例证明。
5. 补齐现有测试变体的应用内控制接缝，构建明确联动 renderer `--test-gates`。首帧、普通完整刷新、交互投影分别制造 Pending→Accepted/Rejected；等待期间改 owner/滚动，重复 query/ACK，单次 close，participant/focus抛错，ACK失败。逐票断言：不重建原候选、不重复帧号、不丢新请求、native/core接受版本一致、最终释放。测试闸门只改变时序或注入显式失败，结果由生产结算逻辑产生。

**A2：按 Sol 已给方案实现 SurfaceRecord/使用许可。**

在宿主保存每代独立记录，键含 `appInstance/sessionToken/componentInstance/surfaceGeneration/geometryRevision`。UI串行取得 native引用且成功后才发布；渲染线程同临界区校验身份、取得使用许可，创建/绘制/Flush/缓存surface/redraw/teardown全程覆盖。退役记录保留至最后使用完成；新同尺寸surface不能复用旧身份。

销毁回调只关新许可、标退役、投递清理并返回。移除400ms等待后仍Unreference的路径；由渲染线程完成Flush与SurfaceDestroy、归还许可后通知UI串行释放引用。引用保对象存活，提交仍需核对退役/几何/取消；若已进入不可取消提交，保留未知结果，返回后按旧身份结算，不晋升新代。`busyGeneration`不作为全生命周期静默证明。

使用既有8类闸门反例：许可后、创建前后、绘制中、提交准入前、不可取消提交中，以及空闲/queued/committing停止。旧引用未释放前保持记录，新代能独立工作；逐项记录许可/引用配对、最终rc、accepted/命中身份和资源收敛。回调参数不足以区分指针复用时，依据实际SDK回调顺序或可绑定实例的接缝建立静默屏障，不能靠地址相等推断身份。

**A3：真正等待 owner/renderer，再开放重启。**

XComponent卸载不再调用stopHost的修改保留。进一步令停止支持Starting/StartingPending/Running，实例化完成回执；`g_appThread.detach()`只结束引导线程，全球`shutdownDone`可能是旧值，都不能证明本实例owner退出。选择同步owner由可join线程持有，或保存实际仓颉task与按实例退出确认；保持UI非阻塞。

Stopped需同时确认本实例不接单、owner实际退出、listener/client线程与连接/票据收敛、原窗口事务ACK和renderer teardown完成、surface许可归还。Stopping期间重开明确拒绝，完成后产生新实例；旧完成通知不能改新状态。真实`stop→await→boot`分别覆盖空闲/queued/committing，补Starting时stop及启动失败可重试。surface临时重建则owner/version保持且能继续人/外部操作。

### B. 保留传输修复，修正验收并补真正关闭重开

保留分离队列与条件编译接缝；普通HAP在符号/注册/行为上都证明测试控制不可用。测试变体控制帧严格独立、限定本轮验证者，清理恢复由明确生命周期持有者完成。

修 `verify_transport_gate.py`：到期后的 `alive-timeout` 必须失败/未知，不能算 EOF；关闭检查只接受预期EOF/reset/refused，其他异常（含timeout）保留原因并失败。用合法字段值包含 `PAUSE_CLAIM` 的正常命令证明值确实进入owner且未暂停；当前 `GET_CONTEXT 0 PAUSE_CLAIM` 返回ERROR只证明没被控制入口吞掉。

SETTLE的结果改称“取消排队已完成/仍Closing”，不得自证Closed。停止后用owner外的生命周期控制/观察入口取得本实例关闭确认，实际同进程boot；旧半帧补发不进新owner，新合法请求成功。取消测试继续精确核对1张/多张服务端终态、队列/字节/连接/在途和版本，客户端timeout始终不能替代未执行。

### C. 新能力继续：完整公共双字段系统文字代理

承接第三次复核全部C目标。复用平台已有context、accepted初值/几何与核心延续标记，交付框架拥有的代理/模板，由name、alias及允许空值的独立消费者使用。

- 每次真实挂载固定 `app/session/context/editGeneration/mountGeneration`，change/submit/blur/迟到focus定时器携带创建时身份；先验证新focus再收尾当前代理，结束一次且旧回调不触碰新字段。
- 本地preview的显示资格与已被owner接受的精确文字来源分开。异步候选需要冻结“哪次编辑”的来源回执；不能在延迟接受时读取最新缓冲。`preservesActiveLocalText=false` 的空串是合法owner值，显示/提交同步/重新聚焦三处一并去掉空值推断。
- 真实平台selection与marked/preview范围接通UTF-16/UTF-8转换；中间插入、选区删除/替换、emoji、组合提交取消、切字段都有owner读回。
- 保留T7/T8旧输入拒绝证据，后续必须获得新上下文、人的合法修改成功、公开owner字段/版本精确读回，显示后再次续写。桥接rc与native editingText不是业务成功证据。普通TextInput输入与系统IME组合态分别标记。

### D. 裁剪/命中与普通负载响应

复用effectiveClips完成跨边界文字/按钮、空交集、圆角外点、resize的像素和命中双反例，点击导致的owner变化也要对应。夹具和普通输入可独立推进，不等A所有极端时序完成。

正常生命周期具备后测真实resize、前后台恢复，普通触摸/连续输入/外部请求的同请求单调时钟阶段、有效样本和工作量；停止后线程唤醒/队列/资源归零或合理缓存基线。模拟器数据与物理真机/显示器呈现分开，保留真实热点，不扩大控件库。

### E. 失败关闭与独立平台消费

1. `build_and_run.sh` 启动/变体断言逐项收集失败。当前两函数顺序位于 `… || ASSERT_FAILED=1` 的组合命令，前者失败可被后者成功覆盖；加“只有seam日志、缺owner/present”的负控，以及不启动/残留旧日志，确认被测入口非零。应用发布本轮实例/启动id，和PID/HAP/日志起点绑定；仅保存PID不够。
2. `verify_hap_closure.sh` 每个精确ZIP成员提取和ELF解析必须成功；去掉失败continue及隐藏在process substitution中的解析错误。真实依赖缺失、损坏必需ELF、解析器失败都拒绝；系统库白名单有SDK来源，核SONAME/NEEDED/ABI。负控外层成功与被测构建失败分别报告。
3. transport迁框架成果保留；公共脚本允许独立应用定义、身份、输出路径，不固定复制settings_counter或写旧lab artifacts。通用ArkTS文字代理纳入框架模板，UI-only可不接外部传输。
4. 源清单以逐项安全枚举处理含空格路径。独立目录消费者从公共入口正常构建/运行，应用字段结构不同，实际人/外部接续；normal与verify分别冻结源码、工具链、动态依赖、HAP和运行身份。既有464项一致仅证明本轮原目录的输入匹配。
5. 最终同源macOS name/alias读写、拒绝与窗口反馈，加A0/A1实际影响的公共输入/提交回归。最终HAP、清单、安装、截图、读回、性能对应同一构建；旧绿色日志只沿用未变化的适用范围。

### 推进顺序与报告

先A0，随后A1/A2/A3沿已给方案协调；B测试器修正、C代理与空值/选区、D夹具、E失败关闭与独立消费准备同步推进，最终汇合等待具体依赖。按写集分批实现保持整包连续，不把“本轮上下文用尽/缺触发入口”当产品阻塞或完成标准。

沿既有顾问会话带新证据聚焦追问，不重发全仓、也不让顾问代写并行目录。当前Sol/Astra方案已有明确不变量和反例，执行后用运行结果确认；仓颉技能与Laya按现行任务规则使用。跨语言ABI、共享核心与Pharos写集由主执行者协调，状态仍只维护ACTIVE。

集中报告A–E各自的源码/受控反例/正常应用/独立消费及精确未验；同一缺陷继续累计失败，不换名清零。以人→外部→人成功接续与最终产物闭环收口，环境缺项只阻塞相应验收。

<a id="review5-current-package"></a>
## 第五次指导复核与当前完整工作包

2026-09-26。依据[第四轮执行报告](2026-09-25-harmonyos-backend-first-chain-execution-report-4.md)、当前源码与原始证据，只读复核；未重跑构建、产品测试或模拟器。**整包继续，接受传输重开等具体成果，A1/A2/A3仍有实现缺口，不能只列为补测试。** 本节更新第四次复核的进度与实施顺序，原A–E目标完整承接。

### 本轮接受范围

- A0共享`FrameObservation`已补`ticketId`并与snapshot一致，C端40字节断言及仓颉大小/尾部canary用例覆盖旧32/40字节错配。原始`/private/tmp/cjgui_macos_a0.log`有readback和两帧记录。报告所称207项/canary运行通过，本次未定位精确原始结果及对应库哈希；归档已有结果即可，缺失时再跑针对性验证。alignment/offset及嵌套receipt仍按原验收补齐。
- B真实传输关闭重开已发生：`reopen_v12/reopen_hilog_timeline.txt`同PID 9749记录listener退出、Closed成立、同端口再监听与身份1→1000→2000。控制连接结束后再`awaitClosed→boot`、监听socket在finally关闭的修复保留。4票取消及重开后业务值保留有原始记录。
- `commit_v1`证明传输已认领票据后业务值/版本恰好+1；这是**transport Executing**，尚未进入renderer的Flush/Committing。当前owner与renderer在传输重开时均存续，不能作为应用停止/重启或Surface存活证明。
- E启动断言逐项累计失败、ZIP提取/readobj失败计入BROKEN的修复成立；完好HAP PASS、损坏`libcjgui.so`明确FAIL保留。追加虚构库名只验证必需名单分支。
- `normal_final`478项清单哈希与当前对应文件全匹配，实际build/last HAP同为`2538415e…a477`。`commit_v1`与当前有3项差异、`reopen_v12`有6项，含后续脚本、应用/transport及变体配置，作为各自历史证据保留；不升格为最终版本全套验证。设备统一称模拟器。

### A. 先接通实际构建来源，完成事务和平台生命周期

**A0/A1来源断点必须先闭合。** 共享`src/composable_ui_window.cj`已有ACK重试和关闭意图，OHOS snapshot却仍是旧的settled清票/忽略ACK/无关闭意图逻辑。snapshot与lab实际副本相同，哈希`076b51…99d8f`也匹配`normal_final`清单，故当前HAP确实未消费这些修复。先从共享核心生成可重复的平台快照，平台差异通过明确适配或可重放变换表达，记录来源与差异并防止重新同步丢修复；保留Pharos的输入/事件并行修改。最终核对共享源→平台快照→消费目录→HAP，而非只重算已有快照指纹。

**A1仍需实施两条关键路径。**

1. 首帧PENDING仍由共享`start()`的false分支进入discard，host在`window.start()==false`时返回且未把窗口纳入继续pump的集合；仅保留token不能推进。实现host可持有并泵送的StartingPending，明确启动受理与Ready结果；失败/单次close/Starting时stop都留在同一实例状态机内直到真实收敛。
2. 共享`settlePendingPresent()`仍先设`settled=true`再调可能抛错的接受回调。异常后下一轮会ACK并清票，即使核心只完成部分接受。将native终态、核心收尾进度和ACK完成分开，Accepted后异常转入不可回滚的终止收敛路径；原票未完整收尾前阻止新候选，避免重复participant/focus回调。Rejected回滚异常也按原票收尾。ACK仅重试原票，不能用ACK成功替代核心收尾成功。

保留第四次A1完整反例：首帧/完整刷新/交互投影各自Pending→Accepted/Rejected；等待期新owner/滚动/资源请求；重复query/ACK；单次close；participant/focus异常；ACK首次失败后恢复。接缝必须进入实际HAP，并证明原事务不重建、新请求不丢、关闭后不恢复焦点、票据和持有最终收敛。

**A2/A3沿已有Sol方案完成，不以transport反例替代。** 每代SurfaceRecord五元身份和RAII使用许可覆盖创建、绘制、Flush、缓存、redraw、teardown；引用失败不发布active，退役后由最后使用者完成销毁并回到UI串行归还引用。当前400ms后仍Unreference和`busyGeneration`局部窗口不足以证明安全。按原8类闸门在实际renderer边界验证。

应用Stopped需本实例owner实际退出、原窗口事务/ACK、renderer teardown、Surface许可、传输线程/票据全部收敛；`g_appThread.detach()`、全局`shutdownDone`和新listener身份均不能单独代替。补Starting/StartingPending时stop、失败重试和真实应用空闲/queued/renderer-Committing三态停止；surface临时重建继续保留owner/version。

### B. 保留生产修复，补强传输反例

1. `verify_transport_reopen_v2.py:221`仍以`OSError`捕获关闭拒绝，包含`socket.timeout`。明确区分EOF/reset/refused与超时/其他异常；探针增加“仅超时”负控。800ms测试保持可保留，但绑定Closed→boot阶段和原实例，记录实际异常，不用观察不到应答推导已关闭。
2. 现有267–273行是在boot之后新建连接、发长度头再主动close，不是旧半帧补发。改为stop前保留同一旧socket，发送可辨识业务帧的前半部；Closed/boot后在该socket尝试补余帧。断言旧连接拒绝、对应操作未应用/owner版本未变、新连接新请求成功。
3. Executing探针先安装保持再RESUME；在生产stop裁决处采样目标票的实例/ID/状态，证明stop确实发生在该票Executing时。客户端必须拿到完整且严格解析的业务终态，核KIND/APPLIED/版本与公开owner读回；空结果、`CLIENT_UNDETERMINED`、未结束线程都失败。现有“只要不含outcome_unknown就通过”的断言删除。保留恰好+1的真实读回，并记录该层没有进入renderer提交。
4. 测试控制帧可用独立解析器，但严格校验协议、KIND、OP、END、必需字段、重复字段及值类型，错误帧不能提供成功键。两个新探针统一绝对单调deadline与有界读取；raw请求/回包和断言随run归档，关联HAP/PID/旧新实例/票据，不只保存全局JSON布尔结果。

### C. 新公共文字能力同步交付

复用现有name/alias消费者与上下文桥，完成框架拥有的ArkTS代理/模板；每次挂载冻结app/session/context/edit/mount身份，旧change/submit/blur/定时focus回调不得读取新的可变`imeCtx`冒用新字段。

保留本地preview与owner接受值的区别；候选冻结对应那次编辑的精确来源回执。当前renderer仍用`value.empty()`推断本地延续，改为消费明确`preservesActiveLocalText`及事务身份；允许空值的独立字段要在显示、提交同步、重新聚焦三处保持空串，不复活旧字。

接通真实selection/marked范围及UTF-16/UTF-8转换，覆盖中间插入、删除/替换、emoji、切字段。name/alias与独立空值字段都跑人改→外部读改→人获取新上下文续写→owner精确读回；旧输入被拒后必须有成功恢复。C-API输入法实验桩与当前ArkTS TextInput路径分别判断，前者失败不能直接证明后者系统组合输入不可验；工具粘贴/普通输入与系统IME提交取消分别记证据。

### D. 裁剪、命中与响应

继续第四次D：跨边界文字/按钮、空交集、圆角外点、resize的像素与命中双反例；真实点击对应owner变化。正常生命周期接通后补resize/前后台、人连续输入与外部请求的同请求单调分段耗时、工作量和有效样本，停止后唤醒/队列/资源收敛。夹具、采样接入与普通输入可独立推进。

### E. 独立消费与最终同源交付

1. 保留已修失败累计/BROKEN判别；补移除真实NEEDED依赖、解析器失败以及残留旧实例日志的负控。NEEDED解析应覆盖全部实际条目而非仅`lib*.so`，核目标ELF架构/SONAME与SDK系统库来源，合法空依赖保留。
2. 当前`launch_ts`在启动、等待和取日志之后生成，PID只是附记，日志仍按tag匹配。应用启动标识/实例身份须进入实际marker并与本次PID、HAP、日志区间核对，证明旧实例marker不能满足本轮断言。
3. 报告称APP_SRC已参数化，当前`sync_platform.sh:89`仍固定示例源；`build_and_run.sh`输出仍固定旧lab，`source_manifest.sh`仍按空白拆分find输出。完成应用定义/身份/输出入口与逐项安全清单，实际在含空格独立目录构建运行不同字段结构的消费者，公共文字模板也从平台入口消费。
4. 最终normal与verify分别冻结真实编译输入、工具链、依赖、HAP及运行证据；先保留历史成果，只因相关生产/验证器改动复跑受影响链。以同源macOS name/alias/拒绝/窗口反馈及A1影响的输入提交回归汇合；A0旧日志优先补准确归档，不机械重跑整仓。

### 整包推进与集中交付

先修共享核心来源与A1主路径，A2/A3按既有方案实施；B验收补强、C代理/独立字段、D夹具/采样、E参数化与负控交错推进。一次下发完整A–E，具体失败只阻塞依赖项。布局/绘制由裁剪与Surface检验，文字与语义由真实接续检验，资源调度由关闭/公平性检验，普通开发者接入由独立消费检验；继续框架能力建设。

已有咨询结论先落实，结构性新证据再聚焦向当前规则指定的顾问升级。集中报告分别说明共享实现、实际OHOS消费、受控反例、正常应用、模拟器输入和独立交付；同一旧问题累计不清零。整包状态只维护ACTIVE，源报告保留为自报历史。
