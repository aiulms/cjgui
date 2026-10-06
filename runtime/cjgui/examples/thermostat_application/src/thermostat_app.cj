// 恒温示例：第二个真实独立消费者（第六次复核第 5 项）。
//
// 与设置计数示例的差异（每个都是本消费者存在的理由）：
//  - 不同领域字段：目标温度（16–30 整数）、节能开关（布尔）、备注（**可空**
//    字符串 ≤64——空串是合法业务值，与设置计数「非空」规则相反）；
//  - 独立 resourceId（9801）与独立外部授权身份（thermo agent）；
//  - 独立 bundle（labs/ohos_thermo_app，com.example.cjguithermo）与独立传输
//    端口（7857，由该 lab 的宿主层声明）。
//
// 领域规则只有这一份（仓颉 owner）：人与外部经同一 execute，遵守同一版本契约。
// 控制器把规则投影为 CJGUI 组件树；宿主差异不进入本文件。

package cjgui_thermostat_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.sync.*
import std.time.*
import std.random.*

/// 已应用的真实业务状态（无草稿层：设置类动作直接生效）。
public class CjguiThermostatSnapshot {
    public let version: Int64
    public let targetTemp: Int64
    public let eco: Bool
    public let note: String
    public let imageVersion: Int64
    public init(version: Int64, targetTemp: Int64, eco: Bool, note: String, imageVersion: Int64) {
        this.version = version; this.targetTemp = targetTemp; this.eco = eco
        this.note = note
        this.imageVersion = imageVersion
    }
}

/// R3（2026-10-02）：备注按版本的有界历史条目（该版本接受动作后的备注值）。
public class CjguiThermostatNoteVersion {
    public let version: Int64
    public let note: String
    public init(version: Int64, note: String) {
        this.version = version
        this.note = note
    }
}

public class CjguiThermostatDomain <: CjguiSharedOperationDomain & CjguiSharedOperationChangeDomain {
    public static let resourceId: Int64 = 9801
    public static let tempMin: Int64 = 16
    public static let tempMax: Int64 = 30
    // 备注可空：空串合法；非空时不超过 64 个 Unicode 标量。
    // 与生成字段公开的 maximumLength 使用同一单位。
    public static let noteMaxUnits: Int64 = 64

    private var versionValue: Int64
    private var targetTempValue: Int64
    private var ecoValue: Bool
    private var noteValue: String
    private var imageVersionValue: Int64
    private var imageCatalog: ?CjguiGeneratedUiCapabilityCatalog
    private let streamIdentity: String
    private let changeLog: ArrayList<CjguiSharedOperationChangeEntry>
    // R3（h-source-preview-followup 2026-10-02）：备注文本按版本的**有界历史**，
    // 供生成字段范围会话的选区重基（外部改版后继续输入不丢锚点）。每条是
    // (该版本接受后的备注值)；只保留最近 32 条，超出丢最旧（窗口会话只重基
    // 近期选区，远期按不可映射具名拒绝）。
    private let noteHistory: ArrayList<CjguiThermostatNoteVersion>

    public init() {
        this.versionValue = 0
        this.targetTempValue = 22
        this.ecoValue = false
        this.noteValue = ""
        this.imageVersionValue = 1
        this.imageCatalog = None
        // 每次启动的 capability 均为新发；编入流标识防跨重启续读。
        this.streamIdentity = "thermostat_stream_${Random().nextUInt64()}"
        this.changeLog = ArrayList<CjguiSharedOperationChangeEntry>()
        this.noteHistory = ArrayList<CjguiThermostatNoteVersion>()
        recordNoteVersion()
    }

    public func resourceType(): String { return "thermostat" }

    public func thermostatSnapshot(): CjguiThermostatSnapshot {
        return CjguiThermostatSnapshot(versionValue, targetTempValue, ecoValue, noteValue,
            imageVersionValue)
    }

    public func imageResourceSpec(): CjguiGeneratedUiImageResourceSpec {
        return CjguiThermostatImage.spec(imageVersionValue)
    }

    public func bindImageCatalog(catalog: CjguiGeneratedUiCapabilityCatalog): Unit {
        imageCatalog = Some(catalog)
    }

    // round12-R2：宿主可挂**表面状态闭包**（accepted 读回几何/当前编辑身份），
    // 随每次 GET_CONTEXT 公开——读回定位不依赖 hilog node-rect。未挂时载荷保持
    // 旧形状（ownerState 为空，传输层自动省略该行）。
    private var stateProvider: ?(() -> String) = None

