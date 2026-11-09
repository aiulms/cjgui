package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*

/// 宿主对外连接与“当前原型会话”之间的稳定桥。一个运行中的宿主只创建一个外部连接；
/// 切换项目时只把桥的目标 session 换掉，descriptor/连接不变。
///
/// 为什么需要桥：外部连接在 start 前一次性绑定 domain/provider，且宿主已启动后不能改绑。
/// 若切换项目只替换控制器里的 session，连接仍会指向旧 owner/旧区域——模型看到的还是旧项目。
/// 桥把两者解耦后：可见窗口与外部连接都通过 `currentSession()` 取同一个新会话。
///
/// R1 跨会话隔离：写请求绑定其创建依据所属的会话版本带。桥向客户端发布的每一个
/// 版本号都加上当前会话的 `sessionVersionBase`，而新会话的 base 被设置为**严格大于**
/// 本桥历史上发布过的最大版本号。于是：
/// - 旧会话产生的请求携带的版本永远低于新 base，无论客户端读没读过新会话，
///   都以 `stale_session_generation` 拒绝，读取不能替旧请求“补上新身份”；
/// - 基于新会话读取创建的合法请求天然落在新版本带内，正常完成；
/// - 同一 descriptor 下发现新项目、创建新请求和继续操作的能力保持不变。
/// 该机制只重用既有版本检查，不新增 RPC 或通用会话框架；数值带单调、不复用。
class PrototypeHostBridge <: CjguiSharedOperationDomain & CjguiSharedOperationGeneratedUiProvider {
    private var session: PrototypeSession
    private var generationValue: Int64 = 1
    /// 当前会话版本带的基址；首个会话为 0（发布的版本与区域原始值一致）。
    private var sessionVersionBase: Int64 = 0
    /// 本桥向客户端发布过的最大版本号（跨所有历史会话）。
    private var maxPublishedVersion: Int64 = 0
    private var measurementRecorder: ?PrototypeMeasurementRecorder = None

    func setMeasurementRecorder(recorder: PrototypeMeasurementRecorder): Unit {
        measurementRecorder = Some(recorder)
    }

    init(session: PrototypeSession) {
        this.session = session
    }

    /// 新会话完全准备好后调用；这是桥唯一的目标替换点。
    func adopt(next: PrototypeSession): Unit {
        this.session = next
        this.generationValue += 1
        // 新版本带严格高于历史发布过的任何版本，旧请求的数字永远进不了新带。
        this.sessionVersionBase = this.maxPublishedVersion + 1
    }

    func generation(): Int64 {
        return generationValue
    }

    func currentSession(): PrototypeSession {
        return session
    }

    private func domain(): PrototypeProjectDomain {
        return session.domain
    }

    private func region(): CjguiGeneratedUiWindowRegion {
        return session.region
    }

    /// 把区域/领域的原始版本号发布到客户端版本带，并推进历史最大发布值。
    private func publishVersion(raw: Int64): Int64 {
        if (raw < 0) {
            return raw
        }
        let published = sessionVersionBase + raw
        if (published > maxPublishedVersion) {
            maxPublishedVersion = published
        }
        return published
    }

    /// 客户端提交的版本必须落在本会话版本带内；低于当前 base 的数字只能来自
    /// 之前的会话（或凭空捏造），按陈旧会话拒绝。
    private func inboundVersion(expectedVersion: Int64): ?Int64 {
        if (expectedVersion < sessionVersionBase) {
            return None
        }
        return Some(expectedVersion - sessionVersionBase)
    }

    private func staleGenerationSubmit(): CjguiSharedOperationGeneratedUiSubmit {
        let current = publishVersion(region().acceptedStructureVersion())
        return CjguiSharedOperationGeneratedUiSubmit(false, "stale_session_generation", "", current, current)
    }

