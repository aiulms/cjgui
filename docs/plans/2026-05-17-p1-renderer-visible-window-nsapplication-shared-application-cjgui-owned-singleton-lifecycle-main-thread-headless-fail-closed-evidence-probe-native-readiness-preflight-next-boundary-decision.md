# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe native-readiness preflight next-boundary decision

状态：next-boundary / native-readiness value boundary selected

## 当前封账点

native-readiness preflight 已形成 internal-only readiness：

- native-readiness preflight 已打开。
- application accessor call 继续 false。
- native bridge expansion 继续 false。
- runtime native probe execution 继续 false。
- singleton creation、cleanup / teardown execution、production singleton ownership truth 与 implementation 仍 blocked。
- activation、event-loop、visible、drawable、render stop-line 仍保持。

## 下一边界

下一阶段可以继续在 evidence probe runway 内推进，但只能进入 native-readiness value boundary / no-accessor no-bridge-expansion owner decision。

下一阶段仍不能进入 application singleton accessor call implementation、production singleton owner implementation、native bridge expansion、runtime native probe execution、cleanup / teardown execution、activation、event loop、visible order、drawable、render、state write、public API 或 C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe native-readiness value boundary / no-accessor no-bridge-expansion owner decision`
