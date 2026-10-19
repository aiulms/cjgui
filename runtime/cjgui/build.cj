package cjgui

import std.process.*

// cjpm runs this before normal builds and tests.  The archive contains the
// narrow internal Objective-C renderer ABI declared by runtime_renderer_session;
// it is deliberately not a public C API or a source-set substitution.
//
// 平台分派：Linux 用 platforms/linux/scripts/build_sidecar.sh 构建同一份 ABI 的
// X11 + Vulkan + FreeType 实现；macOS 仍走原有 Objective-C/Metal sidecar。两边产物
// 落在同一个 native/lib/libcjgui_internal_renderer.a，消费者不需要分叉。
main(): Int64 {
    let probe = executeWithOutput("uname", [])
    let systemName = if (probe[1].size > 0) { String.fromUtf8(probe[1]) } else { "" }
    if (systemName.contains("Linux")) {
        return execute("bash", ["platforms/linux/scripts/build_sidecar.sh"])
    }
    return execute("zsh", ["native/scripts/build_cjgui_internal_renderer_sidecar.sh"])
}
