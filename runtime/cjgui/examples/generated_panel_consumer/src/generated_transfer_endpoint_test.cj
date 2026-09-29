package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*

private func transferTestPanel(): CjguiTaskGeneratedRegion {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(8101, "transfer-test", false)
    ]))
    return CjguiTaskGeneratedRegion(domain, 8101)
}

private func transferStructure(targetKey: String, sourceKey: String, targetAction: String,
    sourceFirst!: Bool = false): String {
    let target = "NODE 1 ${targetKey} action action=${targetAction}\n" +
        "PROPERTY 1 ${targetKey} label 接收 PNG\n" +
        "PROPERTY 1 ${targetKey} transferRole TARGET\n" +
        "PROPERTY 1 ${targetKey} transferFormat image/png\n"
    let source = "NODE 1 ${sourceKey} action action=PNG_TRANSFER_ENDPOINT\n" +
        "PROPERTY 1 ${sourceKey} label 拖出 PNG\n" +
        "PROPERTY 1 ${sourceKey} transferRole SOURCE\n" +
        "PROPERTY 1 ${sourceKey} transferFormat image/png\n"
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\n" +
        (if (sourceFirst) { source + target } else { target + source }) + "END"
}

private func acceptTransferCandidate(region: CjguiTaskGeneratedRegion, structure: String,
    expectedVersion: Int64): Bool {
    let submitted = region.submitStructure(structure, expectedVersion)
    if (!submitted.candidateAccepted) { return false }
    if (!region.beginSceneRefresh()) { return false }
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    if (!region.prepareSceneRefresh()) {
        region.rollbackSceneRefresh()
        return false
    }
    region.commitSceneRefresh()
    return region.acceptedStructureVersion() == expectedVersion + 1
}

private func generatedTransferFixtureOffer(): CjguiSharedOperationTransferOffer {
    let bytes: Array<Byte> = [0x89u8, 0x50u8, 0x4Eu8, 0x47u8]
    return CjguiSharedOperationTransferOffer.createBinary("COPY", "fixture",
        "generated-transfer-test", 1, CjguiSharedOperationTransferFormat.png(), bytes).getOrThrow()
}

@Test
func generatedNormalStructurePublishesAndAcceptsFileSource(): Unit {
    let region = transferTestPanel()
    let normal = CjguiTaskGeneratedRegion.effectStructure(0, true)
    @Assert(normal.contains("generatedPngTarget transferFileSource local_file_url"), true)
    @Assert(region.capabilitiesPayload().contains("file_url_format=public.file-url"), true)
    @Assert(region.submitStructure(normal, 0).candidateAccepted, true)
    let invalid = normal.replace("transferFileSource local_file_url",
        "transferFileSource arbitrary_url")
    let rejected = region.submitStructure(invalid, 0)
    @Assert(rejected.candidateAccepted, false)
    @Assert(rejected.reason, "transfer_file_source_unsupported")
}

private class GeneratedTransferTestController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiDataTransferProvider {
    private let region: CjguiTaskGeneratedRegion
    private let fixtureOffer: CjguiSharedOperationTransferOffer
    private var lastStagedDeclarationCount: Int64 = 0
    private var lastStagedTargetSemanticId: String = ""
    private var lastStagedTargetIncarnation: Int64 = 0
    private var forceInvalidTransferDeclaration: Bool = false

    public init(region: CjguiTaskGeneratedRegion) {
        this.region = region
        this.fixtureOffer = generatedTransferFixtureOffer()
    }
    public func uiSceneVersion(): Int64 { return region.revision() }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(99000, "transfer-test-root", CjguiComposableUiStyle(gap: 4))
        root.add(region.buildSection(CjguiComposableUiTheme.beaconDark()))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        for (endpoint in region.refreshTransferEndpoints()) {
            if (endpoint.role == "TARGET") {
                lastStagedTargetSemanticId = endpoint.semanticId
                lastStagedTargetIncarnation = endpoint.receiverIncarnation
                declarations.add(CjguiComposableUiDataTransferDeclaration.target(endpoint.semanticId,
                    CjguiSharedOperationTransferFormat.png(), receiverIncarnation: endpoint.receiverIncarnation))
            } else if (endpoint.role == "SOURCE") {
                declarations.add(CjguiComposableUiDataTransferDeclaration.source(endpoint.semanticId, fixtureOffer))
            }
        }
        if (forceInvalidTransferDeclaration) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.target("missing-generated-semantic",
                CjguiSharedOperationTransferFormat.png()))
        }
        lastStagedDeclarationCount = declarations.size
        return declarations
    }
    public func stagedDeclarationCount(): Int64 { return lastStagedDeclarationCount }
    public func stagedTargetSemanticId(): String { return lastStagedTargetSemanticId }
    public func stagedTargetIncarnation(): Int64 { return lastStagedTargetIncarnation }
    public func setInvalidTransferDeclaration(enabled: Bool): Unit {
        forceInvalidTransferDeclaration = enabled
    }
    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func dataTransferOwnerVersion(node: CjguiComposableUiLayoutNode): Int64 {
        for (endpoint in region.acceptedTransferEndpoints()) {
            if (endpoint.role == "TARGET" && endpoint.nodeId == node.nodeId) { return 0 }
        }
        return -1
    }
    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { region.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { region.rollbackSceneRefresh() }
}