    public func attachStateProvider(provider: () -> String): Unit {
        stateProvider = Some(provider)
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let ownerState = if (let Some(provider) <- stateProvider) {
            provider()
        } else {
            ""
        }
        return CjguiSharedOperationContextSnapshot(versionValue, "恒温示例", resourceType(),
            ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(CjguiThermostatDomain.resourceId, "恒温器",
                    ArrayList<CjguiSharedOperationField>([
                        CjguiSharedOperationField("targetTemp", CjguiSharedOperationValue.integer(targetTempValue)),
                        CjguiSharedOperationField("eco", CjguiSharedOperationValue.boolean(ecoValue)),
                        CjguiSharedOperationField("tempRange", CjguiSharedOperationValue.string("16-30")),
                        CjguiSharedOperationField("note", CjguiSharedOperationValue.string(noteValue)),
                        CjguiSharedOperationField("imageVersion", CjguiSharedOperationValue.integer(imageVersionValue))
                    ]))
            ]), ownerState: ownerState)
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            CjguiSharedOperationActionDescriptor("TEMP_UP", "目标温度加一",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("TEMP_DOWN", "目标温度减一",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("SWITCH_IMAGE", "切换恒温热图",
                ArrayList<CjguiSharedOperationParameterDescriptor>(), 1, 1),
            CjguiSharedOperationActionDescriptor("SET_ECO", "设置节能开关",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("value", "BOOLEAN", true)
                ]), 1, 1),
            CjguiSharedOperationActionDescriptor("SET_NOTE", "设置备注（可空）",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("text", "STRING", true)
                ]), 1, 1)
        ])
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(invocation)
    }

    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>,
        expectedStreamIdentity: String): CjguiSharedOperationChanges {
        if ((expectedStreamIdentity.size > 0 && expectedStreamIdentity != streamIdentity) || sinceVersion < 0 ||
            sinceVersion > versionValue) {
            return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, true,
                ArrayList<CjguiSharedOperationChangeEntry>())
        }
        let changes = ArrayList<CjguiSharedOperationChangeEntry>()
        for (entry in changeLog) {
            if (entry.version > sinceVersion && (resourceFilter.size == 0 ||
                resourceFilter[0] == CjguiThermostatDomain.resourceId)) {
                changes.add(entry)
            }
        }
        return CjguiSharedOperationChanges(sinceVersion, versionValue, streamIdentity, false, changes)
    }

    // 唯一的业务执行入口：人与外部共用，规则与原子性只在这里。
    private func execute(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = versionValue
        if (invocation.targetResourceIds.size != 1 ||
            invocation.targetResourceIds[0] != CjguiThermostatDomain.resourceId) {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_target")
        }
        if (invocation.expectedVersion != versionValue) {
            return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict")
        }
        if (invocation.actionName == "TEMP_UP") {
            return applyTemp(before, targetTempValue + 1)
        }
        if (invocation.actionName == "TEMP_DOWN") {
            return applyTemp(before, targetTempValue - 1)
        }
        if (invocation.actionName == "SWITCH_IMAGE") {
            let nextVersion: Int64 = if (imageVersionValue == 1) { 2 } else { 1 }
            if (let Some(catalog) <- imageCatalog) {
                if (!catalog.updateImageResource(CjguiThermostatImage.spec(nextVersion))) {
                    return rejected(before, false, catalog.lastRegistrationRejection())
                }
            }
            imageVersionValue = nextVersion
            versionValue += 1
            recordChange("image_changed")
            return accepted(before, "image_changed")
        }
        if (invocation.actionName == "SET_ECO") {
            for (argument in invocation.arguments) {
                if (argument.name == "value" && argument.value.valueType == "BOOLEAN") {
                    ecoValue = argument.value.booleanValue
                    versionValue += 1
                    recordChange(if (ecoValue) { "eco_enabled" } else { "eco_disabled" })
                    return accepted(before, "eco_state_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        if (invocation.actionName == "SET_NOTE") {
            for (argument in invocation.arguments) {
                if (argument.name == "text" && argument.value.valueType == "STRING") {
                    let next = argument.value.stringValue
                    // 备注规则：**可空**（空串是合法业务值），非空 ≤64 码元。
                    // 这与设置计数的「非空」规则相反，是本消费者的存在理由之一。
                    if (CjguiSharedFieldRule.scalarCount(next) > CjguiThermostatDomain.noteMaxUnits) {
                        return rejected(before, false, "note_out_of_range")
                    }
                    noteValue = next
                    versionValue += 1
                    recordChange("note_changed")
                    return accepted(before, "note_changed")
                }
            }
            return rejected(before, false, "invalid_parameters")
        }
        return rejected(before, false, "invalid_action")
    }

    private func applyTemp(before: Int64, next: Int64): CjguiSharedOperationActionResult {
        if (next < CjguiThermostatDomain.tempMin || next > CjguiThermostatDomain.tempMax) {
            // 越界拒绝：不产生部分业务写入。
            return rejected(before, false, "temp_out_of_range")
        }
        targetTempValue = next
        versionValue += 1
        recordChange("target_temp_changed")
        return accepted(before, "target_temp_changed")
    }

    private func recordChange(kind: String) {
        changeLog.add(CjguiSharedOperationChangeEntry(versionValue, CjguiThermostatDomain.resourceId, kind))
        recordNoteVersion()
    }

    /// R3：把「当前版本接受后的备注值」追加进有界历史（每笔已接受动作一次）。
    private func recordNoteVersion(): Unit {
        noteHistory.add(CjguiThermostatNoteVersion(versionValue, noteValue))
        if (noteHistory.size > 32) {
            let _ = noteHistory.remove(at: 0)
        }
    }

    /// R3：fromVersion 时点的备注文本；历史越界（更早版本）返回 None。
    public func noteAtVersion(version: Int64): ?String {
        var found: ?String = None
        for (entry in noteHistory) {
            if (entry.version <= version) {
                found = Some(entry.note)
            } else {
                break
            }
        }
        return match (found) {
            case Some(value) => Some(value)
            case None => if (version >= versionValue) { Some(noteValue) } else { None }
        }
    }

    /// R3：把备注的源字节选区从 fromVersion 重基到当前版本。文本未变→原样；
    /// 单处替换按前后缀差分平移；跨过/交叠替换区→无歧义时平移，部分交叠→
    /// None（不猜偏移）。
    public func rebaseNoteSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        let oldText = match (noteAtVersion(fromVersion)) {
            case Some(value) => value
            case None => return None
        }
        let currentVersion = versionValue
        if (oldText == noteValue) {
            return Some((currentVersion, startByte, endByte))
        }
        let oldBytes = oldText.toArray()
        let newBytes = noteValue.toArray()
        var prefix: Int64 = 0
        let shared = if (oldBytes.size < newBytes.size) { oldBytes.size } else { newBytes.size }
        while (prefix < shared && oldBytes[prefix] == newBytes[prefix]) {
            prefix += 1
        }
        var suffix: Int64 = 0
        while (suffix < shared - prefix && oldBytes[oldBytes.size - 1 - suffix] == newBytes[newBytes.size - 1 - suffix]) {
            suffix += 1
        }
        let replacedStart = prefix
        let replacedEnd = oldBytes.size - suffix
        let insertedBytes = newBytes.size - suffix - prefix
        let delta = insertedBytes - (replacedEnd - replacedStart)
        if (endByte <= replacedStart) {
            return Some((currentVersion, startByte, endByte))
        }
        if (startByte >= replacedEnd) {
            return Some((currentVersion, startByte + delta, endByte + delta))
        }
        // 完全跨过替换区（两端都在外）：整体平移右端。
        if (startByte <= replacedStart && endByte >= replacedEnd) {
            return Some((currentVersion, startByte, endByte + delta))
        }
        return None
    }

    private func rejected(before: Int64, conflict: Bool, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, conflict, before, before, reason)
    }

    private func accepted(before: Int64, reason: String): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(true, false, before, versionValue, reason)
    }
}