    private func staleGenerationAction(): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 0, 0, "stale_session_generation")
    }

    private func bandedSubmit(result: CjguiSharedOperationGeneratedUiSubmit): CjguiSharedOperationGeneratedUiSubmit {
        return CjguiSharedOperationGeneratedUiSubmit(result.accepted, result.reason, result.path,
            publishVersion(result.versionBefore), publishVersion(result.versionAfter),
            sceneAccepted: result.sceneAccepted, candidateVersion: publishVersion(result.candidateVersion),
            candidateToken: result.candidateToken, receipt: result.receipt)
    }

    /// R1: the atomic snapshot's structure version (and the structure line
    /// embedded in its SNAPSHOT_STRUCTURE section) must be published in the
    /// SAME band as `acceptedStructureVersion()`. Otherwise the public client
    /// builds a plan base from a raw local version and the bridge rejects it
    /// after a session switch even though the client did the documented reads.
    private func bridgeParseInt(token: String): Int64 {
        return try {
            Int64.parse(token)
        } catch (_: Exception) {
            -1
        }
    }

    private func bandSnapshotPayload(text: String): String {
        let builder = StringBuilder()
        var first = true
        for (line in text.split("\n")) {
            var rewritten = line
            for ((prefix, offset) in [("ACCEPTED_STRUCTURE_VERSION ", 0), ("SNAPSHOT_STRUCTURE STRUCTURE ", 0)]) {
                if (line.startsWith(prefix)) {
                    let token = line[prefix.size..]
                    let raw = bridgeParseInt(token)
                    if (raw >= 0) {
                        rewritten = "${prefix}${publishVersion(raw)}"
                    }
                }
            }
            if (!first) {
                builder.append("\n")
            }
            first = false
            builder.append(rewritten)
        }
        return builder.toString()
    }

    /// R1: the accepted structure readback starts with `STRUCTURE <version>`;
    /// band that structure-scope number only (owner revisions, cursors and
    /// history versions keep their own scopes and are NOT rewritten).
    private func bandAcceptedStructurePayload(text: String): String {
        let marker = "STRUCTURE "
        if (!text.startsWith(marker)) {
            return text
        }
        let newline = match (text.indexOf("\n")) {
            case Some(value) => value
            case None => -1
        }
        let firstLine = if (newline < 0) { text } else { text[0..newline] }
        let rest = if (newline < 0) { "" } else { text[newline..] }
        let raw = bridgeParseInt(firstLine[marker.size..])
        if (raw < 0) {
            return text
        }
        return "${marker}${publishVersion(raw)}${rest}"
    }

    /// R1: candidate state/ticket `ACCEPTED_VERSION` is the accepted structure
    /// version of its session; publish it in the same band so a candidate
    /// terminal check and the following snapshot agree.
    private func bandCandidatePayload(text: String): String {
        let builder = StringBuilder()
        var first = true
        for (line in text.split("\n")) {
            var rewritten = line
            let marker = "ACCEPTED_VERSION "
            if (line.startsWith(marker)) {
                let raw = bridgeParseInt(line[marker.size..])
                if (raw >= 0) {
                    rewritten = "${marker}${publishVersion(raw)}"
                }
            }
            if (!first) {
                builder.append("\n")
            }
            first = false
            builder.append(rewritten)
        }
        return builder.toString()
    }

    /// R1: after a session switch an identity-free (negative version) external
    /// write cannot be attributed to the current session. It is refused with a
    /// named reason instead of being forwarded to the new owner. Versioned
    /// writes stay available and are checked against the version band.
    private func sessionIdentityRequiredAction(): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(false, false, 0, 0, "session_identity_required")
    }

    // ——— CjguiSharedOperationDomain ———

    public func resourceType(): String {
        return domain().resourceType()
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let raw = domain().contextSnapshot()
        return CjguiSharedOperationContextSnapshot(publishVersion(raw.version), raw.contextName,
            raw.resourceType, raw.resources, relations: raw.relations, streamIdentity: raw.streamIdentity,
            ownerState: raw.ownerState)
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return domain().actionDescriptors()
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation):
        CjguiSharedOperationActionResult {
        return domain().executeFromHuman(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation):
        CjguiSharedOperationActionResult {
        // 版本化的调用必须携带本会话版本带内的数字。负版本按既有契约表示
        // “不校验版本”，属无版本请求，不因会话切换而改变语义。
        let translated = match (inboundVersion(invocation.expectedVersion)) {
            case Some(raw) => raw
            case None =>
                if (invocation.expectedVersion >= 0) {
                    return staleGenerationAction()
                }
                // R1: identity-free business write after a session switch.
                if (generationValue > 1) {
                    return sessionIdentityRequiredAction()
                }
                invocation.expectedVersion
        }
        let result = domain().executeFromExternal(CjguiSharedOperationActionInvocation(
            invocation.actionName, translated, invocation.targetResourceIds, invocation.arguments))
        return CjguiSharedOperationActionResult(result.applied, result.isVersionConflict,
            publishVersion(result.versionBefore), publishVersion(result.versionAfter), result.reason)
    }

    // ——— CjguiSharedOperationGeneratedUiProvider ———

    public func capabilitiesPayload(): String {
        return region().capabilitiesPayload()
    }

    public func fieldsPayload(): String {
        return region().fieldsPayload()
    }

    public func fieldsPayload(instanceKey: String): String {
        return region().fieldsPayload(instanceKey)
    }

    public func fieldsPayloadForOwner(ownerResourceId: Int64): String {
        return region().fieldsPayloadForOwner(ownerResourceId)
    }

    public func instanceOwnerResourceId(instanceKey: String): Int64 {
        return region().instanceOwnerResourceId(instanceKey)
    }

    public func acceptedStructurePayload(): String {
        return bandAcceptedStructurePayload(region().acceptedStructurePayload())
    }

    public func acceptedStructureVersion(): Int64 {
        return publishVersion(region().acceptedStructureVersion())
    }

    public func submitStructure(candidatePayload: String,
        expectedVersion: Int64): CjguiSharedOperationGeneratedUiSubmit {
        // R1：请求的数值版本必须属于当前会话的版本带。
        let translated = match (inboundVersion(expectedVersion)) {
            case Some(raw) => raw
            case None => return staleGenerationSubmit()
        }
        var observation: ?PrototypeMeasurementRecord = None
        if (let Some(recorder) <- measurementRecorder) {
            observation = recorder.begin("public_submit", "generated_structure", 0u64)
        }
        let result = region().submitStructure(candidatePayload, translated)
        if (let Some(recorder) <- measurementRecorder) {
            recorder.complete(observation, result.accepted, "public_submit_${result.reason}")
        }
        return bandedSubmit(result)
    }

    public func candidateStructureVersion(): Int64 {
        return publishVersion(region().candidateStructureVersion())
    }

    public func sceneState(): String {
        return region().sceneState()
    }

    public func acceptedInstancesPayload(): String {
        return region().acceptedInstancesPayload()
    }

    public func candidateTicketPayload(token: Int64): String {
        return bandCandidatePayload(region().candidateTicketPayload(token))
    }

    public func snapshotPayload(): String {
        return bandSnapshotPayload(region().snapshotPayload())
    }

    public func changesPayload(streamEpoch: Int64, cursor: Int64): String {
        return region().changesPayload(streamEpoch, cursor)
    }

    public func sectionPayload(section: String, expectedCursor: Int64): String {
        return region().sectionPayload(section, expectedCursor)
    }

    public func uiDocumentHistoryPayload(): String {
        // 界面历史以自身每会话唯一的 surface 身份/epoch 隔离旧请求（见
        // CjguiUiDocumentHistory），其版本随 payload 原样发布、原样回读，
        // 不与结构/业务版本带混用。
        return region().uiDocumentHistoryPayload()
    }

    public func submitUiDocumentHistory(action: String, expectedVersion: Int64, expectedDigest: String,
        surfaceIdentity: Int64, historyEpoch: Int64): CjguiSharedOperationGeneratedUiSubmit {
        // 界面历史写请求的身份由文档会话的 surface/epoch 承担：新会话的
        // epoch 由进程级分配器新发，旧请求携带的旧身份在新会话上必然失配。
        return region().submitUiDocumentHistory(action, expectedVersion, expectedDigest, surfaceIdentity,
            historyEpoch)
    }
}