@Test
func generatedTransferEndpointMetadataFollowsOnlyAcceptedCandidates(): Unit {
    let region = transferTestPanel()
    let normal = CjguiTaskGeneratedRegion.effectStructure(0, true)
    @Assert(normal.contains("generatedPngTarget transferRole TARGET"), true)
    @Assert(normal.contains("generatedPngSource transferRole SOURCE"), true)
    @Assert(region.acceptedTransferMetadataPayload().contains("target=none"), true)
    @Assert(acceptTransferCandidate(region, transferStructure("pngDrop", "pngSource", "PNG_TRANSFER_ENDPOINT"), 0), true)
    let firstTargetNode = region.acceptedNodeIdForKey("pngDrop")
    let firstSourceNode = region.acceptedNodeIdForKey("pngSource")
    @Assert(firstTargetNode > 0, true)
    @Assert(firstSourceNode > 0, true)
    let first = region.acceptedTransferMetadataPayload()
    @Assert(first.contains("target=pngDrop"), true)
    @Assert(first.contains("source=pngSource"), true)
    @Assert(first.contains("format=image/png"), true)
    let firstEndpoints = region.acceptedTransferEndpoints()
    // This focused region transaction built real identities, but only the
    // separate provider/window test below proves native binding acceptance.
    @Assert(firstEndpoints.size, 2)

    // Once begin pins the successful candidate token, a second submission must
    // not supersede metadata while the native scene still owns its snapshot.
    @Assert(region.submitStructure(transferStructure("replacement", "replacementSource",
        "PNG_TRANSFER_ENDPOINT"), 1).candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    @Assert(region.prepareSceneRefresh(), true)
    let busySubmit = region.submitStructure(transferStructure("tooLate", "tooLateSource",
        "PNG_TRANSFER_ENDPOINT"), 1)
    @Assert(busySubmit.candidateAccepted, false)
    @Assert(busySubmit.reason, "scene_refresh_busy")
    region.rollbackSceneRefresh()
    @Assert(region.acceptedTransferEndpoints()[0].declaredKey, "pngDrop")
    @Assert(region.acceptedTransferMetadataPayload(), first)

    // Reorder with stable keys and owner action preserves the target incarnation.
    @Assert(acceptTransferCandidate(region,
        transferStructure("pngDrop", "pngSource", "PNG_TRANSFER_ENDPOINT", sourceFirst: true), 1), true)
    let reordered = region.acceptedTransferMetadataPayload()
    @Assert(reordered, first.replace("version=1", "version=2"))

    // Same generated key but a new action binding is a new receiver incarnation.
    @Assert(acceptTransferCandidate(region,
        transferStructure("pngDrop", "pngSource", "CONTROL_BUTTON"), 2), true)
    let rebound = region.acceptedTransferMetadataPayload()
    @Assert(rebound.contains("target_action=CONTROL_BUTTON"), true)
    @Assert(rebound.contains("receiver_incarnation=2"), true)

    // Removing and later restoring a target changes the accepted binding
    // generation even when the declared key is reused.
    let noEndpoints = "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\nEND"
    @Assert(acceptTransferCandidate(region, noEndpoints, 3), true)
    @Assert(region.acceptedTransferEndpoints().size, 0)
    @Assert(region.acceptedTransferMetadataPayload().contains("receiver_incarnation=3"), true)
    @Assert(acceptTransferCandidate(region,
        transferStructure("pngDrop", "pngSource", "CONTROL_BUTTON"), 4), true)
    let restored = region.acceptedTransferMetadataPayload()
    @Assert(restored.contains("receiver_incarnation=4"), true)
    let restoredTargetNode = region.acceptedNodeIdForKey("pngDrop")
    let restoredSourceNode = region.acceptedNodeIdForKey("pngSource")

    // A candidate refused by the registered value domain cannot publish a new
    // key or incarnation. The previously accepted descriptor remains readable.
    let invalid = transferStructure("pngDropRejected", "pngSourceRejected", "PNG_TRANSFER_ENDPOINT")
        .replace("transferRole TARGET", "transferRole RECEIVER")
    let rejected = region.submitStructure(invalid, 5)
    @Assert(rejected.candidateAccepted, false)
    @Assert(region.acceptedTransferMetadataPayload(), restored)
    @Assert(region.acceptedNodeIdForKey("pngDrop"), restoredTargetNode)
    @Assert(region.acceptedNodeIdForKey("pngSource"), restoredSourceNode)
    @Assert(region.acceptedNodeIdForKey("pngDropRejected") < 0, true)

    // Build the already accepted generated structure into a real window scene.
    // Endpoint IDs must resolve from accepted generated instances, never from a
    // candidate-only key or a synthetic semantic string.
    let controller = GeneratedTransferTestController(region)
    let window = CjguiComposableUiWindow(controller)
    region.attachWindow(window)
    @Assert(window.start(), true)
    let endpoints = region.acceptedTransferEndpoints()
    @Assert(endpoints.size, 2)
    @Assert(endpoints[0].declaredKey, "pngDrop")
    @Assert(endpoints[0].role, "TARGET")
    @Assert(endpoints[0].format, "image/png")
    @Assert(endpoints[0].semanticId.size > 0, true)
    @Assert(endpoints[0].receiverIncarnation, 4)
    @Assert(endpoints[1].declaredKey, "pngSource")
    @Assert(endpoints[1].role, "SOURCE")
    @Assert(endpoints[1].semanticId.size > 0, true)
    @Assert(region.acceptedInstancesPayload().contains("INSTANCE pngDrop "), true)
    window.close()
}

@Test
func generatedTransferProviderStagesOnlyTheSceneBeingAccepted(): Unit {
    let region = transferTestPanel()
    let controller = GeneratedTransferTestController(region)
    let window = CjguiComposableUiWindow(controller)
    region.attachWindow(window)
    @Assert(window.start(), true)
    @Assert(region.acceptedTransferEndpoints().size, 0)

    // The provider reads the exact build snapshot while window.refresh stages
    // its scene and declarations in one transaction.
    let submitted = region.submitStructure(
        transferStructure("endpointA", "sourceA", "PNG_TRANSFER_ENDPOINT"), 0)
    @Assert(submitted.candidateAccepted, true)
    @Assert(region.acceptedTransferEndpoints().size, 0)
    @Assert(window.refresh(), true)
    let accepted = region.acceptedTransferEndpoints()
    @Assert(accepted.size, 2)
    @Assert(accepted[0].declaredKey, "endpointA")
    @Assert(accepted[0].nodeId > 0, true)
    @Assert(accepted[0].semanticId.size > 0, true)
    @Assert(accepted[1].declaredKey, "sourceA")
    @Assert(controller.stagedDeclarationCount(), 2)

    // Replace A with B in a real window acceptance. The provider no longer
    // stages A's old semantic target when B's candidate is submitted.
    @Assert(region.submitStructure(transferStructure("endpointB", "sourceB",
        "PNG_TRANSFER_ENDPOINT"), 1).candidateAccepted, true)
    @Assert(window.refresh(), true)
    let acceptedB = region.acceptedTransferEndpoints()
    @Assert(acceptedB[0].declaredKey, "endpointB")
    @Assert(acceptedB[0].semanticId == accepted[0].semanticId, false)
    @Assert(acceptedB[0].receiverIncarnation, accepted[0].receiverIncarnation + 1)
    @Assert(controller.stagedDeclarationCount(), 2)
    @Assert(controller.stagedTargetSemanticId(), acceptedB[0].semanticId)

    // Same keys and action keep incarnation; a same-key action replacement
    // increments it. Reordering changes neither endpoint identities nor epoch.
    @Assert(region.submitStructure(transferStructure("endpointB", "sourceB",
        "PNG_TRANSFER_ENDPOINT", sourceFirst: true), 2).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedTransferEndpoints()[0].semanticId, acceptedB[0].semanticId)
    @Assert(region.acceptedTransferEndpoints()[0].receiverIncarnation,
        acceptedB[0].receiverIncarnation)
    @Assert(region.submitStructure(transferStructure("endpointB", "sourceB",
        "CONTROL_BUTTON"), 3).candidateAccepted, true)
    @Assert(window.refresh(), true)
    @Assert(region.acceptedTransferEndpoints()[0].receiverIncarnation,
        acceptedB[0].receiverIncarnation + 1)
    @Assert(controller.stagedTargetIncarnation(), acceptedB[0].receiverIncarnation + 1)

    // A candidate with a stale provider semantic is rejected before native
    // commit; rollback preserves the prior accepted endpoint and generation.
    let beforeReject = region.acceptedTransferEndpoints()
    @Assert(region.submitStructure(transferStructure("rejectedTarget", "rejectedSource",
        "PNG_TRANSFER_ENDPOINT"), 4).candidateAccepted, true)
    controller.setInvalidTransferDeclaration(true)
    @Assert(window.refresh(), false)
    controller.setInvalidTransferDeclaration(false)
    @Assert(region.acceptedTransferEndpoints()[0].declaredKey, "endpointB")
    @Assert(region.acceptedTransferEndpoints()[0].semanticId, beforeReject[0].semanticId)
    @Assert(region.acceptedTransferEndpoints()[0].receiverIncarnation,
        beforeReject[0].receiverIncarnation)
    window.close()
}
