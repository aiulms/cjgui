package cjgui

private func prefixFixture(kind: UInt32, ordinal: UInt32, nonce!: UInt64 = 1u64,
    generation!: UInt64 = 7u64, binding!: UInt64 = 1u64, resource!: Int64 = 102): InternalRendererPumpResult {
    var p = InternalRendererActivationPrefix()
    p.sessionGeneration = generation
    p.nonce = nonce
    p.sceneVersion = 1u64
    p.nodeId = 4u64
    p.resourceId = resource
    p.nodeKind = 4u32
    p.bindingEpoch = binding
    p.ordinal = ordinal
    p.secondKind = 27u32
    p.memberCount = 2u32
    p.memberKind = kind
    return InternalRendererPumpResult(0, kind, 0u32, 0u32, 0u32, 4u64, 1u64, resource, 4u32,
        0, 0, 0.0, 0.0, 0.0, 0.0, false, 0, 0u32, -1, 0, -1, 0,
        0u64, 0u64, 0u64, 0u64, 0u64, 0u64, -1, 0u64, 0u64, activationPrefix: p)
}

@Test
func activationPrefixNoneAndBudgetYieldDoNotEndActualPair(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(prefixFixture(31u32, 1u32), 1u64, true), 1)
    @Assert(gate.admit(prefixFixture(0u32, 0u32, nonce: 0u64), 1u64, false), 0)
    @Assert(gate.pending(), true)
    @Assert(gate.admit(prefixFixture(27u32, 2u32), 1u64, true), 2)
    gate.settleSecond()
    @Assert(gate.pending(), false)
    @Assert(gate.admit(prefixFixture(27u32, 2u32), 1u64, true), -1)
}

@Test
func activationPrefixRebindClosesAndRejectsOriginalSuffix(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(prefixFixture(31u32, 1u32), 1u64, true), 1)
    @Assert(gate.admit(prefixFixture(27u32, 2u32), 2u64, true), -1)
    @Assert(gate.pending(), false)
    @Assert(gate.admit(prefixFixture(31u32, 1u32, nonce: 2u64, binding: 2u64), 2u64, true), 1)
}

@Test
func activationPrefixIndependentEventCannotExtendOldNonce(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(prefixFixture(31u32, 1u32), 1u64, true), 1)
    @Assert(gate.admit(prefixFixture(31u32, 0u32, nonce: 0u64), 1u64, true), 0)
    @Assert(gate.admit(prefixFixture(27u32, 2u32), 1u64, true), -1)
}

@Test
func activationPrefixCloseAndSlotReuseCannotAuthorizeLateSecond(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(prefixFixture(31u32, 1u32), 1u64, true), 1)
    gate.cancel()
    @Assert(gate.admit(prefixFixture(27u32, 2u32), 1u64, true), -1)
    @Assert(gate.admit(prefixFixture(31u32, 1u32, generation: 8u64), 1u64, true), 1)
}

@Test
func activationPrefixStaleTargetAndAlteredResourceAreRejected(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(prefixFixture(31u32, 1u32), 1u64, false), -1)
    @Assert(gate.pending(), false)
    @Assert(gate.admit(prefixFixture(31u32, 1u32), 1u64, true), 1)
    @Assert(gate.admit(prefixFixture(27u32, 2u32, resource: 103), 1u64, true), -1)
    @Assert(gate.pending(), false)
}

private func physicalPrefixFixture(kind: UInt32, ordinal: UInt32, count: UInt32,
    nonce!: UInt64 = 1u64, generation!: UInt64 = 7u64, node!: UInt64 = 4u64,
    sequence!: UInt64 = 0u64, terminal!: UInt32 = 45u32,
    memberKind!: UInt32 = 0u32): InternalRendererPumpResult {
    var p = InternalRendererActivationPrefix()
    p.sessionGeneration = generation
    p.nonce = nonce
    p.sceneVersion = 1u64
    p.nodeId = node
    p.resourceId = -1
    p.nodeKind = 4u32
    p.bindingEpoch = 1u64
    p.ordinal = ordinal
    p.secondKind = terminal
    p.memberCount = count
    p.memberKind = if (memberKind == 0u32) { kind } else { memberKind }
    return InternalRendererPumpResult(0, kind, 0u32, 0u32, 0u32, node, 1u64, -1, 4u32,
        0, 0, 0.0, 0.0, 0.0, 0.0, false, 0, 0u32, -1, 0, -1, 0,
        0u64, sequence, 0u64, 0u64, 0u64, 0u64, -1, 0u64, 0u64, activationPrefix: p)
}

