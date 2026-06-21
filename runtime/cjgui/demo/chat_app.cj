package cjgui_chat_demo

import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}
import cjgui.demo_support.{CjguiExperimentalDemoComponentActionRouteCatalog}
import cjgui.demo_support.{CjguiExperimentalDemoCommitActionRouteCatalog}
import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}
import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}
import cjgui.demo_support.{CjguiExperimentalDemoEvidencePresenter, CjguiExperimentalDemoEvidenceSectionBuilder}
import cjgui.demo_support.{CjguiExperimentalDemoLayoutEvidence}
import cjgui.demo_support.{CjguiExperimentalDemoComponentInteractionEvidence, CjguiExperimentalDemoStateReadbackEvidence}
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
    let componentSession: CjguiExperimentalDemoComponentActionSession
    let routeCatalog: CjguiExperimentalDemoComponentActionRouteCatalog
    let commitRouteCatalog: CjguiExperimentalDemoCommitActionRouteCatalog
    let commitHarness: CjguiExperimentalDemoCommitHarness
    let runHarness: CjguiExperimentalDemoRunHarness
    private var messages = ArrayList<ChatMessage>()
    var lastSender: String
    var lastText: String

    init() {
        this.demoName = "chat"
        this.componentSession = CjguiExperimentalDemoComponentActionSession(
            "chat",
            "messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer",
            "threaded_chat",
            "chat_thread",
            "",
            "composer"
        )
        this.routeCatalog = CjguiExperimentalDemoComponentActionRouteCatalog()
        this.commitRouteCatalog = CjguiExperimentalDemoCommitActionRouteCatalog()
        this.commitHarness = CjguiExperimentalDemoCommitHarness(
            "chat",
            "messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer"
        )
        this.runHarness = CjguiExperimentalDemoRunHarness("chat")
        this.lastSender = "assistant"
        this.lastText = "Welcome to CJGUI"
        messages.add(ChatMessage(lastSender, lastText))
    }

    func updateComposer(text: String) {
        componentSession.typeInput(text)
        componentSession.moveFocus("composer")
        componentSession.recordComponentActionRoute(
            routeCatalog.chatTypeMessage(),
            businessState()
        )
    }

    func appendMessage(sender: String, text: String) {
        messages.add(ChatMessage(sender, text))
        lastSender = sender
        lastText = text
        if (sender == "assistant") {
            componentSession.applyStyle("assistant_reply")
        } else {
            componentSession.applyStyle("owner_message")
        }
        componentSession.recordComponentActionRoute(
            routeCatalog.chatAppendReply(),
            businessState()
        )
    }

    func sendComposer(sender: String): Bool {
        if (componentSession.textInput() == "") {
            return false
        }
        let message = componentSession.textInput()
        messages.add(ChatMessage(sender, message))
        lastSender = sender
        lastText = message
        componentSession.applyStyle("owner_message")
        componentSession.typeInput("")
        componentSession.recordComponentActionRoute(
            routeCatalog.chatSendMessage(),
            businessState()
        )
        return true
    }

    func moveFocus(target: String) {
        componentSession.moveFocus(target)
        componentSession.recordComponentActionRoute(
            routeCatalog.chatMoveFocus(target),
            businessState()
        )
    }

    func messageCount(): Int64 {
        return messages.size
    }

    func businessState(): String {
        return "messages=${messages.size};last=${lastSender}:${lastText};composer=${componentSession.textInput()};focus=${componentSession.focus()}"
    }

    func summary(): String {
        return "demo=${demoName};layout=${componentSession.layout()};${businessState()}"
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
    let thread = ChatThreadState()
    let before = thread.businessState()
    thread.updateComposer("Ship Chat demo")
    let sent = thread.sendComposer("owner")
    thread.appendMessage("assistant", "Chat demo received")
    thread.moveFocus("message_list")
    let after = thread.businessState()
    let summary = thread.summary()
    let stateReadbackOk = before == "messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer" &&
        after == "messages=3;last=assistant:Chat demo received;composer=;focus=message_list" &&
        thread.sharedBefore() == before &&
        thread.sharedAfter() == after &&
        thread.sharedActions() == "chat.type_message,chat.send_message,chat.append_reply,chat.move_focus" &&
        thread.sharedWrites() == 4 &&
        thread.sharedComponentActions() == "composer:chat.type_message,send_button:chat.send_message,message_list:chat.append_reply,message_list:chat.move_focus" &&
        thread.sharedUiState() == "layout=threaded_chat;style=assistant_reply;input=;focus=message_list" &&
        sent &&
        thread.messageCount() == 3 &&
        summary == "demo=chat;layout=threaded_chat;messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
    let apiOutput = thread.buildSharedOutput(summary, stateReadbackOk)
    let commitRoute = thread.commitRouteCatalog.chatCommitThread()
    let commitResult = thread.commitHarness.commitComponentActionRoute(commitRoute, after)
    let commitReadbackOk = stateReadbackOk &&
        apiOutput.demoName == "chat" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == after &&
        apiOutput.actionTrace == "chat.type_message,chat.send_message,chat.append_reply,chat.move_focus" &&
        apiOutput.writeCount == 4 &&
        apiOutput.domainSummary == summary &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=chat;readback=true;writes=4;actions=chat.type_message,chat.send_message,chat.append_reply,chat.move_focus;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;summary=demo=chat;layout=threaded_chat;messages=3;last=assistant:Chat demo received;composer=;focus=message_list" &&
        thread.commitHarness.resultMatchesRoute(commitResult, commitRoute, before, after)
    let runResult = thread.runHarness.finishCommittedSessionRun(
        "not_started",
        "runnable",
        apiOutput,
        thread.componentSession,
        commitResult,
        commitReadbackOk
    )
    let evidencePresenter = CjguiExperimentalDemoEvidencePresenter("cjgui chat demo app")
    let readbackOk = commitReadbackOk && runResult.runnable
    let evidenceBuilder = CjguiExperimentalDemoEvidenceSectionBuilder("chat", "not_started", "runnable")
    evidenceBuilder.addLayoutEvidence(CjguiExperimentalDemoLayoutEvidence("threaded_chat"))
    evidenceBuilder.addInteractionEvidence(
        CjguiExperimentalDemoComponentInteractionEvidence("type_message,send_message,append_reply,move_focus")
    )
    evidenceBuilder.addStateReadbackEvidence(CjguiExperimentalDemoStateReadbackEvidence(before, after, readbackOk))

    let evidenceSection = evidenceBuilder.buildSection(
        apiOutput,
        thread.componentSession,
        commitResult,
        thread.commitHarness,
        runResult
    )
    evidencePresenter.printEvidenceSection(evidenceSection)

    if (readbackOk) {
        return 0
    }
    return 1
}
