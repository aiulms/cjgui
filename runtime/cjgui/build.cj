package cjgui

import std.process.*

// cjpm runs this before normal builds and tests.  The archive contains the
// narrow internal Objective-C renderer ABI declared by runtime_renderer_session;
// it is deliberately not a public C API or a source-set substitution.
main(): Int64 {
    return execute("zsh", ["native/scripts/build_cjgui_internal_renderer_sidecar.sh"])
}
