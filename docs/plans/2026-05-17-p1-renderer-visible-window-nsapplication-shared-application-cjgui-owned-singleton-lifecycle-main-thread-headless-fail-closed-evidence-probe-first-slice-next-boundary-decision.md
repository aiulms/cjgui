# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe first slice next-boundary decision

状态：next-boundary / native-readiness preflight selected

## 当前封账点

scan-only evidence probe first slice 已形成 internal-only readiness：

- main-thread confinement evidence 已以 no-side-effect fact 记录。
- headless fail-closed evidence 已以 no-side-effect fact 记录。
- singleton creation、application accessor call、native bridge expansion 与 runtime probe execution 均保持 false。
- production singleton ownership truth 与 implementation 仍 blocked。
- activation、event-loop、visible、drawable、render stop-line 仍保持。

## 下一边界

下一阶段可以继续在 evidence probe runway 内推进，但只能进入 native-readiness preflight / no-accessor no-bridge-expansion decision。

下一阶段仍不能进入 application singleton accessor call implementation、production singleton owner implementation、cleanup / teardown execution、activation、event loop、visible order、drawable、render、state write、public API 或 C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe native-readiness preflight / no-accessor no-bridge-expansion decision`
