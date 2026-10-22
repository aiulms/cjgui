package cjgui

import std.process.*

// Direct root cjpm builds/tests run this hook and remain serialized per target.
// The normal macOS application runner pins its own archive through generated
// cjpm inputs and skips this shared-cache hook; it never replaces native/lib.
// The archive contains the
// narrow internal Objective-C renderer ABI declared by runtime_renderer_session;
// it is deliberately not a public C API or a source-set substitution.
//
// 平台分派：Linux 用 platforms/linux/scripts/build_sidecar.sh 构建同一份 ABI 的
// X11 + Vulkan + FreeType 实现；macOS 仍走原有 Objective-C/Metal sidecar。两边产物
// 生产产物仍落在 native/lib；macOS 包内测试通过显式测试入口链接
// native/testing/lib，不用编译宏原地替换生产归档。
main(): Int64 {
    let probe = executeWithOutput("uname", [])
    let systemName = if (probe[1].size > 0) { String.fromUtf8(probe[1]) } else { "" }
    if (systemName.contains("Linux")) {
        return execute("bash", ["platforms/linux/scripts/build_sidecar.sh"])
    }
    return execute("zsh", ["native/scripts/build_cjgui_internal_renderer_sidecar.sh"])
}