/// 授权：外部 Agent 可读取上下文/变更并调用与人类相同的动作。
/// 身份与设置计数示例完全不同（独立 agent 标识）。
public func thermostatAuthorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization("恒温示例本地 Agent", "cjgui-thermo-agent-20260926",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
            CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", all, true),
            CjguiSharedOperationExternalActionScope("GET_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("SUBMIT_GENERATED_UI", all, true),
            CjguiSharedOperationExternalActionScope("TEMP_UP", all, true),
            CjguiSharedOperationExternalActionScope("TEMP_DOWN", all, true),
            CjguiSharedOperationExternalActionScope("SWITCH_IMAGE", all, true),
            CjguiSharedOperationExternalActionScope("SET_ECO", all, true),
            CjguiSharedOperationExternalActionScope("SET_NOTE", all, true)
        ]))
}

/// 控制器：把领域状态投影为 CJGUI 组件树；人机共用同一身份与样式。
public class CjguiThermostatController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiBusinessOwnerRevisionProvider {
    public static let nodeIdTempDown: Int64 = 21
    public static let nodeIdTempUp: Int64 = 22
    public static let nodeIdEco: Int64 = 23
    public static let nodeIdNote: Int64 = 24
    // presentation 消费者：备注 TEXT 投影（非 INPUT 锚）。同一 note owner 字段
    // 的自绘呈现——点选/拖选经**公共持留排版命中**（窗口 hitTest，消费 A2 租约
    // 表）安装选区，系统输入经**公共范围会话适配**（CjguiGeneratedFieldRange
    // Session）写同一 owner 事务（SET_NOTE）；不建产品私有 native 路径。
    public static let nodeIdNotePresentation: Int64 = 25
    public static let nodeIdImage: Int64 = 31
    public static let nodeIdImageSwitch: Int64 = 32
    // C（h-source-preview-next）：样式阶段循环按钮（本地 UI 状态，不经 owner）。
    public static let nodeIdStylePhase: Int64 = 34
    // H 触摸滚动区（手写视口）：滚动区容器/内容与区内控件。
    public static let nodeIdHandScroll: Int64 = 900
    public static let nodeIdHandScrollImage: Int64 = 940
    public static let nodeIdHandScrollTempUp: Int64 = 941
    public static let nodeIdHandScrollNote: Int64 = 942
    public static let nodeIdHandScrollTempDown: Int64 = 943
    // 手写滚动视口：与生成 scrollArea 共用核心同一 viewport 机制。
    public let handScrollViewport: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()
    // 卡片滚动区：恒温卡内容（约 836vp）超过宿主表面（调试面板占下半屏时
    // 仅约 487vp）——按钮/开关/备注/状态行在折叠线下，clip 正确归零且不可
    // 命中。把卡片区收进滚动区后，滑动能把这些控件带回视口（区内子节点
    // 的 clip 随滚动偏移正确更新）。复用与手写视口同一机制，不新增第二套。
    public static let nodeIdCardScroll: Int64 = 40
    public let cardScrollViewport: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()
    // C（触摸包指导接续）：屏外 reveal 的显式目标导航——应用内导航按钮经
    // 公共 focusAcceptedSemanticNode 请求滚动区内编辑器。宿主循环在 pump 后
    // 消费挂起请求。
    public static let nodeIdFocusNoteNav: Int64 = 944
    private var pendingFocusSemantic: ?String = None
    private var pendingPresentationFocus: Bool = false
    private var pendingPresentationFocusBase: Int64 = -1

    public func requestFocusSemantic(semanticId: String): Unit {
        pendingFocusSemantic = Some(semanticId)
    }

    // presentation 锚点的**场景接受后**焦点请求：bind 的镜像声明在下一次
    // present 提交后才晋升 accepted，焦点必须等它（与 Pharos focusReassert
    // 同一形态），否则 owned 门以 decl=0 拒绝、无 live context。
    public func requestPresentationFocusAfterAccept(): Unit {
        pendingPresentationFocus = true
        pendingPresentationFocusBase = match (presentationWindow) {
            case Some(window) => window.lastAcceptedSceneVersion()
            case None => -1
        }
    }

    /// 仅当 bind 时的镜像声明已经随一次 accepted 场景晋升（accepted 版本
    /// 相对请求时**推进**）才放行焦点；宿主循环逐 tick 轮询本入口。
    /// 待决未放行期间由宿主循环代为请求刷新（指针派发运行在渲染线程，
    /// 那里的 requestRefresh 可能被线程策略丢弃；宿主线程的请求是权威通道）。
    public func presentationFocusPending(): Bool {
        return pendingPresentationFocus
    }

    /// 宿主出口：本窗口**采纳**这份落点的事实（恢复链 kind-55 的收场凭据）。
    ///
    /// 之前 thermo 只读 `pres-diag` 那一类前置条件，采纳事实本身没有消费者：
    /// 框架已经把它记在窗口里、Pharos 侧也在用，独立消费者这条腿因此拿不到
    /// 「同实例、同当前身份的窗口采纳」凭据，只能退回「签了票/装了就算通过」。
    /// 计数只在窗口采纳成功后前进（平台安装成功但窗口拒绝采纳只进 failed），
    /// 所以这一行既不等于「票据已签发」也不等于「平台已安装」，三者不能互相顶替。
    /// 只在计数前进的那一次返回一行，其余 tick 返回 None（不制造 hilog 噪声）。
    public func takeRestoreAdoptionFact(): ?String {
        let window = match (presentationWindow) {
            case Some(value) => value
            case None => return None
        }
        let count = window.textSessionRestoreCount()
        if (count <= lastRestoreAdoptedCount) {
            return None
        }
        lastRestoreAdoptedCount = count
        let (request, ctx, node, start, end, ownerVersion, projectionVersion) =
            window.lastRestoreAdoptionFact()
        return Some("count=${count} failed=${window.textSessionRestoreFailureCount()} " +
            "request=${request} ctx=${ctx} node=${node} adopted=${start}:${end} " +
            "owner_version=${ownerVersion} v=${projectionVersion}")
    }

