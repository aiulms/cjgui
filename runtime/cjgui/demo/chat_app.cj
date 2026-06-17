package cjgui_chat_demo

import cjgui.*
import std.collection.*

// 中文维护注释：这是独立 Chat demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 Chat 消费 CJGUI experimental 非 Bool public API，并执行 owner-local 消息/输入/焦点写入读回。
// Stop-line: 只做 demo-host in-memory 状态，不调用 native bridge，不提交 renderer。

class ChatMessage {
    let sender: String
    let text: String

    init(sender: String, text: String) {
        this.sender = sender
        this.text = text
    }
}

class ChatThreadState {
    let demoName: String
    let layoutKind: String
    private var messages = ArrayList<ChatMessage>()
    var composerText: String
    var focusTarget: String
    var lastSender: String
    var lastText: String

    init() {
        this.demoName = "chat"
        this.layoutKind = "threaded_chat"
        this.composerText = ""
        this.focusTarget = "composer"
        this.lastSender = "assistant"
        this.lastText = "Welcome to CJGUI"
        messages.add(ChatMessage(lastSender, lastText))
    }

    func updateComposer(text: String) {
        composerText = text
        focusTarget = "composer"
    }

    func appendMessage(sender: String, text: String) {
        messages.add(ChatMessage(sender, text))
        lastSender = sender
        lastText = text
    }

    func sendComposer(sender: String): Bool {
        if (composerText == "") {
            return false
        }
        appendMessage(sender, composerText)
        composerText = ""
        return true
    }

    func moveFocus(target: String) {
        focusTarget = target
    }

    func messageCount(): Int64 {
        return messages.size
    }

    func businessState(): String {
        return "messages=${messages.size};last=${lastSender}:${lastText};composer=${composerText};focus=${focusTarget}"
    }

    func buildApiOutput(): CjguiExperimentalChatDemoOutput {
        return cjguiExperimentalBuildChatDemoOutput(
            messages.size,
            lastSender,
            lastText,
            composerText,
            focusTarget,
            layoutKind
        )
    }
}

main(): Int64 {
    let thread = ChatThreadState()
    let before = thread.businessState()
    thread.updateComposer("Ship Chat demo")
    let sent = thread.sendComposer("owner")
    thread.appendMessage("assistant", "Chat demo received")
    thread.moveFocus("message_list")
    let after = thread.businessState()
    let apiOutput = thread.buildApiOutput()
    let readbackOk = before == "messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer" &&
        after == "messages=3;last=assistant:Chat demo received;composer=;focus=message_list" &&
        sent &&
        thread.messageCount() == 3 &&
        apiOutput.demoName == "chat" &&
        apiOutput.messageCount == 3 &&
        apiOutput.lastSender == "assistant" &&
        apiOutput.lastText == "Chat demo received" &&
        apiOutput.composerText == "" &&
        apiOutput.focusTarget == "message_list" &&
        apiOutput.layoutKind == "threaded_chat" &&
        apiOutput.summary == "messages=3;last=assistant:Chat demo received;composer=;focus=message_list;layout=threaded_chat"

    println("cjgui chat demo app: demo=chat")
    println("cjgui chat demo app: status_before=not_started")
    println("cjgui chat demo app: status_after=runnable")
    println("cjgui chat demo app: layout=threaded_chat")
    println("cjgui chat demo app: interaction=type_message,send_message,append_reply,move_focus")
    println("cjgui chat demo app: state_before=${before}")
    println("cjgui chat demo app: state_after=${after}")
    println("cjgui chat demo app: state_readback=${readbackOk}")
    println("cjgui chat demo app: public_api_consumed=true")
    println("cjgui chat demo app: public_api_name=cjguiExperimentalBuildChatDemoOutput")
    println("cjgui chat demo app: public_api_output=${apiOutput.summary}")

    if (readbackOk) {
        return 0
    }
    return 1
}
