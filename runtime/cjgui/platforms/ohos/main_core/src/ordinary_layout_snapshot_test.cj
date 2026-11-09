package cjgui

import std.collection.*
import std.convert.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class OrdinaryLayoutRows <: CjguiComposableUiVariableHeightListSource {
    var rowBuilds: Int64 = 0
    var itemReads: Int64 = 0
    var generation: Int64 = 1
    var lastDeclaredRow: ?CjguiComposableUiNode = None
    let scope = CjguiComposableUiIdentityScope("ordinary-rows")
    var body: String
    init() {
        var value = "OLD "
        for (_ in 0..256) { value += "中文 plain 👩🏽‍💻 " }
        body = value
    }
    public func itemCount(): Int64 { return 1000 }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        itemReads += 1
        return CjguiComposableUiVariableHeightListItem("row_${index}",index+1,"row ${index}",generation,estimatedHeight:76)
    }
    public func indexForKey(key: String): Int64 {
        let parts=key.split("_")
        return if (parts.size==2) { Int64.parse(parts[1]) } else { -1 }
    }
    public func measurementGeneration(): Int64 { return generation }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem,isSelected: Bool,isFocused: Bool): CjguiComposableUiNode {
        rowBuilds += 1
        let row=CjguiComposableUiNode(-1,"row-${item.resourceId}",CJGUI_COMPOSABLE_UI_VERTICAL,"","","",-1,
            CjguiComposableUiStyle(minHeight:76),identity:Some(scope.local(item.key)))
        lastDeclaredRow=Some(row)
        row.add(cjguiComposableText(986100+item.resourceId,"body-${item.resourceId}",body,CjguiComposableUiStyle()))
        return row
    }
}

private class OrdinaryLayoutController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let rows=OrdinaryLayoutRows()
    let state=CjguiComposableUiVirtualListState()
    var revision: Int64=1
    var candidateVersion: Int64=0
    var builds: Int64=0
    let commits=ArrayList<Int64>()
    public func uiSceneVersion(): Int64 { return revision }
    public func beginSceneRefresh(): Bool { candidateVersion=revision;return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList<CjguiComposableUiCommand>() }
    public func commitSceneRefresh(): Unit { commits.add(candidateVersion) }
    public func rollbackSceneRefresh(): Unit {}
    public func buildUi(): CjguiComposableUiNode {
        if (revision==1) { return cjguiComposableText(98500,"initial","initial",CjguiComposableUiStyle()) }
        builds += 1
        let gradient=CjguiComposableUiLinearGradient(stops:[
            CjguiComposableUiGradientStop(position:0.0,color:CjguiComposableUiColor(0.1,0.2,0.3,1.0)),
            CjguiComposableUiGradientStop(position:1.0,color:CjguiComposableUiColor(0.3,0.2,0.1,1.0))])
        let root=cjguiComposableVertical(98501,"dynamic-root",CjguiComposableUiStyle(gradient:Some(gradient)))
        root.add(cjguiComposableVariableHeightList(98502,"dynamic-list",98503,rows,state,76,4,2,
            CjguiComposableUiStyle(fixedWidth:450,fixedHeight:300)))
        return root
    }
    public func applyUiEvent(event:CjguiComposableUiEvent):CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind:Int64,node:Int64):CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose():CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true,shouldClose:true) }
}

@When[os=="macOS"]
@Test
func ordinaryDynamicLayoutFreezesCallbacksAndCancelsStalePreparation(): Unit {
    cjguiMacosOwnerTest({ => ordinaryDynamicLayoutFreezesCallbacksAndCancelsStalePreparationBody() })
}

private func ordinaryDynamicLayoutFreezesCallbacksAndCancelsStalePreparationBody(): Unit {
    let controller=OrdinaryLayoutController()
    let app=CjguiMacosApplication()
    let opened=app.openWindow(controller,configuration:
        CjguiMacosApplicationWindowConfiguration("ordinary dynamic preparation",600u32,420u32))
    @Assert(opened.didOpen,true)
    let window=app.window(opened.identifier.getOrThrow()).getOrThrow()
    try {
        for (_ in 0..240) { if (controller.commits.contains(1)) { break };let _=app.pumpOneTurn() }
        @Assert(controller.commits.contains(1),true)
        let caller=CjguiOwnerTurnBudget()
        window.useOwnerTurnBudget(caller)
        controller.revision=2;window.requestRefresh()
        for (_ in 0..48) {
            @Assert(caller.begin(),true)
            try { let _=app.pumpOneTurn() } finally { caller.end() }
            if (controller.builds>0) { break }
        }
        println("ORDINARY_DYNAMIC preparing=${window.testStaticLayoutPreparing()} workers=${window.testStaticLayoutWorkerStartCount()} rows=${controller.rows.rowBuilds}")
        @Assert(window.testStaticLayoutPreparing(),true)
        // The source keeps its own declaration for ordinary action bindings;
        // scoped ID resolution must reach that original before snapshotting.
        println("ORDINARY_FROZEN_ID declared=${controller.rows.lastDeclaredRow.getOrThrow().nodeId}")
        @Assert(controller.rows.lastDeclaredRow.getOrThrow().nodeId>0,true)
        @Assert(controller.state.materializedEnd(),0)
        // Invalidate before a legal second owner turn could finish version2.
        // Callback replay is checked on the replacement candidate below.
        // A new owner declaration cancels the old immutable preparation.
        controller.revision=3;controller.rows.generation+=1
        controller.rows.body="NEW "+controller.rows.body
        window.requestRefresh()
        for (_ in 0..48) { let _=app.pumpOneTurn();if (controller.builds==2) { break } }
        let builtRows=controller.rows.rowBuilds
        let itemReads=controller.rows.itemReads
        for (_ in 0..3) { let _=app.pumpOneTurn() }
        @Assert(controller.rows.rowBuilds,builtRows)
        @Assert(controller.rows.itemReads,itemReads)
        let completionStarted=MonoTime.now()
        var completionTurns: Int64=0
        while (!controller.commits.contains(3) && (MonoTime.now()-completionStarted).toNanoseconds()<2000000000) {
            let _=app.pumpUntilWork(timeoutMs:16u32)
            completionTurns+=1
        }
        println("ORDINARY_LAYOUT_COMPLETION turns=${completionTurns} wall_ns=${(MonoTime.now()-completionStarted).toNanoseconds()} accepted=${controller.commits.contains(3)}")
        @Assert(controller.commits.contains(2),false)
        @Assert(controller.commits.contains(3),true)
        @Assert(controller.state.materializedEnd()>0,true)
        @Assert(window.testStaticLayoutWorkerStartCount()>0,true)
        @Assert(controller.builds,2)
    } finally { app.close() }
}