    public func presentationFocusDiag(): String {
        var accepted: Int64 = -1
        var refresh: String = "no-window"
        var edits: String = "no-window"
        if (let Some(window) <- presentationWindow) {
            accepted = window.lastAcceptedSceneVersion()
            refresh = window.refreshDiagnostics()
            let lastDecision = window.textSessionLastDecision()
            let lastDesc = match (lastDecision) {
                case Some(e) => "ticket=${e.ticket} accepted=${e.accepted} reason=${e.reason}"
                case None => "last=none"
            }
            edits = "decisions=${window.textSessionRangeDecisionCount()} " +
                "accepted=${window.textSessionAcceptedCount()} refused=${window.textSessionRefusedCount()} " +
                lastDesc
        }
        return "pending=${pendingPresentationFocus} base=${pendingPresentationFocusBase} accepted=${accepted} rev=${localRevision} | ${refresh} | ${edits}"
    }

    public func takePendingPresentationFocus(): Bool {
        if (!pendingPresentationFocus) {
            return false
        }
        var accepted: Int64 = -1
        if (let Some(window) <- presentationWindow) {
            accepted = window.lastAcceptedSceneVersion()
        }
        if (accepted < 0) {
            // 无窗口：待决作废（具名事实是「不可编排」，不是「再等等」）。
            pendingPresentationFocus = false
            return false
        }
        if (accepted <= pendingPresentationFocusBase) {
            // 声明尚未随 accepted 场景晋升：保留待决，下一 tick 再查。
            return false
        }
        // B3（2026-10-06）：版本推进只是"发生过一次 accepted present"，并不证明
        // 那次 present 冻结并结算了**本代**镜像声明（同场景刷新、别的候选都会推进
        // 版本）。放行的权威事实是窗口的声明晋升就绪；base 比较只保留作活性前置。
        let ready = match (presentationWindow) {
            case Some(window) => window.ownedTextMirrorDeclarationReady()
            case None => false
        }
        if (!ready) {
            return false
        }
        pendingPresentationFocus = false
        return true
    }

    // H2：滚动物理策略与活动由**窗口**拥有；样例不再逐个枚举视口，也不再有
    // 全局开关。宿主声明策略（`configureScrollPhysicsToken`）并只调
    // `window.stepWindowActivities`。
    public func takePendingFocusRequest(): ?String {
        let pending = pendingFocusSemantic
        pendingFocusSemantic = None
        return pending
    }

    private let domain: CjguiThermostatDomain
    private let generatedRegion: CjguiGeneratedUiWindowRegion
    private let generatedBinding: CjguiThermostatGeneratedBinding
    // presentation 消费者的窗口引用与会话簿记：bindRangeTextSession 的唯一绑定
    // 语义由窗口拥有，这里只持有「当前绑定是否仍是本锚点」的判别事实。
    private var presentationWindow: ?CjguiComposableUiWindow = None
    private var notePresentationSession: ?CjguiTextSession = None
    private var notePresentationAnchor: ?CjguiPresentationHitTicket = None
    // 窗口采纳计数的**本实例**上次读数：只在前进的那一次交出一行事实，重复 tick
    // 不再重报（计数是窗口终身累计，别处的增加不能冒充本次交接）。
    private var lastRestoreAdoptedCount: Int64 = 0
    private var localRevision: Int64
    private var statusText: String
    // C：样式阶段（0 混合 → 1 修改 → 2 倒置 → 3 重叠 → 4 超 64 → 5 清除）。
    // 纯 UI 声明状态：非法批次的拒绝与保旧都发生在框架渲染器，这里只负责
    // 把每阶段的声明真实送到同一条 wire。
    private var styleRunsPhase: Int64

    public init(domain: CjguiThermostatDomain) {
        this.domain = domain
        this.generatedBinding = CjguiThermostatGeneratedBinding(domain)
        this.generatedRegion = CjguiGeneratedUiWindowRegion(
            CjguiThermostatGeneratedBinding.catalog(domain), this.generatedBinding,
            "thermo-generated")
        this.localRevision = 1
        this.statusText = "编辑后应用恒温配置"
        this.styleRunsPhase = 0
    }

    /// presentation 消费者的窗口接线：宿主在窗口创建后注入（与 attachWindow
    /// 同一窗口对象）。会话绑定与命中都走该窗口的公共入口。
    public func attachPresentationWindow(window: CjguiComposableUiWindow): Unit {
        presentationWindow = Some(window)
    }

    public func uiSceneVersion(): Int64 {
        return localRevision + domain.thermostatSnapshot().version + generatedRegion.revision()
    }

    public func uiBusinessOwnerRevision(): Int64 { return domain.thermostatSnapshot().version }

    public func generatedUiRegion(): CjguiGeneratedUiWindowRegion { return generatedRegion }

