// Narrow Cangjie-to-system logger. The Kit Hilog module in this SDK links a
// compile-time mock unavailable on the simulator; the public NDK library is
// present in the system image and is linked by this transport package.
package cjgui_ohos_transport

foreign func OH_LOG_PrintMsg(logType: Int32, level: Int32, domain: UInt32,
    tag: CString, message: CString): Int32

// round7-B：渲染器宿主导出的**只读**观测序号（进程内单调，全序）。hilog 行序是
// hilogd 的接收序，跨线程（owner 的 waitFor 与连接 worker 的入队之间没有共享锁）
// 不等于事件因果序，跨语言时钟也不能直接相减；这个原子计数器是两侧唯一能共享
// 的全序域。它只被日志读取，不参与调度、许可或公开协议。
foreign func cjgui_ohos_observation_seq(): UInt64

/// 本进程内下一个观测序号。纯只读：调用它不改变任何状态。
public func cjguiOhosObservationSeq(): UInt64 {
    return unsafe { cjgui_ohos_observation_seq() }
}

func cjguiOhosLog(level: Int32, tag: String, message: String): Unit {
    try {
        let cTag = unsafe { LibC.mallocCString(tag) }
        try {
            let cMessage = unsafe { LibC.mallocCString(message) }
            try {
                let _ = unsafe { OH_LOG_PrintMsg(0, level, 0, cTag, cMessage) }
            } finally {
                unsafe { LibC.free(cMessage) }
            }
        } finally {
            unsafe { LibC.free(cTag) }
        }
    } catch (_) {
        // Diagnostic output must never unwind across the owner or TCP bridge.
    }
}

public func cjguiOhosInfo(tag: String, message: String): Unit {
    cjguiOhosLog(4, tag, message)
}

public func cjguiOhosWarn(tag: String, message: String): Unit {
    cjguiOhosLog(5, tag, message)
}

public func cjguiOhosError(tag: String, message: String): Unit {
    cjguiOhosLog(6, tag, message)
}
