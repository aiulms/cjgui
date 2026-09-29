// Narrow Cangjie-to-system logger. The Kit Hilog module in this SDK links a
// compile-time mock unavailable on the simulator; the public NDK library is
// present in the system image and is linked by this transport package.
package cjgui_ohos_transport

foreign func OH_LOG_PrintMsg(logType: Int32, level: Int32, domain: UInt32,
    tag: CString, message: CString): Int32

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
