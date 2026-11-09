// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental UI state core。
// Scope: 为多个独立 demo 提供同一组 layout/style/text-input/focus owner-local 状态与动作 helper。
// Stop-line: 只保存 demo process-local in-memory 状态，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui.demo_support

public class CjguiExperimentalDemoUiStateCore {
    private var layoutMode: String
    private var styleToken: String
    private var inputText: String
    private var focusTarget: String

    public init(layoutMode: String, styleToken: String, inputText: String, focusTarget: String) {
        this.layoutMode = layoutMode
        this.styleToken = styleToken
        this.inputText = inputText
        this.focusTarget = focusTarget
    }

    public func applyLayout(mode: String) {
        layoutMode = mode
    }

    public func applyStyle(token: String) {
        styleToken = token
    }

    public func typeInput(text: String) {
        inputText = text
    }

    public func moveFocus(target: String) {
        focusTarget = target
    }

    public func layout(): String {
        return layoutMode
    }

    public func style(): String {
        return styleToken
    }

    public func textInput(): String {
        return inputText
    }

    public func focus(): String {
        return focusTarget
    }

    public func summary(): String {
        return "layout=${layoutMode};style=${styleToken};input=${inputText};focus=${focusTarget}"
    }
}
