# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe runtime native-readiness probe execution preflight next-boundary decision

状态：next-boundary / stage 75 / no runtime execution

## Decision

Stage 75 runtime native-readiness probe execution preflight 已经完成 formal seal。下一段只允许打开 runtime native-readiness probe execution value boundary 的 owner decision，并且必须继续保持 no-accessor / no-bridge-expansion / no-runtime-execution。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe runtime native-readiness probe execution value boundary / no-accessor no-bridge-expansion no-runtime-execution owner decision`

## Guard

下一段不等于 runtime native probe execution，也不授权 application singleton accessor、native bridge expansion、production singleton owner implementation、cleanup / teardown execution、activation、event loop、visible order、drawable、render、public API、production public C ABI、renderer state write、`runtime_state.cj` write 或 `runtime/cjgui/cjpm.toml` change。
