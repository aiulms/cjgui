package cjgui_chat_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder, CjguiExperimentalDemoUiStateCore}
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
    let uiState: CjguiExperimentalDemoUiStateCore
    private var messages = ArrayList<ChatMessage>()
    var lastSender: String
    var lastText: String

    init() {
        this.demoName = "chat"
        this.uiState = CjguiExperimentalDemoUiStateCore("threaded_chat", "chat_thread", "", "composer")
        this.lastSender = "assistant"
        this.lastText = "Welcome to CJGUI"
        messages.add(ChatMessage(lastSender, lastText))
    }

    func updateComposer(text: String) {
        uiState.typeInput(text)
        uiState.moveFocus("composer")
    }

    func appendMessage(sender: String, text: String) {
        messages.add(ChatMessage(sender, text))
        lastSender = sender
        lastText = text
        if (sender == "assistant") {
            uiState.applyStyle("assistant_reply")
        } else {
            uiState.applyStyle("owner_message")
        }
    }

    func sendComposer(sender: String): Bool {
        if (uiState.textInput() == "") {
            return false
        }
        appendMessage(sender, uiState.textInput())
        uiState.typeInput("")
        return true
    }

    func moveFocus(target: String) {
        uiState.moveFocus(target)
    }

    func messageCount(): Int64 {
        return messages.size
    }

    func businessState(): String {
        return "messages=${messages.size};last=${lastSender}:${lastText};composer=${uiState.textInput()};focus=${uiState.focus()}"
    }

    func summary(): String {
        return "demo=${demoName};layout=${uiState.layout()};${businessState()}"
    }

    func sharedUiState(): String {
        return uiState.summary()
    }
}

main(): Int64 {
    let thread = ChatThreadState()
    let before = thread.businessState()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("chat", before)
    thread.updateComposer("Ship Chat demo")
    sharedTrace.recordAction("chat.type_message", thread.businessState())
    let sent = thread.sendComposer("owner")
    sharedTrace.recordAction("chat.send_message", thread.businessState())
    thread.appendMessage("assistant", "Chat demo received")
    sharedTrace.recordAction("chat.append_reply", thread.businessState())
    thread.moveFocus("message_list")
    let after = thread.businessState()
    sharedTrace.recordAction("chat.move_focus", after)
    let summary = thread.summary()
    let stateReadbackOk = before == "messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer" &&
        after == "messages=3;last=assistant:Chat demo received;composer=;focus=message_list" &&
        sharedTrace.before() == before &&
        sharedTrace.after() == after &&
        sharedTrace.actions() == "chat.type_message,chat.send_message,chat.append_reply,chat.move_focus" &&
        sharedTrace.writes() == 4 &&
        thread.sharedUiState() == "layout=threaded_chat;style=assistant_reply;input=;focus=message_list" &&
        sent &&
        thread.messageCount() == 3 &&
        summary == "demo=chat;layout=threaded_chat;messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, summary, stateReadbackOk)
    let readbackOk = stateReadbackOk &&
        apiOutput.demoName == "chat" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "chat.type_message,chat.send_message,chat.append_reply,chat.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == summary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=chat;readback=true;writes=4;actions=chat.type_message,chat.send_message,chat.append_reply,chat.move_focus;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;summary=demo=chat;layout=threaded_chat;messages=3;last=assistant:Chat demo received;composer=;focus=message_list"

    println("cjgui chat demo app: demo=chat")
    println("cjgui chat demo app: status_before=not_started")
    println("cjgui chat demo app: status_after=runnable")
    println("cjgui chat demo app: layout=threaded_chat")
    println("cjgui chat demo app: interaction=type_message,send_message,append_reply,move_focus")
    println("cjgui chat demo app: state_before=${before}")
    println("cjgui chat demo app: state_after=${after}")
    println("cjgui chat demo app: state_readback=${readbackOk}")
    println("cjgui chat demo app: public_api_consumed=true")
    println("cjgui chat demo app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui chat demo app: public_api_output=${apiOutput.summary}")
    println("cjgui chat demo app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui chat demo app: shared_support_output=${sharedTrace.summary()}")
    println("cjgui chat demo app: shared_state_core=${thread.sharedUiState()}")

    if (readbackOk) {
        return 0
    }
    return 1
}
