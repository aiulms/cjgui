package cjgui

import cjgui_shared_operation_core.*
import std.env.*
import std.fs.*

// A deliberately small executable used only by the shell acceptance probe.
// Each invocation owns a fresh binding, so the probe exercises the filesystem
// claim and persisted baseline across real OS processes rather than threads.
private func emit(result: CjguiTextDocumentFileSaveResult): Unit {
    getStdOut().writeln(result.reason)
    getStdOut().flush()
}

private func save(binding: CjguiTextDocumentFileBinding, path: String, content: String): Unit {
    let document = CjguiTextDocument(9901, "进程保存探针", content)
    emit(binding.saveFromHuman(document.snapshot(), path))
}

main(args: Array<String>): Int64 {
    if (args.size < 3) {
        getStdErr().writeln("usage: shared_text_document_file_process_probe save|open-save|open-wait-save PATH CONTENT [GATE_PATH]")
        return 2
    }
    let operation = args[0]
    let path = args[1]
    let content = args[2]
    let binding = CjguiTextDocumentFileBinding()
    if (operation == "save") {
        save(binding, path, content)
        return 0
    }
    let opened = binding.openFromHuman(9901, "进程保存探针", path)
    if (!opened.applied) {
        getStdOut().writeln("open_failed")
        getStdOut().flush()
        return 0
    }
    if (operation == "open-save") {
        save(binding, path, content)
        return 0
    }
    if (operation != "open-wait-save" || args.size != 4) {
        getStdErr().writeln("invalid operation")
        return 2
    }
    let gate = args[3]
    getStdOut().writeln("READY")
    getStdOut().flush()
    var attempts = 0
    while (!exists(gate) && attempts < 400) {
        sleep(Duration.millisecond * 5)
        attempts += 1
    }
    if (!exists(gate)) {
        getStdOut().writeln("gate_timeout")
        getStdOut().flush()
        return 0
    }
    save(binding, path, content)
    return 0
}
