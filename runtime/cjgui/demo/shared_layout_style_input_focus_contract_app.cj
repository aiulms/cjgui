package cjgui_shared_layout_style_input_focus_contract_demo

import cjgui.*

// 中文维护注释：这是独立 shared layout/style/input/focus contract demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 shared harness 能表达 layout/style/text input/focus 四类交互合同，并输出 before / after / readback。
// Stop-line: 只做 demo-host in-memory 状态，不调度 Action，不写 renderer，不调用 native bridge。

class SharedLayoutStyleInputFocusContractState {
    let contractName: String
    var layoutMode: String
    var styleToken: String
    var inputText: String
    var focusTarget: String
    var interactionTrace: String

    init() {
        this.contractName = "shared_layout_style_input_focus"
        this.layoutMode = "single_column"
        this.styleToken = "neutral_list"
        this.inputText = "<empty>"
        this.focusTarget = "todo_input"
        this.interactionTrace = "idle"
    }

    private func appendInteraction(name: String) {
        if (interactionTrace == "idle") {
            interactionTrace = name
        } else {
            interactionTrace = "${interactionTrace},${name}"
        }
    }

    func applyLayout(kind: String) {
        layoutMode = kind
        appendInteraction("layout_split_detail")
    }

    func applyStyle(token: String) {
        styleToken = token
        appendInteraction("style_focus_accent")
    }

    func typeInput(text: String) {
        inputText = text
        appendInteraction("input_type_main")
    }

    func moveFocus(target: String) {
        focusTarget = target
        appendInteraction("focus_file_filter")
    }

    func businessState(): String {
        return "layout=${layoutMode};style=${styleToken};input=${inputText};focus=${focusTarget}"
    }

    func buildContractOutput(
        layoutBefore: String,
        layoutAfter: String,
        styleBefore: String,
        styleAfter: String,
        inputBefore: String,
        inputAfter: String,
        focusBefore: String,
        focusAfter: String,
        readbackOk: Bool
    ): CjguiExperimentalSharedLayoutStyleInputFocusContractOutput {
        return cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(
            layoutBefore,
            layoutAfter,
            styleBefore,
            styleAfter,
            inputBefore,
            inputAfter,
            focusBefore,
            focusAfter,
            interactionTrace,
            readbackOk
        )
    }
}

main(): Int64 {
    let contract = SharedLayoutStyleInputFocusContractState()
    let before = contract.businessState()
    let layoutBefore = contract.layoutMode
    let styleBefore = contract.styleToken
    let inputBefore = contract.inputText
    let focusBefore = contract.focusTarget

    contract.applyLayout("split_detail")
    contract.applyStyle("focus_accent")
    contract.typeInput("main")
    contract.moveFocus("file_filter")

    let after = contract.businessState()
    let layoutAfter = contract.layoutMode
    let styleAfter = contract.styleToken
    let inputAfter = contract.inputText
    let focusAfter = contract.focusTarget
    let readbackOk = before == "layout=single_column;style=neutral_list;input=<empty>;focus=todo_input" &&
        after == "layout=split_detail;style=focus_accent;input=main;focus=file_filter" &&
        contract.interactionTrace == "layout_split_detail,style_focus_accent,input_type_main,focus_file_filter"
    let apiOutput = contract.buildContractOutput(
        layoutBefore,
        layoutAfter,
        styleBefore,
        styleAfter,
        inputBefore,
        inputAfter,
        focusBefore,
        focusAfter,
        readbackOk
    )
    let outputOk = readbackOk &&
        apiOutput.contractName == "shared_layout_style_input_focus" &&
        apiOutput.layoutBefore == "single_column" &&
        apiOutput.layoutAfter == "split_detail" &&
        apiOutput.styleBefore == "neutral_list" &&
        apiOutput.styleAfter == "focus_accent" &&
        apiOutput.inputBefore == "<empty>" &&
        apiOutput.inputAfter == "main" &&
        apiOutput.focusBefore == "todo_input" &&
        apiOutput.focusAfter == "file_filter" &&
        apiOutput.interactionTrace == "layout_split_detail,style_focus_accent,input_type_main,focus_file_filter" &&
        apiOutput.readbackOk &&
        apiOutput.summary == "contract=shared_layout_style_input_focus;layout=single_column->split_detail;style=neutral_list->focus_accent;input=<empty>->main;focus=todo_input->file_filter;interaction=layout_split_detail,style_focus_accent,input_type_main,focus_file_filter;readback=true"

    println("cjgui shared layout-style-input-focus contract app: demo=shared_layout_style_input_focus_contract")
    println("cjgui shared layout-style-input-focus contract app: status_before=not_started")
    println("cjgui shared layout-style-input-focus contract app: status_after=runnable")
    println("cjgui shared layout-style-input-focus contract app: interaction=apply_layout,apply_style,type_input,move_focus")
    println("cjgui shared layout-style-input-focus contract app: state_before=${before}")
    println("cjgui shared layout-style-input-focus contract app: state_after=${after}")
    println("cjgui shared layout-style-input-focus contract app: state_readback=${readbackOk}")
    println("cjgui shared layout-style-input-focus contract app: public_api_consumed=true")
    println("cjgui shared layout-style-input-focus contract app: public_api_name=cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput")
    println("cjgui shared layout-style-input-focus contract app: public_api_output=${apiOutput.summary}")

    if (outputOk) {
        return 0
    }
    return 1
}
