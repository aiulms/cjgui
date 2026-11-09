package cjgui
import std.unittest.*
import std.unittest.testmacro.*

private func restoreContractChoice(revision!: Int64 = 10, document!: String = "restore-owner",
    epoch!: Int64 = 121, view!: Int64 = 1, version!: Int64 = 4,
    a!: Int64 = 0, b!: Int64 = 0): CjguiSourceSelectionSnapshot {
    return CjguiSourceSelectionSnapshot(version,revision,a,b,documentId:document,sessionEpoch:epoch,viewGeneration:view)
}
private func restoreContractRequest(mapped!: Bool = false, foreground!: Bool = false,
    paint!: Bool = false, choice!: ?CjguiSourceSelectionSnapshot = Some(restoreContractChoice())): CjguiPendingSelectionRestore {
    return CjguiPendingSelectionRestore(3,5u64,CjguiTextSelectionTicket(1,4,4,4,10),107,1,10,
        "",0,0,0,0,mapped,{=>},sourceCoordinatesAreBytes:mapped,proxyOnlyPaint:paint,
        frozenSourceChoice:choice,foregroundOnly:foreground,caretInputSequence:4u64)
}
private func restoreContractDecision(request: CjguiPendingSelectionRestore,
    binding!: UInt64 = 5u64, semantic!: Bool = true,
    choice!: ?CjguiSourceSelectionSnapshot = Some(restoreContractChoice()),
    node!: Int64 = 107, resource!: Int64 = 1, kind!: Int64 = 10, value!: String = "",
    a!: Int64 = 0,b!: Int64 = 0,sourceA!: Int64 = 0,sourceB!: Int64 = 0,
    samePurpose!: Bool = true): String {
    return request.reassertionRefusal(binding,semantic,choice,node,resource,kind,value,a,b,sourceA,sourceB,samePurpose)
}
@Test
func sameRestoreOrdinaryIdentityIsReusedWithoutReplacingPending(): Unit {
    let original=restoreContractRequest()
    @Assert(restoreContractDecision(original),"")
    @Assert(original.id,3);@Assert(original.caretInputSequence,4u64)
    @Assert(original.frozenSourceChoice.getOrThrow().revision,10)
}
@Test
func sameRestoreNewChoiceAndEachOwnerDomainRefuseReuse(): Unit {
    let original=restoreContractRequest()
    @Assert(restoreContractDecision(original,choice:Some(restoreContractChoice(revision:11))).size>0,true)
    @Assert(restoreContractDecision(original,choice:Some(restoreContractChoice(document:"another"))).size>0,true)
    @Assert(restoreContractDecision(original,choice:Some(restoreContractChoice(epoch:122))).size>0,true)
    @Assert(restoreContractDecision(original,choice:Some(restoreContractChoice(view:2))).size>0,true)
    @Assert(restoreContractDecision(original,choice:Some(restoreContractChoice(version:5))).size>0,true)
    @Assert(restoreContractDecision(original,choice:None).size>0,true)
    @Assert(restoreContractDecision(original,binding:6u64).size>0,true)
    @Assert(restoreContractDecision(original,semantic:false).size>0,true)
}
@Test
func sameRestoreTargetBodyRangeAndPurposeRefuseReuse(): Unit {
    let original=restoreContractRequest()
    @Assert(restoreContractDecision(original,node:108).size>0,true)
    @Assert(restoreContractDecision(original,resource:2).size>0,true)
    @Assert(restoreContractDecision(original,kind:3).size>0,true)
    @Assert(restoreContractDecision(original,value:"X").size>0,true)
    @Assert(restoreContractDecision(original,a:1).size>0,true)
    @Assert(restoreContractDecision(original,b:1).size>0,true)
    @Assert(restoreContractDecision(original,sourceA:1).size>0,true)
    @Assert(restoreContractDecision(original,sourceB:1).size>0,true)
    @Assert(restoreContractDecision(original,samePurpose:false).size>0,true)
    @Assert(restoreContractDecision(restoreContractRequest(foreground:true)).size>0,true)
    @Assert(restoreContractDecision(restoreContractRequest(paint:true)).size>0,true)
}
@Test
func sameRestoreMappedCallbackAndMorePreciseProxyAreRetained(): Unit {
    let original=restoreContractRequest(mapped:true)
    @Assert(restoreContractDecision(original,a:1,b:1),"")
    @Assert(original.commitSourceSelection,true);@Assert(original.sourceCoordinatesAreBytes,true)
    @Assert(original.anchor16,0);@Assert(original.focus16,0)
    @Assert(restoreContractDecision(original,choice:Some(restoreContractChoice(revision:11))).size>0,true)
}
@Test
func sameRestorePlainSessionWithoutSourceOwnerRequiresBothAbsent(): Unit {
    let original=restoreContractRequest(choice:None)
    @Assert(restoreContractDecision(original,choice:None),"")
    @Assert(restoreContractDecision(original).size>0,true)
}
