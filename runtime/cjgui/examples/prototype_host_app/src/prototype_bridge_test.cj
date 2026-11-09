package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

// R1 的针对性反例：两个项目使用相同字段、相同数值版本（都还是 0），
// 切换后把切换前取得的请求投给桥。
// - RED 条件：新 region 本身会接受同版本 + 兼容字段的旧候选（版本/字段检查无法隔离）；
// - GREEN：桥按“会话版本带”拒绝旧请求——客户端读不读新会话都不能让它通过；
// - 基于新会话读取创建的合法请求落在新版本带内，正常完成。
// 旧实现（observedGeneration 门）在“读一次新会话后同一旧候选被接受”，已被否定。

private func prototypeBridgeTestProject(suffix: String, title: String): (String, PrototypeSession) {
    let declaration = "{\"schema\":\"cjgui.prototype-project.v1\",\"id\":\"bridge-project-" + suffix +
        "\",\"title\":\"" + title + "\",\"fields\":[" +
        "{\"id\":\"alpha\",\"label\":\"甲\",\"kind\":\"text\",\"value\":\"a0\"}," +
        "{\"id\":\"beta\",\"label\":\"乙\",\"kind\":\"integer\",\"minimum\":1,\"maximum\":9,\"value\":2}]}"
    let root = prototypeTestTempProject(declaration)
    return (root, PrototypeSession(PrototypeProjectLoader.load(root), false))
}