    public func beginSceneRefresh(): Bool { return generatedRegion.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return generatedRegion.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { generatedRegion.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { generatedRegion.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { generatedRegion.disposeSceneRefreshResources() }

    public func buildUi(): CjguiComposableUiNode {
        let snapshot = domain.thermostatSnapshot()
        let heading = CjguiComposableUiStyle(fixedHeight: 24, textColor: CjguiComposableUiColor(0.94, 0.96, 1.0, 1.0),
            fontSize: 17.0, fontWeight: 700)
        let value = CjguiComposableUiStyle(fixedHeight: 84, textColor: CjguiComposableUiColor(1.0, 0.82, 0.55, 1.0),
            fontSize: 54.0, fontWeight: 600)
        let action = CjguiComposableUiStyle(fixedWidth: 190, fixedHeight: 64, gap: 16,
            background: CjguiComposableUiColor(0.42, 0.24, 0.12, 1.0),
            border: CjguiComposableUiColor(0.66, 0.44, 0.26, 1.0), borderWidth: 2,
            cornerRadius: 14, fontSize: 30.0, fontWeight: 600,
            textColor: CjguiComposableUiColor(0.98, 0.94, 0.90, 1.0))
        let card = CjguiComposableUiStyle(growX: 1, padding: 24, gap: 14,
            background: CjguiComposableUiColor(0.16, 0.13, 0.10, 1.0),
            border: CjguiComposableUiColor(0.38, 0.30, 0.22, 1.0), borderWidth: 1,
            cornerRadius: 18)

        let root = cjguiComposableVertical(1, "thermo-root",
            CjguiComposableUiStyle(padding: 12, gap: 10,
                background: CjguiComposableUiColor(0.10, 0.07, 0.05, 1.0)))
        root.add(cjguiComposableText(10, "thermo-title", "恒温示例", heading))
        // C（h-source-preview-next）：既有第二消费者经同一框架声明消费混合
        // textStyleRuns。run 端点是节点显示文本的 UTF-8 显示字节偏移（与
        // macOS/网格 caret run 同一 wire 契约）："混排 Mixed 0129 样例" 共
        // 24 字节——混排 0..6、"Mixed" 7..12、"0129" 13..17。阶段由样式按钮
        // 循环推进（0 混合生效 → 1 修改 → 2 倒置 → 3 重叠 → 4 超 64 → 5 清除），
        // 非法批次在框架渲染器整批拒绝、保留旧 runs；不新增第二编辑面。
        let phase = styleRunsPhase
        let mixedRuns = match (phase) {
            case 1 => [
                CjguiComposableUiTextStyleRun(0, 6, 12.0, 400, "system", 0.98, 0.85, 0.30, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 700, "system", 0.35, 0.90, 0.55, 1.0),
                CjguiComposableUiTextStyleRun(13, 17, 14.0, 600, "monospaced", 1.0, 1.0, 1.0, 1.0,
                    hasBackground: true, backgroundRed: 0.10, backgroundGreen: 0.45,
                    backgroundBlue: 0.42, backgroundAlpha: 1.0)]
            // 阶段 4 的判别对象是长文本节点的超 64 批次；这里重声明与阶段 1
            // 相同的合法 runs，保证拒绝阶段里本节点画面稳定不换样。
            case 4 => [
                CjguiComposableUiTextStyleRun(0, 6, 12.0, 400, "system", 0.98, 0.85, 0.30, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 700, "system", 0.35, 0.90, 0.55, 1.0),
                CjguiComposableUiTextStyleRun(13, 17, 14.0, 600, "monospaced", 1.0, 1.0, 1.0, 1.0,
                    hasBackground: true, backgroundRed: 0.10, backgroundGreen: 0.45,
                    backgroundBlue: 0.42, backgroundAlpha: 1.0)]
            case 5 => Array<CjguiComposableUiTextStyleRun>()
            case 2 => [
                CjguiComposableUiTextStyleRun(9, 3, 12.0, 700, "system", 1.0, 0.0, 0.0, 1.0)]
            case 3 => [
                CjguiComposableUiTextStyleRun(0, 8, 12.0, 700, "system", 0.20, 0.40, 1.0, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 400, "system", 1.0, 0.60, 0.10, 1.0)]
            case _ => [
                CjguiComposableUiTextStyleRun(0, 6, 12.0, 700, "system", 1.0, 1.0, 1.0, 1.0),
                CjguiComposableUiTextStyleRun(7, 12, 12.0, 700, "system", 1.0, 0.30, 0.28, 1.0),
                CjguiComposableUiTextStyleRun(13, 17, 12.0, 400, "monospaced", 0.92, 0.96, 1.0, 1.0,
                    hasBackground: true, backgroundRed: 0.16, backgroundGreen: 0.22,
                    backgroundBlue: 0.30, backgroundAlpha: 1.0)]
        }
        let mixedStyle = CjguiComposableUiStyle(fixedHeight: 16,
            textColor: CjguiComposableUiColor(0.86, 0.89, 0.95, 1.0), fontSize: 12.0)
        root.add(cjguiComposableText(11, "thermo-mixed", "混排 Mixed 0129 样例", mixedStyle,
            textStyleRuns: mixedRuns))
        // 超 64 预算的载具：100 字节 ASCII 长文本，常规阶段两段样式，阶段 4
        // 声明 65 个单字节 run（排序、不重叠、各自非空）——按数量上限整批
        // 拒绝、保旧。
        let stressText = "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        let stressRuns = ArrayList<CjguiComposableUiTextStyleRun>()
        if (phase == 4) {
            var i: Int64 = 0
            while (i < 65) {
                stressRuns.add(CjguiComposableUiTextStyleRun(i, i + 1, 11.0, 400, "system",
                    1.0, 0.50, 0.10, 1.0))
                i += 1
            }
        } else if (phase != 5) {
            stressRuns.add(CjguiComposableUiTextStyleRun(0, 10, 11.0, 700, "system", 1.0, 0.45, 0.95, 1.0))
            stressRuns.add(CjguiComposableUiTextStyleRun(10, 20, 11.0, 400, "monospaced", 0.92, 0.96, 1.0, 1.0,
                hasBackground: true, backgroundRed: 0.16, backgroundGreen: 0.22,
                backgroundBlue: 0.30, backgroundAlpha: 1.0))
        }
        root.add(cjguiComposableText(33, "thermo-runs-stress", stressText,
            CjguiComposableUiStyle(fixedHeight: 14, growX: 1,
                textColor: CjguiComposableUiColor(0.70, 0.74, 0.82, 1.0), fontSize: 11.0),
            textStyleRuns: stressRuns.toArray()))
        root.add(cjguiComposableButton(CjguiThermostatController.nodeIdStylePhase,
            "thermo-style-phase", "样式阶段 ${phase}", "CYCLE_STYLE_PHASE",
            CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 34,
                background: CjguiComposableUiColor(0.30, 0.24, 0.16, 1.0),
                textColor: CjguiComposableUiColor(0.98, 0.94, 0.90, 1.0), fontSize: 13.0)))
        // 布局单位是 vp；377×487 vp 首屏同时消费公开生成与手写视口。
        // 直接放入真实候选根，避免零高度包装层令后续兄弟与候选重叠。
        root.add(generatedRegion.buildNode())

        let cardBox = cjguiComposableVertical(15, "thermo-card", card)
        cardBox.add(cjguiComposableText(12, "thermo-value", "目标温度：${snapshot.targetTemp}℃",
            value, resourceId: CjguiThermostatDomain.resourceId, fieldId: "targetTemp",
            displayValueRole: "applied"))
        let image = domain.imageResourceSpec()
        let imageRow = cjguiComposableHorizontal(29, "thermo-image-row",
            CjguiComposableUiStyle(fixedHeight: 72, gap: 16))
        imageRow.add(cjguiComposableImage(CjguiThermostatController.nodeIdImage, "thermo-heat-map",
            image.rasterPath, CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 72),
            contentMode: 1, imageResourceId: image.key, imageResourceVersion: image.version))
        imageRow.add(cjguiComposableButton(CjguiThermostatController.nodeIdImageSwitch,
            "thermo-image-switch", "切换热图", "SWITCH_IMAGE", CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 60,
                background: CjguiComposableUiColor(0.43, 0.27, 0.12, 1.0),
                textColor: CjguiComposableUiColor(0.98, 0.94, 0.90, 1.0))))
        cardBox.add(imageRow)
        let actions = cjguiComposableHorizontal(20, "thermo-actions",
            CjguiComposableUiStyle(fixedHeight: 64, gap: 16))
        actions.add(cjguiComposableButton(CjguiThermostatController.nodeIdTempDown, "thermo-down",
            "降温", "TEMP_DOWN", CjguiThermostatDomain.resourceId, action))
        actions.add(cjguiComposableButton(CjguiThermostatController.nodeIdTempUp, "thermo-up",
            "升温", "TEMP_UP", CjguiThermostatDomain.resourceId, action))
        cardBox.add(actions)
        cardBox.add(cjguiComposableBooleanInput(CjguiThermostatController.nodeIdEco, "thermo-eco",
            "节能模式", snapshot.eco, CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 56, fontSize: 26.0,
                textColor: CjguiComposableUiColor(0.92, 0.90, 0.82, 1.0)),
            fieldId: "eco", operationActionName: "SET_ECO", displayValueRole: "applied"))
        // 备注字段：可空字符串（空串合法）——与设置计数的非空规则相反。
        cardBox.add(cjguiComposableTextInput(CjguiThermostatController.nodeIdNote, "thermo-note",
            "备注", snapshot.note, CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedHeight: 72, growX: 1, fontSize: 28.0,
                background: CjguiComposableUiColor(0.13, 0.10, 0.07, 1.0),
                border: CjguiComposableUiColor(0.44, 0.36, 0.26, 1.0), borderWidth: 1,
                cornerRadius: 10, textColor: CjguiComposableUiColor(0.95, 0.93, 0.88, 1.0)),
            fieldId: "note", operationActionName: "SET_NOTE",
            operationResourceId: CjguiThermostatDomain.resourceId, displayValueRole: "applied"))
        // presentation 消费者：同一 note 值的 TEXT 投影（非 INPUT 锚）。
        // pointerInteractive 让指针相位到达控制器；fieldId/writer 声明使公共
        // 范围会话适配（生成字段桥）可绑。值仍是 owner 快照投影（draft 期由
        // 会话镜像接管呈现）。
        cardBox.add(cjguiComposableText(CjguiThermostatController.nodeIdNotePresentation,
            "thermo-note-presentation", snapshot.note,
            CjguiComposableUiStyle(fixedHeight: 64, growX: 1, fontSize: 26.0,
                pointerInteractive: true,
                background: CjguiComposableUiColor(0.16, 0.12, 0.08, 1.0),
                border: CjguiComposableUiColor(0.44, 0.36, 0.26, 1.0), borderWidth: 1,
                cornerRadius: 10, textColor: CjguiComposableUiColor(0.97, 0.94, 0.88, 1.0)),
            resourceId: CjguiThermostatDomain.resourceId, fieldId: "note",
            operationActionName: "SET_NOTE",
            operationResourceId: CjguiThermostatDomain.resourceId, displayValueRole: "applied"))
        cardBox.add(cjguiComposableText(30, "thermo-status", statusLine(), value,
            resourceId: CjguiThermostatDomain.resourceId, fieldId: "eco",
            displayValueRole: "applied"))
        // 底部留白：扩大卡片滚动区的滚动余量，让备注 presentation 锚（25）在
        // 键盘升起（表面避让收缩）时也能滚到可见带上完成点选/拖选。
        cardBox.add(cjguiComposableVertical(36, "thermo-card-spacer",
            CjguiComposableUiStyle(fixedHeight: 240, growX: 1)))
        // H 触摸滚动：手写视口（>3 屏有界内容，混排文字/图片/按钮/编辑器）。
        // 滚动经共享 viewport 的 scroll 意图通道，不改 owner；区内按钮与
        // 编辑器照常推进 owner，与生成 scrollArea 共同调用同一机制。
        // 区内备注编辑器与顶部编辑器绑定同一 owner 字段（同值双入口）。
        let handScroll = cjguiComposableScrollArea(CjguiThermostatController.nodeIdHandScroll,
            "thermo-hand-scroll", handScrollViewport,
            CjguiComposableUiStyle(fixedHeight: 150, growX: 1, cornerRadius: 12, clipsContent: true,
                background: CjguiComposableUiColor(0.14, 0.10, 0.07, 1.0),
                border: CjguiComposableUiColor(0.44, 0.32, 0.20, 1.0), borderWidth: 1))
        let handContent = cjguiComposableVertical(901, "thermo-hand-scroll-content",
            CjguiComposableUiStyle(padding: 20, gap: 12, growX: 1))
        handContent.add(cjguiComposableText(902, "hand-scroll-head", "手写滚动区（上下拖动查看）",
            CjguiComposableUiStyle(fixedHeight: 46, textColor: CjguiComposableUiColor(0.95, 0.93, 0.88, 1.0),
                fontSize: 26.0, fontWeight: 600)))
        handContent.add(cjguiComposableButton(CjguiThermostatController.nodeIdFocusNoteNav,
            "thermo-focus-note-nav", "定位滚动备注", "FOCUS_NOTE",
            CjguiThermostatDomain.resourceId,
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 56,
                background: CjguiComposableUiColor(0.30, 0.20, 0.10, 1.0),
                textColor: CjguiComposableUiColor(0.98, 0.94, 0.90, 1.0))))
        var rowNodeId: Int64 = 910
        for (i in 1..=8) {
            handContent.add(cjguiComposableText(rowNodeId, "hand-scroll-row${i}",
                "滚动行 ${i}：内容超过三屏，行号用于滚动后画面与命中对照",
                CjguiComposableUiStyle(fixedHeight: 44, growX: 1,
                    textColor: CjguiComposableUiColor(0.90, 0.86, 0.80, 1.0), fontSize: 22.0)))
            rowNodeId += 1
            if (i == 4) {
                let handImageRow = cjguiComposableHorizontal(930, "hand-scroll-image-row",
                    CjguiComposableUiStyle(fixedHeight: 72, gap: 16))
                handImageRow.add(cjguiComposableImage(CjguiThermostatController.nodeIdHandScrollImage,
                    "hand-scroll-heat-map", image.rasterPath,
                    CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 72),
                    contentMode: 1, imageResourceId: image.key, imageResourceVersion: image.version))
                handImageRow.add(cjguiComposableButton(CjguiThermostatController.nodeIdHandScrollTempUp,
                    "hand-scroll-up", "滚动区升温", "TEMP_UP", CjguiThermostatDomain.resourceId, action))
                handContent.add(handImageRow)
            }
            if (i == 8) {
                handContent.add(cjguiComposableTextInput(CjguiThermostatController.nodeIdHandScrollNote,
                    "hand-scroll-note", "滚动备注", snapshot.note, CjguiThermostatDomain.resourceId,
                    CjguiComposableUiStyle(fixedHeight: 64, growX: 1, fontSize: 24.0,
                        background: CjguiComposableUiColor(0.13, 0.10, 0.07, 1.0),
                        border: CjguiComposableUiColor(0.44, 0.36, 0.26, 1.0), borderWidth: 1,
                        cornerRadius: 10, textColor: CjguiComposableUiColor(0.95, 0.93, 0.88, 1.0)),
                    fieldId: "note", operationActionName: "SET_NOTE",
                    operationResourceId: CjguiThermostatDomain.resourceId, displayValueRole: "applied"))
            }
        }
        handContent.add(cjguiComposableButton(CjguiThermostatController.nodeIdHandScrollTempDown,
            "hand-scroll-down", "滚动区降温", "TEMP_DOWN", CjguiThermostatDomain.resourceId, action))
        handScroll.add(handContent)
        root.add(handScroll)
        let cardScroll = cjguiComposableScrollArea(CjguiThermostatController.nodeIdCardScroll,
            "thermo-card-scroll", this.cardScrollViewport,
            CjguiComposableUiStyle(fixedHeight: 340, growX: 1, clipsContent: true,
                background: CjguiComposableUiColor(0.10, 0.08, 0.06, 1.0)))
        cardScroll.add(cardBox)
        root.add(cardScroll)
        return root
    }

    private func statusLine(): String {
        let snapshot = domain.thermostatSnapshot()
        let note = if (snapshot.note.size > 0) { "备注：${snapshot.note}" } else { "备注：（空）· 节能 ${snapshot.eco}" }
        return "${statusText} · ${note}"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let generatedResult = generatedRegion.handleEvent(event)
        if (generatedResult.didApply) {
            localRevision += 1
            return generatedResult
        }
        if (event.node.nodeId == CjguiThermostatController.nodeIdNotePresentation &&
            (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
                event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
                event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END)) {
            return handleNotePresentationPointer(event)
        }
        let snapshot = domain.thermostatSnapshot()
        if (event.eventKind == 27 && event.node.nodeId == CjguiThermostatController.nodeIdFocusNoteNav) {
            // 显式目标导航：请求聚焦滚动区内编辑器（屏外 reveal→系统输入）。
            requestFocusSemantic("hand-scroll-note")
            statusText = "已请求定位滚动备注"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiThermostatController.nodeIdStylePhase) {
            // 本地循环：阶段推进只改 UI 声明（localRevision 驱动重建与 runs 重装），
            // 不产生 owner 写入——C 的判别对象是渲染器准入，不是业务状态。
            styleRunsPhase = (styleRunsPhase + 1) % 6
            statusText = "样式阶段 ${styleRunsPhase}"
            println("THERMO_STYLE_PHASE phase=${styleRunsPhase}")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == CjguiThermostatController.nodeIdImageSwitch) {
            return applyImage(domain.executeFromHuman(invoke("SWITCH_IMAGE", snapshot.version)))
        }
        if (event.eventKind == 27 && (event.node.nodeId == CjguiThermostatController.nodeIdTempUp
            || event.node.nodeId == CjguiThermostatController.nodeIdHandScrollTempUp)) {
            return applyTemp(domain.executeFromHuman(invoke("TEMP_UP", snapshot.version)))
        }
        if (event.eventKind == 27 && (event.node.nodeId == CjguiThermostatController.nodeIdTempDown
            || event.node.nodeId == CjguiThermostatController.nodeIdHandScrollTempDown)) {
            return applyTemp(domain.executeFromHuman(invoke("TEMP_DOWN", snapshot.version)))
        }
        if (event.eventKind == 29 && event.node.nodeId == CjguiThermostatController.nodeIdEco) {
            let next = event.text == "true"
            return applyEco(domain.executeFromHuman(invokeBoolean(next, snapshot.version)))
        }
        if (event.eventKind == 28 && (event.node.nodeId == CjguiThermostatController.nodeIdNote
            || event.node.nodeId == CjguiThermostatController.nodeIdHandScrollNote)) {
            return applyNote(domain.executeFromHuman(invokeNote(event.text, snapshot.version)))
        }
        return CjguiComposableUiDispatchResult(false)
    }

    // ---- presentation 消费者（备注 TEXT 投影） ----
    // 点选/拖选：BEGIN 冻结锚点 caret；END 经**公共持留排版命中**取落点并按
    // 公共范围会话安装选区（restore 链在 accepted 场景上安装、回 ADOPTED2）。
    // 命中具名不保留/未命中时不臆造 caret，保持上一合法选区。

    private func boundNotePresentationSession(window: CjguiComposableUiWindow): CjguiTextSession {
        if (let Some(bound) <- notePresentationSession) {
            if (window.ownedTextSessionBoundNodeId() == CjguiThermostatController.nodeIdNotePresentation) {
                // 会话仍绑定本锚点：不重建（组合态/选区保留，与生成字段绑定同一语义）。
                return bound
            }
        }
        let session = CjguiGeneratedFieldRangeSession(generatedBinding, "note")
        let bound = window.bindRangeTextSession(CjguiThermostatController.nodeIdNotePresentation,
            "thermo-note-presentation", session, session,
            CjguiThermostatDomain.resourceId, CJGUI_COMPOSABLE_UI_TEXT)
        notePresentationSession = Some(bound)
        return bound
    }

    /// 公共持留排版命中：点选位置 → 备注 UTF-16 caret。命中失败返回 -1
    /// （layout_not_retained 等具名结果），调用方不臆造落点。
    /// BEGIN 冻结命中票据（查询内已核对预期场景），END 用框架入口复核后才换算。
    /// 换算只发生在票据逐项复核通过之后，不存在旧坐标贴当前版本。
    private func freezeNotePresentationHit(window: CjguiComposableUiWindow,
        event: CjguiComposableUiEvent): ?CjguiPresentationHitTicket {
        return window.freezePresentationHit(CjguiThermostatController.nodeIdNotePresentation,
            Float64(event.pointerX), Float64(event.pointerY))
    }

    private func handleNotePresentationPointer(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let window = match (presentationWindow) {
            case Some(value) => value
            case None => return CjguiComposableUiDispatchResult(false)
        }
        let session = boundNotePresentationSession(window)
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN) {
            notePresentationAnchor = freezeNotePresentationHit(window, event)
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) {
            let focusTicket = freezeNotePresentationHit(window, event)
            let anchorTicket = notePresentationAnchor
            notePresentationAnchor = None
            let anchorAdopted = match (anchorTicket) {
                case Some(t) => window.adoptPresentationHitCaret(
                    CjguiThermostatController.nodeIdNotePresentation, t)
                case None => (1, -1)
            }
            let focusAdopted = match (focusTicket) {
                case Some(t) => window.adoptPresentationHitCaret(
                    CjguiThermostatController.nodeIdNotePresentation, t)
                case None => (1, -1)
            }
            println("THERMO_PRES_END anchor=${anchorAdopted[0]}:${anchorAdopted[1]} focus=${focusAdopted[0]}:${focusAdopted[1]}")
            if (anchorAdopted[0] != 0 || focusAdopted[0] != 0) {
                println("THERMO_PRES_END stale_ticket anchorStatus=${anchorAdopted[0]} focusStatus=${focusAdopted[0]}")
                return CjguiComposableUiDispatchResult(true)
            }
            let anchor16 = anchorAdopted[1]
            let focus16 = focusAdopted[1]
            if (focus16 >= 0) {
                var start16 = focus16
                var end16 = focus16
                if (anchor16 >= 0 && anchor16 != focus16) {
                    start16 = if (anchor16 < focus16) { anchor16 } else { focus16 }
                    end16 = if (anchor16 < focus16) { focus16 } else { anchor16 }
                }
                session.setSelection16(start16, end16)
                session.markNativeSelectionRestoreRequired()
                // B3：就绪事实取窗口侧的**镜像声明晋升**（声明已随当前绑定写入
                // native，且其后完成过至少一次 accepted present）。BEGIN 时绑定
                // 成功不等于这代声明可编辑——同手势内聚焦只会再建一个上下文，
                // 先者的恢复票据从此 stale。落点判据在 END 现读，不用缓存。
                let declarationReady = window.ownedTextMirrorDeclarationReady()
                println("THERMO_PRES_END declarationReady=${declarationReady} " +
                    "focusPending=${presentationFocusPending()}")
                if (declarationReady && !presentationFocusPending()) {
                    // 重复点选已就绪锚点且无待决首绑焦点：焦点直接请求即可复用
                    // live context。不得与待决请求各建一个上下文
                    //（双上下文会让先者的恢复票据永远 stale，输入门保持关闭）。
                    let _focused = window.focusAcceptedSemanticNode("thermo-note-presentation")
                } else {
                    // 声明尚未晋升（首绑/换绑/owner 推进后的重声明）：镜像声明要
                    // 等本次重建 accept 后才晋升，焦点由宿主循环在场景接受后消费
                    //（requestPresentationFocusAfterAccept），不按时间等待。
                    requestPresentationFocusAfterAccept()
                    localRevision += 1
                    // 本地修订要显式请求刷新才会触发重建/提交（宿主 tick 只泵
                    // 事件；宿主线程的刷新请求是权威通道）。
                    window.requestRefresh()
                }
            }
            return CjguiComposableUiDispatchResult(focus16 >= 0)
        }
        return CjguiComposableUiDispatchResult(true)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        statusText = if (eventKind == 11) { "输入队列已满：本次输入未应用，请重试" }
            else { "输入未应用：事件 ${eventKind} 的原控件已刷新（节点 ${nodeId}）" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }

    private func invoke(action: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation(action, expectedVersion,
            ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>())
    }

    private func invokeBoolean(value: Bool, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("SET_ECO", expectedVersion,
            ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.boolean(value))
            ]))
    }

    private func invokeNote(text: String, expectedVersion: Int64): CjguiSharedOperationActionInvocation {
        return CjguiSharedOperationActionInvocation("SET_NOTE", expectedVersion,
            ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))
            ]))
    }

    private func applyTemp(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.thermostatSnapshot()
        statusText = if (result.applied) {
            "目标温度已应用 v${result.versionAfter} · ${snapshot.targetTemp}℃"
        } else if (result.reason == "temp_out_of_range") {
            "温度未应用：16-30℃（当前 ${snapshot.targetTemp}℃）"
        } else if (result.reason == "version_conflict") {
            "温度未应用：内容已被外部更新，请基于新值重试"
        } else {
            "温度未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyImage(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        statusText = if (result.applied) { "热图已切换到 v${domain.thermostatSnapshot().imageVersion}" }
            else { "热图未切换：${result.reason}" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyEco(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.thermostatSnapshot()
        statusText = if (result.applied) { "节能已应用 v${result.versionAfter} · ${snapshot.eco}" }
            else if (result.reason == "version_conflict") { "节能未应用：内容已被外部更新" }
            else { "节能未应用：${result.reason}" }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func applyNote(result: CjguiSharedOperationActionResult): CjguiComposableUiDispatchResult {
        let snapshot = domain.thermostatSnapshot()
        statusText = if (result.applied) {
            "备注已应用 v${result.versionAfter} · ${snapshot.note}"
        } else if (result.reason == "note_out_of_range") {
            "备注未应用：≤64 字符（当前 ${snapshot.note}）"
        } else if (result.reason == "version_conflict") {
            "备注未应用：内容已被外部更新，请基于新值重试"
        } else {
            "备注未应用：${result.reason}"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(result.applied)
    }
}
