package cjgui_shared_layout_style_input_focus_contract_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}

// 中文维护注释：这是独立 shared layout/style/input/focus contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能表达 layout/style/text input/focus 四类交互合同，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedLayoutStyleInputFocusContractState {
    let contractName: String
    var layoutMode: String
    var styleToken: String
    var inputText: String
    var focusTarget: String

    init() {
        this.contractName = "shared_layout_style_input_focus"
        this.layoutMode = "single_column"
        this.styleToken = "neutral_list"
        this.inputText = "<empty>"
        this.focusTarget = "todo_input"
    }

    func applyLayout(kind: String) {
        layoutMode = kind
    }

    func applyStyle(token: String) {
        styleToken = token
    }

    func typeInput(text: String) {
        inputText = text
    }

    func moveFocus(target: String) {
        focusTarget = target
    }

    func businessState(): String {
        return "layout=${layoutMode};style=${styleToken};input=${inputText};focus=${focusTarget}"
    }

    func domainSummary(layoutBefore: String, styleBefore: String, inputBefore: String, focusBefore: String): String {
        return "contract=${contractName};layout=${layoutBefore}->${layoutMode};style=${styleBefore}->${styleToken};input=${inputBefore}->${inputText};focus=${focusBefore}->${focusTarget}"
    }
}

main(): Int64 {
    let contract = SharedLayoutStyleInputFocusContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layoutMode
    let styleBefore = contract.styleToken
    let inputBefore = contract.inputText
    let focusBefore = contract.focusTarget
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("shared_layout_style_input_focus_contract", before)

    contract.applyLayout("split_detail")
    sharedTrace.recordAction("shared_layout_style_input_focus.apply_layout", contract.businessState())
    contract.applyStyle("focus_accent")
    sharedTrace.recordAction("shared_layout_style_input_focus.apply_style", contract.businessState())
    contract.typeInput("main")
    sharedTrace.recordAction("shared_layout_style_input_focus.type_input", contract.businessState())
    contract.moveFocus("file_filter")

    let after = contract.businessState()
    sharedTrace.recordAction("shared_layout_style_input_focus.move_focus", after)
    let layoutAfter = contract.layoutMode
    let styleAfter = contract.styleToken
    let inputAfter = contract.inputText
    let focusAfter = contract.focusTarget
    let stateReadbackOk = before == "layout=single_column;style=neutral_list;input=<empty>;focus=todo_input" &&
        after == "layout=split_detail;style=focus_accent;input=main;focus=file_filter" &&
        layoutAfter == "split_detail" &&
        styleAfter == "focus_accent" &&
        inputAfter == "main" &&
        focusAfter == "file_filter" &&
        sharedTrace.before() == before &&
        sharedTrace.after() == after &&
        sharedTrace.actions() == "shared_layout_style_input_focus.apply_layout,shared_layout_style_input_focus.apply_style,shared_layout_style_input_focus.type_input,shared_layout_style_input_focus.move_focus" &&
        sharedTrace.writes() == 4
    let domainSummary = contract.domainSummary(layoutBefore, styleBefore, inputBefore, focusBefore)
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, domainSummary, stateReadbackOk)
    let outputOk = stateReadbackOk &&
        apiOutput.demoName == "shared_layout_style_input_focus_contract" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "shared_layout_style_input_focus.apply_layout,shared_layout_style_input_focus.apply_style,shared_layout_style_input_focus.type_input,shared_layout_style_input_focus.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == domainSummary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=shared_layout_style_input_focus_contract;readback=true;writes=4;actions=shared_layout_style_input_focus.apply_layout,shared_layout_style_input_focus.apply_style,shared_layout_style_input_focus.type_input,shared_layout_style_input_focus.move_focus;before=layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=layout=split_detail;style=focus_accent;input=main;focus=file_filter;summary=contract=shared_layout_style_input_focus;layout=single_column->split_detail;style=neutral_list->focus_accent;input=<empty>->main;focus=todo_input->file_filter"

    println("cjgui shared layout-style-input-focus contract app: demo=shared_layout_style_input_focus_contract")
    println("cjgui shared layout-style-input-focus contract app: status_before=not_started")
    println("cjgui shared layout-style-input-focus contract app: status_after=runnable")
    println("cjgui shared layout-style-input-focus contract app: interaction=apply_layout,apply_style,type_input,move_focus")
    println("cjgui shared layout-style-input-focus contract app: state_before=${before}")
    println("cjgui shared layout-style-input-focus contract app: state_after=${after}")
    println("cjgui shared layout-style-input-focus contract app: state_readback=${outputOk}")
    println("cjgui shared layout-style-input-focus contract app: public_api_consumed=true")
    println("cjgui shared layout-style-input-focus contract app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui shared layout-style-input-focus contract app: public_api_output=${apiOutput.summary}")
    println("cjgui shared layout-style-input-focus contract app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui shared layout-style-input-focus contract app: shared_support_output=${sharedTrace.summary()}")

    if (outputOk) {
        return 0
    }
    return 1
}