private let prototypeBridgeCandidate: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 bridge-root vertical
NODE 1 bridge-label label
PROPERTY 1 bridge-label text candidate
END
"""

@Test
func prototypeBridgeNewRegionAloneWouldAcceptOldStyleCandidate(): Unit {
    // RED 证据：不经桥时，同字段、同数值版本 0 足以让新 region 接受请求——
    // 版本与字段兼容检查本身无法区分两个会话。
    let (_, sessionA) = prototypeBridgeTestProject("a", "项目甲")
    let (_, sessionB) = prototypeBridgeTestProject("b", "项目乙")
    @Assert(sessionA.region.acceptedStructureVersion(), 0)
    @Assert(sessionB.region.acceptedStructureVersion(), 0)
    let direct = sessionB.region.submitStructure(prototypeBridgeCandidate, 0)
    @Assert(direct.candidateAccepted, true)
    // 提交被接收（场景接受前的候选版本已就位）；场景提交是另一回事。
    @Assert(sessionB.region.candidateStructureVersion() >= 1, true)
}

@Test
func prototypeBridgeRejectsCrossSessionCandidateEvenAfterReads(): Unit {
    let (_, sessionA) = prototypeBridgeTestProject("c", "项目丙")
    let (_, sessionB) = prototypeBridgeTestProject("d", "项目丁")
    let bridge = PrototypeHostBridge(sessionA)
    // 会话甲期间客户端读到的版本是原始值 0。
    @Assert(bridge.acceptedStructureVersion(), 0)
    bridge.adopt(sessionB)
    @Assert(bridge.currentSession().project.id, "bridge-project-d")
    // 切换后：同一或另一客户端读取新会话（版本带基址抬升）。
    let bandedVersion = bridge.acceptedStructureVersion()
    @Assert(bandedVersion > 0, true)
    let _ = bridge.capabilitiesPayload()
    let _ = bridge.acceptedStructurePayload()
    // 旧请求（会话甲带的版本 0）在读取新会话之后仍然被拒绝，且 B 的界面/owner 不变。
    let stale = bridge.submitStructure(prototypeBridgeCandidate, 0)
    @Assert(stale.accepted, false)
    @Assert(stale.reason, "stale_session_generation")
    @Assert(sessionB.region.acceptedStructureVersion(), 0)
    // 基于新会话读取创建的合法请求（版本 = 新带发布值）正常完成。
    let accepted = bridge.submitStructure(prototypeBridgeCandidate, bandedVersion)
    @Assert(accepted.candidateAccepted, true)
    @Assert(sessionB.region.candidateStructureVersion() >= 1, true)
}

@Test
func prototypeBridgeBandsAdvanceAcrossMultipleSwitches(): Unit {
    let (_, sessionA) = prototypeBridgeTestProject("e", "项目戊")
    let (_, sessionB) = prototypeBridgeTestProject("f", "项目己")
    let (_, sessionC) = prototypeBridgeTestProject("g", "项目庚")
    let bridge = PrototypeHostBridge(sessionA)
    let aVersion = bridge.acceptedStructureVersion()
    bridge.adopt(sessionB)
    let bVersion = bridge.acceptedStructureVersion()
    @Assert(bVersion > aVersion, true)
    // 在会话乙上完成一次真实结构提交，推进其发布版本（候选接收即发布候选版本）。
    @Assert(bridge.submitStructure(prototypeBridgeCandidate, bVersion).candidateAccepted, true)
    let bVersionAfter = bridge.candidateStructureVersion()
    bridge.adopt(sessionC)
    let cVersion = bridge.acceptedStructureVersion()
    // 新会话版本带严格高于此前发布过的所有版本（含会话乙推进后的值）。
    @Assert(cVersion > bVersionAfter, true)
    // 会话乙时代的请求（bVersion / bVersionAfter）对会话丙永久失效。
    @Assert(bridge.submitStructure(prototypeBridgeCandidate, bVersion).reason, "stale_session_generation")
    @Assert(bridge.submitStructure(prototypeBridgeCandidate, bVersionAfter).reason, "stale_session_generation")
    @Assert(sessionC.region.acceptedStructureVersion(), 0)
    // 基于会话丙读取的新请求正常完成。
    @Assert(bridge.submitStructure(prototypeBridgeCandidate, cVersion).accepted, true)
}

@Test
func prototypeBridgeRejectsCrossSessionBusinessCallByVersionBand(): Unit {
    let (_, sessionA) = prototypeBridgeTestProject("h", "项目辛")
    let (_, sessionB) = prototypeBridgeTestProject("i", "项目壬")
    let bridge = PrototypeHostBridge(sessionA)
    // 会话甲期间读到的业务上下文版本。
    let aContextVersion = bridge.contextSnapshot().version
    bridge.adopt(sessionB)
    // 旧业务写入（会话甲带的版本）永久拒绝。
    let stale = bridge.executeFromExternal(CjguiSharedOperationActionInvocation("RESTORE_DEFAULTS",
        aContextVersion, ArrayList<Int64>(), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(stale.applied, false)
    @Assert(stale.reason, "stale_session_generation")
    // 基于新会话读取的合法调用正常到达当前 owner（业务结果可能是成功或
    // 字段级拒绝，但不再是 stale 门）。
    let bContextVersion = bridge.contextSnapshot().version
    @Assert(bContextVersion > aContextVersion, true)
    let routed = bridge.executeFromExternal(CjguiSharedOperationActionInvocation("RESTORE_DEFAULTS",
        bContextVersion, ArrayList<Int64>(), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(routed.reason != "stale_session_generation", true)
    // 读取不能替旧请求补上新身份：再读一次后旧版本调用仍被拒绝。
    let _ = bridge.contextSnapshot()
    let stillStale = bridge.executeFromExternal(CjguiSharedOperationActionInvocation("RESTORE_DEFAULTS",
        aContextVersion, ArrayList<Int64>(), ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(stillStale.reason, "stale_session_generation")
}

// R1：界面历史写请求的身份由文档会话每会话唯一的 surface/epoch 承担。
// 会话甲读取的历史基线（surface/epoch/版本）在切换后投递，不得写进会话乙。
@Test
func prototypeBridgeRejectsCrossSessionHistoryRequestBySessionIdentity(): Unit {
    let (_, sessionA) = prototypeBridgeTestProject("j", "项目癸")
    let (_, sessionB) = prototypeBridgeTestProject("k", "项目子")
    let bridge = PrototypeHostBridge(sessionA)
    // 会话甲期间客户端读到历史基线（无论支持与否，读回的是甲的表面身份）。
    let payloadA = bridge.uiDocumentHistoryPayload()
    @Assert(payloadA.size >= 0, true)
    bridge.adopt(sessionB)
    // 读取新会话（不能替旧历史请求补身份）。
    let payloadB = bridge.uiDocumentHistoryPayload()
    let _ = payloadB
    // 旧会话的历史提交（携带甲时代的 surface=0/epoch=0 兜底值）在乙上必须被拒。
    let staleHistory = bridge.submitUiDocumentHistory("UI_DOC_UNDO", 0, "digest", 0, 0)
    @Assert(staleHistory.accepted, false)
    @Assert(sessionB.region.acceptedStructureVersion(), 0)
}

// ——— A/R1：结构版本带必须与正常公开编辑同时成立 ———

@Test
func prototypeBridgeSnapshotCarriesBandedStructureVersionAndKeepsEditing(): Unit {
    let (_, sessionA) = prototypeBridgeTestProject("s1", "项目一")
    let (_, sessionB) = prototypeBridgeTestProject("s2", "项目二")
    let bridge = PrototypeHostBridge(sessionA)
    // First session band starts at 0, so the published snapshot version is raw.
    let snapshotA = bridge.snapshotPayload()
    @Assert(snapshotA.contains("ACCEPTED_STRUCTURE_VERSION 0"), true)
    bridge.adopt(sessionB)
    // Second session band starts above every published version (1).
    let snapshotB = bridge.snapshotPayload()
    @Assert(snapshotB.contains("ACCEPTED_STRUCTURE_VERSION 1"), true)
    @Assert(bridge.acceptedStructureVersion(), 1)
    // A request created from A's snapshot (base 0) must not edit B, even
    // after the client has read B.
    let stale = bridge.submitStructure(prototypeBridgeCandidate, 0)
    @Assert(stale.accepted, false)
    @Assert(stale.reason, "stale_session_generation")
    // A request built from B's OWN snapshot base is the normal documented path.
    let accepted = bridge.submitStructure(prototypeBridgeCandidate, 1)
    @Assert(accepted.accepted, true)
    @Assert(accepted.versionBefore >= 1, true)
    @Assert(accepted.versionAfter >= accepted.versionBefore, true)
}

@Test
func prototypeBridgeRejectsIdentityFreeBusinessWriteAfterSwitch(): Unit {
    let (_, sessionA) = prototypeBridgeTestProject("b1", "项目甲")
    let (_, sessionB) = prototypeBridgeTestProject("b2", "项目乙")
    let bridge = PrototypeHostBridge(sessionA)
    let unversioned = CjguiSharedOperationActionInvocation("RESTORE_DEFAULTS", -1, ArrayList<Int64>(),
        ArrayList<CjguiSharedOperationActionArgument>())
    // Before any switch, the historical negative-version path is unchanged
    // (the domain's own answer applies; identity is not the reason).
    @Assert(bridge.executeFromExternal(unversioned).reason != "session_identity_required", true)
    bridge.adopt(sessionB)
    let _ = bridge.contextSnapshot()
    // After a switch an identity-free write cannot be attributed to the new
    // session and is refused by name instead of being forwarded to B's owner.
    let refused = bridge.executeFromExternal(unversioned)
    @Assert(refused.applied, false)
    @Assert(refused.reason, "session_identity_required")
    // A versioned write in B's own band works and is read back from B's owner.
    let filterArguments = ArrayList<CjguiSharedOperationActionArgument>()
    filterArguments.add(CjguiSharedOperationActionArgument("query",
        CjguiSharedOperationValue.string("versioned-query")))
    let version = bridge.contextSnapshot().version
    let versioned = CjguiSharedOperationActionInvocation("FILTER_RECORDS", version,
        ArrayList<Int64>(), filterArguments)
    let versionedResult = bridge.executeFromExternal(versioned)
    @Assert(versionedResult.reason, "none")
    @Assert(sessionB.domain.queryText(), "versioned-query")
}
