package cjgui_shared_operation_window_app

import cjgui.CjguiSharedOperationWindow
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*

foreign func cjgui_shared_operation_window_app_finish(): Unit

func finishNativeLauncher(): Unit {
    unsafe {
        cjgui_shared_operation_window_app_finish()
    }
}

// This normal app deliberately owns more records than the native viewport can
// display.  The titles make the independent acceptance agent choose targets
// from a GET_CONTEXT response rather than from a pre-supplied record ID. Both actual
// targets and the same-looking, non-writable lure begin outside the first
// eight visible rows.
func sharedOperationRecords(): ArrayList<CjguiSharedOperationRecord> {
    let records = ArrayList<CjguiSharedOperationRecord>()
    var offset: Int64 = 0
    while (offset < 101) {
        let id = 1000 + offset
        var title = "共同操作记录 ${id}"
        if (id == 1077) {
            title = "远程验收候选：北区复核"
        } else if (id == 1088) {
            title = "远程验收候选：南区复核"
        } else if (id == 1094) {
            title = "远程验收候选：未授权诱饵"
        }
        records.add(CjguiSharedOperationRecord(id, title, false))
        offset += 1
    }
    return records
}

// The sample grants a single local caller a capability obtained only through
// its 0600 descriptor in the app-created 0700 directory. GET_CONTEXT has the full
// app context, while SET_MARKED can change only the two intended records.
// Human selection and marking continue to enter the list directly via the
// window and are not grants to the external caller.
func sharedOperationAuthorization(): CjguiSharedOperationExternalAuthorization {
    return CjguiSharedOperationExternalAuthorization(
        "独立 Luna 验收 Agent",
        "cjgui-sample-luna-20260911",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope(
                "GET_CONTEXT",
                ArrayList<Int64>(),
                true
            ),
            CjguiSharedOperationExternalActionScope(
                "SET_MARKED",
                ArrayList<Int64>([1077, 1088]),
                false
            )
        ])
    )
}

func runSharedOperationWindowApp(): Int32 {
    let list = CjguiSharedOperationList(sharedOperationRecords())
    let connection = CjguiSharedOperationExternalConnection(
        list,
        sharedOperationAuthorization()
    )
    let window = CjguiSharedOperationWindow(list)
    // The platform bridge remains the only path to the native window. The
    // connection is pumped alongside it rather than occupying a scheduler
    // thread with a permanent blocking accept loop.
    if (!window.start()) {
        println("cjgui shared operation: window_started=false status=${window.nativeStatus()}")
        finishNativeLauncher()
        return 1
    }
    if (!connection.start()) {
        println("cjgui shared operation: external_connection_started=false")
        window.close()
        finishNativeLauncher()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        // The descriptor is the intentional discovery handoff. It carries the
        // socket path, capability, protocol and action/object scope; do not
        // reconstruct a path or use a fixed global socket name.
        let output = getStdOut()
        output.writeln("CJGUI_SHARED_OPERATION_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_SHARED_OPERATION_READY PROTOCOL ${info.protocol}")
        output.writeln("CJGUI_SHARED_OPERATION_READY ACTION_COUNT ${info.actions.size}")
        output.flush()
    } else {
        let output = getStdOut()
        output.writeln("CJGUI_SHARED_OPERATION_READY DESCRIPTOR_PATH unavailable")
        output.flush()
    }

    while (window.isOpen()) {
        let _ = connection.pump(1u32)
        let _ = window.pump(16u32)
        sleep(Duration.millisecond * 16)
    }

    let finalSnapshot = list.snapshot()
    println("cjgui shared operation: final_version=${finalSnapshot.version}")
    println("cjgui shared operation: final_selected=${finalSnapshot.selectedRecordId}")
    connection.close()
    finishNativeLauncher()
    return 0
}

main(): Int64 {
    return Int64(runSharedOperationWindowApp())
}
