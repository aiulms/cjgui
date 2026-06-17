package cjgui_todo_demo

import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}
import std.collection.*

// 中文维护注释：这是独立 Todo demo app，不属于 runtime_renderer_stage* owner 链。
// Scope: 验证 Todo 消费 CJGUI experimental 非 Bool public API，并保留 owner-local 状态写入读回。
// Stop-line: 不写 runtime_state / renderer_state，不调用 native bridge，不提交 renderer。

class TodoDemoItem {
    let id: Int64
    let title: String
    var isDone: Bool

    init(id: Int64, title: String, isDone: Bool) {
        this.id = id
        this.title = title
        this.isDone = isDone
    }
}

class TodoList {
    private var nextId: Int64 = 1
    private var items = ArrayList<TodoDemoItem>()

    init() {}

    func add(title: String): Int64 {
        let id = nextId
        nextId += 1
        items.add(TodoDemoItem(id, title, false))
        return id
    }

    func complete(id: Int64): Bool {
        for (item in items) {
            if (item.id == id) {
                item.isDone = true
                return true
            }
        }
        return false
    }

    func count(): Int64 {
        return items.size
    }

    func firstTitle(): String {
        if (items.size == 0) {
            return "<none>"
        }
        return items[0].title
    }

    func firstDone(): Bool {
        if (items.size == 0) {
            return false
        }
        return items[0].isDone
    }

    func summary(): String {
        if (items.size == 0) {
            return "items=0;first=<none>;first_done=false"
        }
        return "items=${items.size};first=${items[0].title};first_done=${items[0].isDone}"
    }
}

main(): Int64 {
    let todos = TodoList()
    let before = todos.summary()
    let sharedTrace = CjguiExperimentalDemoInteractionTrace("todo", before)
    let createdId = todos.add("Write first CJGUI todo")
    let afterAdd = todos.summary()
    sharedTrace.recordAction("todo.add", afterAdd)
    let completed = todos.complete(createdId)
    let afterComplete = todos.summary()
    sharedTrace.recordAction("todo.complete", afterComplete)
    let stateReadbackOk = before == "items=0;first=<none>;first_done=false" &&
        afterAdd == "items=1;first=Write first CJGUI todo;first_done=false" &&
        afterComplete == "items=1;first=Write first CJGUI todo;first_done=true" &&
        sharedTrace.before() == before &&
        sharedTrace.after() == afterComplete &&
        sharedTrace.actions() == "todo.add,todo.complete" &&
        sharedTrace.writes() == 2 &&
        todos.count() == 1 &&
        todos.firstTitle() == "Write first CJGUI todo" &&
        todos.firstDone() &&
        completed
    let apiOutput = CjguiExperimentalDemoOutputBuilder().buildFromTrace(sharedTrace, afterComplete, stateReadbackOk)
    let readbackOk = stateReadbackOk &&
        apiOutput.demoName == "todo" &&
        apiOutput.beforeState == before &&
        apiOutput.afterState == afterComplete &&
        apiOutput.actionTrace == "todo.add,todo.complete" &&
        apiOutput.writeCount == 2 &&
        apiOutput.domainSummary == afterComplete &&
        apiOutput.readbackOk &&
        apiOutput.summary == "demo=todo;readback=true;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true;summary=items=1;first=Write first CJGUI todo;first_done=true"

    println("cjgui todo demo app: demo=todo")
    println("cjgui todo demo app: status_before=state_writable")
    println("cjgui todo demo app: status_after=runnable")
    println("cjgui todo demo app: interaction=add_todo,complete_todo")
    println("cjgui todo demo app: summary_before=${before}")
    println("cjgui todo demo app: summary_after_add=${afterAdd}")
    println("cjgui todo demo app: summary_after_complete=${afterComplete}")
    println("cjgui todo demo app: public_api_consumed=true")
    println("cjgui todo demo app: public_api_name=CjguiExperimentalDemoOutputBuilder")
    println("cjgui todo demo app: public_api_output=${apiOutput.summary}")
    println("cjgui todo demo app: shared_support=CjguiExperimentalDemoInteractionTrace")
    println("cjgui todo demo app: shared_support_output=${sharedTrace.summary()}")
    println("cjgui todo demo app: owner_local_write_readback=${readbackOk}")

    if (readbackOk) {
        return 0
    }
    return 1
}
