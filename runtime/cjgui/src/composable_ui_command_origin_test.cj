package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private func commandOriginSource(token!: UInt64 = 19u64, capturedScene!: UInt64 = 17u64,
    eventKind!: UInt32 = 34u32, sessionGeneration!: UInt64 = 6u64,
    targetNodeId!: UInt64 = 41u64, targetResourceId!: Int64 = 3,
    targetNodeKind!: UInt32 = 13u32, focusedNodeId!: UInt64 = 41u64,
    focusedResourceId!: Int64 = 3, focusedNodeKind!: UInt32 = 13u32,
    bindingEpoch!: UInt64 = 8u64, ownerVersion!: Int64 = -1): CjguiInternalRendererCommandSource {
    var source = CjguiInternalRendererCommandSource()
    source.originSerial = 22u64
    source.sessionGeneration = sessionGeneration
    source.capturedScene = capturedScene
    source.declarationToken = token
    source.targetNodeId = targetNodeId
    source.targetResourceId = targetResourceId
    source.targetNodeKind = targetNodeKind
    source.isValid = 1u32
    source.focusedNodeId = focusedNodeId
    source.focusedResourceId = focusedResourceId
    source.focusedNodeKind = focusedNodeKind
    source.originEventKind = eventKind
    source.bindingEpoch = bindingEpoch
    source.ownerVersion = ownerVersion
    return source
}

@Test
func commandOriginContinuityAllowsNativeVerifiedPureRedrawWithUnownedBodyVersion(): Unit {
    let source = commandOriginSource()
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), true)
}

@Test
func commandOriginContinuityRejectsChangedDeclarationTargetFocusAndBinding(): Unit {
    let source = commandOriginSource()
    @Assert(cjguiCommandSourceContinuityMatches(source, 41u32, 0u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 18u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        41u64, 3, 13u32, 20u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        41u64, 3, 13u32, 19u64, 42u64, 3, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 4, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 14u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        42u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 0u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 9u64, 12, 12), false)
}

@Test
func commandOriginContinuityRejectsNonzeroEventGenerationMismatchAndOwnerRevisionChange(): Unit {
    let source = commandOriginSource(ownerVersion: 12)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 6u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), true)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 7u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 12), false)
    @Assert(cjguiCommandSourceContinuityMatches(source, 34u32, 6u64, 17u64,
        41u64, 3, 13u32, 19u64, 41u64, 3, 13u32, 8u64, 8u64, 12, 13), false)
}

@Test
func commandDispatchProofPreservesNoBodyOwnerSentinel(): Unit {
    let proof = CjguiComposableUiCommandDispatchProof(commandOriginSource(), 18u64, "undo")
    @Assert(proof.ownerVersion, -1)
    @Assert(proof.capturedScene, 17u64)
    @Assert(proof.acceptedScene, 18u64)
    @Assert(proof.commandId, "undo")
}
