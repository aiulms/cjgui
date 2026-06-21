package cjgui_shared_demo_harness_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoComponentActionRoute}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoEvidencePresenter, CjguiExperimentalDemoEvidenceSectionBuilder}
import cjgui.demo_support.{CjguiExperimentalDemoServedDemoEvidence}
import cjgui.demo_support.{CjguiExperimentalDemoComponentInteractionEvidence, CjguiExperimentalDemoStateReadbackEvidence}
import std.collection.*

// 中文维护注释：这是独立 shared demo harness demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能立即服务一个 Todo 业务流，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedDemoHarnessState {
    let harnessName: String
    let servedDemo: String
    private var actions = ArrayList<String>()
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    var itemCount: Int64
    var firstTitle: String
    var firstDone: Bool

    init() {
        this.harnessName = "shared_demo_harness"
        this.servedDemo = "todo"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "shared_demo_harness",
            "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list",
            "todo_list",
            "neutral_list",
            "",
            "todo_input"
        )
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "shared_demo_harness",
            "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("shared_demo_harness")
        this.itemCount = 0
        this.firstTitle = "<none>"
        this.firstDone = false
    }

    func addTodo(title: String) {
        actions.add("add_todo")
        itemCount = 1
        firstTitle = title
        firstDone = false
        componentSession.typeInput(title)
        componentSession.moveFocus("todo_first_item")
        componentSession.applyStyle("active_list")
        componentSession.recordComponentActionRoute(
            CjguiExperimentalDemoComponentActionRoute("todo_input", "shared_demo_harness.add_todo"),
            businessState()
        )
    }

    func completeTodo() {
        actions.add("complete_todo")
        firstDone = true
        componentSession.moveFocus("todo_first_item")
        componentSession.applyStyle("completed_accent")
        componentSession.recordComponentActionRoute(
            CjguiExperimentalDemoComponentActionRoute("todo_item", "shared_demo_harness.complete_todo"),
            businessState()
        )
    }

    func actionCount(): Int64 {
        return actions.size
    }

    func businessState(): String {
        return "items=${itemCount};first=${firstTitle};first_done=${firstDone};focus=${componentSession.focus()};style=${componentSession.style()}"
    }

    func domainSummary(): String {
        return "harness=${harnessName};served=${servedDemo};actions=${actions.size};focus=${componentSession.focus()};style=${componentSession.style()}"
    }

    func sharedUiState(): String {
        return componentSession.uiStateSummary()
    }

    func sharedComponentActions(): String {
        return componentSession.componentActions()
    }

    func sharedActions(): String {
        return componentSession.actions()
    }

    func sharedWrites(): Int64 {
        return componentSession.writes()
    }

    func sharedBefore(): String {
        return componentSession.before()
    }

    func sharedAfter(): String {
        return componentSession.after()
    }

    func buildSharedOutput(domainSummary: String, readbackOk: Bool): CjguiExperimentalDemoOutput {
        return componentSession.buildOutput(domainSummary, readbackOk)
    }


}

main(): Int64 {
    let harness = SharedDemoHarnessState()
    let before = harness.businessState()
    harness.addTodo("Write shared CJGUI harness")
    harness.completeTodo()
    let after = harness.businessState()
    let stateReadbackOk = before == "items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list" &&
        after == "items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent" &&
        harness.sharedUiState() == "layout=todo_list;style=completed_accent;input=Write shared CJGUI harness;focus=todo_first_item" &&
        harness.actionCount() == 2 &&
        harness.sharedBefore() == before &&
        harness.sharedAfter() == after &&
        harness.sharedActions() == "shared_demo_harness.add_todo,shared_demo_harness.complete_todo" &&
        harness.sharedWrites() == 2 &&
        harness.sharedComponentActions() == "todo_input:shared_demo_harness.add_todo,todo_item:shared_demo_harness.complete_todo"
    let apiOutput = harness.buildSharedOutput(harness.domainSummary(), stateReadbackOk)
    let commitResult = harness.commitHarness.commitComponentAction(
        "todo_item",
        "shared_demo_harness.commit_todo_flow",
        after
    )
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "shared_demo_harness" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "shared_demo_harness.add_todo,shared_demo_harness.complete_todo" &&
        apiOutput.writeCount == 2 &&
        apiOutput.domainSummary == harness.domainSummary() &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=shared_demo_harness;readback=true;writes=2;actions=shared_demo_harness.add_todo,shared_demo_harness.complete_todo;before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list;after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent;summary=harness=shared_demo_harness;served=todo;actions=2;focus=todo_first_item;style=completed_accent" &&
        harness.commitHarness.resultMatches(
            commitResult,
            "todo_item",
            "shared_demo_harness.commit_todo_flow",
            before,
            after
        )
    let runResult = harness.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        harness.componentSession,
        commitResult,
        commitReadbackOk
    )
    let evidencePresenter = CjguiExperimentalDemoEvidencePresenter("cjgui shared demo harness app")
    let outputOk = commitReadbackOk && runResult.runnable
    let evidenceBuilder = CjguiExperimentalDemoEvidenceSectionBuilder("shared_demo_harness", "not_started", "runnable")
    evidenceBuilder.addServedDemoEvidence(CjguiExperimentalDemoServedDemoEvidence("todo"))
    evidenceBuilder.addInteractionEvidence(CjguiExperimentalDemoComponentInteractionEvidence("run_todo_add_complete"))
    evidenceBuilder.addStateReadbackEvidence(CjguiExperimentalDemoStateReadbackEvidence(before, after, outputOk))

    let evidenceSection = evidenceBuilder.buildSection(
        apiOutput,
        harness.componentSession,
        commitResult,
        harness.commitHarness,
        runResult
    )
    evidencePresenter.printEvidenceSection(evidenceSection)

    if (outputOk) {
        return 0
    }
    return 1
}