@Test
func activationPhysicalPrefixKeepsEachMemberAcrossNoneAndYield(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    let terminal = physicalPrefixFixture(45u32, 4u32, 4u32, node: 12u64, sequence: 2u64)
    for (event in [physicalPrefixFixture(44u32, 1u32, 4u32, node: 11u64),
        physicalPrefixFixture(43u32, 2u32, 4u32, node: 12u64),
        physicalPrefixFixture(31u32, 3u32, 4u32, node: 12u64)]) {
        @Assert(gate.admit(event, 1u64, true), 1)
        @Assert(gate.admit(prefixFixture(0u32, 0u32, nonce: 0u64), 1u64, false), 0)
        @Assert(gate.pending(), true)
    }
    @Assert(gate.admit(terminal, 1u64, true), 2)
    gate.settleTerminal(terminal.activationPrefix)
    @Assert(gate.pending(), false)
    @Assert(gate.admit(physicalPrefixFixture(44u32, 1u32, 4u32, node: 11u64), 1u64, true), -1)
}

@Test
func activationPhysicalSingleAndMaximumPrefixHaveRealTerminal(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    let one = physicalPrefixFixture(45u32, 1u32, 1u32, sequence: 1u64)
    @Assert(gate.admit(one, 1u64, true), 2)
    gate.settleTerminal(one.activationPrefix)
    @Assert(gate.pending(), false)
    var ordinal = 1u32
    while (ordinal < 64u32) {
        @Assert(gate.admit(physicalPrefixFixture(43u32, ordinal, 64u32, nonce: 2u64), 1u64, true), 1)
        ordinal += 1u32
    }
    let last = physicalPrefixFixture(45u32, 64u32, 64u32, nonce: 2u64, sequence: 2u64)
    @Assert(gate.admit(last, 1u64, true), 2)
    gate.settleTerminal(last.activationPrefix)
    @Assert(gate.pending(), false)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 65u32, nonce: 3u64), 1u64, true), -1)
}

@Test
func activationPhysicalOldCancelOnlyPermitsOriginalSequenceCleanup(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(physicalPrefixFixture(47u32, 1u32, 2u32, node: 99u64), 1u64, false), -1)
    @Assert(gate.admit(physicalPrefixFixture(47u32, 1u32, 2u32, node: 99u64, sequence: 8u64), 1u64, false), 1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 2u32, 2u32, node: 12u64, sequence: 9u64), 1u64, false), -1)
    @Assert(gate.pending(), false)
}

@Test
func activationPhysicalWrongCountCannotReclaimCancelledPrefix(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32), 1u64, true), 1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 2u32, 2u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 3u32, 3u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 1u32, 1u32, nonce: 2u64), 1u64, true), 2)
}

@Test
func activationPhysicalOutOfOrderReplayAndForeignEventCancel(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32), 1u64, true), 1)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 3u32, 3u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32, nonce: 2u64), 1u64, true), 1)
    @Assert(gate.admit(prefixFixture(31u32, 0u32, nonce: 0u64), 1u64, true), 0)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 3u32, 3u32, nonce: 2u64), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 1u32, 1u32, nonce: 3u64), 1u64, true), 2)
}

@Test
func activationPhysicalMemberKindTerminalAndBindingMustRemainExact(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32, memberKind: 44u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 3u32), 1u64, true), 1)
    @Assert(gate.admit(physicalPrefixFixture(31u32, 2u32, 3u32, terminal: 27u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 3u32, 3u32), 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 2u32, nonce: 2u64), 1u64, true), 1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 2u32, 2u32, nonce: 2u64), 2u64, true), -1)
    @Assert(gate.pending(), false)
}

@Test
func activationPhysicalLateOldTerminalCannotLowerGenerationWatermark(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 2u32), 1u64, true), 1)
    gate.cancel()
    let fresh = physicalPrefixFixture(45u32, 1u32, 1u32, generation: 8u64)
    @Assert(gate.admit(fresh, 1u64, true), 2)
    gate.settleTerminal(fresh.activationPrefix)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 2u32, 2u32), 1u64, true), -1)
    @Assert(gate.admit(fresh, 1u64, true), -1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 1u32, 1u32, nonce: 5u64), 1u64, true), -1)
}

@Test
func activationPhysicalClosedGenerationsDoNotExhaustNewSessionOrRevokeItsPrefix(): Unit {
    let gate = CjguiMacActivationPrefixGate()
    var generation = 7u64
    while (generation < 107u64) {
        @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 2u32, generation: generation), 1u64, true), 1)
        gate.cancel()
        generation += 1u64
    }
    @Assert(gate.admit(physicalPrefixFixture(43u32, 1u32, 2u32, generation: generation), 1u64, true), 1)
    @Assert(gate.admit(physicalPrefixFixture(45u32, 2u32, 2u32, generation: 7u64), 1u64, true), -1)
    @Assert(gate.pending(), true)
    let last = physicalPrefixFixture(45u32, 2u32, 2u32, generation: generation)
    @Assert(gate.admit(last, 1u64, true), 2)
    gate.settleTerminal(last.activationPrefix)
    @Assert(gate.pending(), false)
}
