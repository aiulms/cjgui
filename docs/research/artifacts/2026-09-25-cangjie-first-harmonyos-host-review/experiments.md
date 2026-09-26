# Raw experiment record

## E0 — current implementation observation (read-only)

Existing active-task HAP, not built by this review:

```text
path: labs/ohos_cjgui_app/entry/build/default/outputs/default/entry-default-unsigned.hap
mtime: 2026-09-25 12:32:26 +0800
size: 21 MiB
sha256: 405e67b59b5ceb34c29eea090f7f34f8f7e3e3e42a4692485493713b126a36a6
contents include:
  libs/arm64-v8a/libentry.so
  libs/arm64-v8a/libcjgui_app.so
  libs/arm64-v8a/libcangjie-runtime.so
  Cangjie standard-library shared objects
```

Existing screenshot inspected:

```text
labs/ohos_cangjie_smoke/artifacts/cjgui-backend/screenshots/a1_first_screen.jpeg
```

It shows the ArkTS page, black XComponent area, and a probe result containing
both `official=...` and `raw=...`. This proves the existing probe screen ran; it
does not prove CJGUI rendering, input, owner convergence, or recovery.

Read-only `hilog` excerpt from the already-running emulator:

```text
09-25 12:33:41.909 ... CjguiApp: onCreate
09-25 12:33:41.923 ... CjguiApp: onWindowStageCreate
09-25 12:33:41.958 ... CjguiApp: loadContent ok
09-25 12:33:42.043 ... CjguiApp: XComponent loaded
09-25 12:33:42.043 ... CjguiHost: cangjie library loaded: libcjgui_app.so
09-25 12:33:42.043 ... CjguiHost: calling cjgui_ohos_app_main
09-25 12:33:42.043 ... CjguiHost: cjgui_ohos_app_main returned <private>
09-25 12:34:59.210 ... CjguiHost: cangjie probe magic=<private> heap=<private>
```

Status: existing runtime probe observed; renderer/business chain `not_run` by
this review.

### Source advanced after the observed HAP

At 12:51 the active implementer replaced the probe-only Cangjie source with
`entry/src/main/cangjie/ohos_app.cj` (sha256
`6410021dd3229bc228e4df8848970a71f8f9300b818c379f6d4b628baa93c673`).
The new source creates `CjguiSettingsCounterDomain`, controller, shared host,
and external connection. `ohos_renderer.cpp` contains a C shim from
`cjgui_ohos_app_main` to the Cangjie export
`cjgui_ohos_app_main_cangjie`, so the differing symbol names are intentional.

At 12:56 no corresponding new HAP existed yet. The active implementation then
produced and installed newer HAPs while this review was still validating. The
chronological results follow.

### 12:57 dependency leg

The first newer HAP reached the XComponent load but the host could not load the
Cangjie library:

```text
CjguiApp: XComponent loaded
CjguiHost: dlopen libcjgui_app.so failed: Error loading shared library
libcangjie-std-ast.so: needed by .../libcjgui_app.so
CjguiHost: cangjie library not loadable; host stays idle
```

The packaging script then produced a 12:58 HAP containing
`libs/arm64-v8a/libcangjie-std-ast.so` (9,805,280 bytes), so this leg was
superseded by a more specific relocation failure.

### 12:58 C-linkage leg

HAP for the C-linkage failure leg:

```text
path: labs/ohos_cjgui_app/entry/build/default/outputs/default/entry-default-unsigned.hap
mtime: 2026-09-25 12:58:34 +0800
size: 32,469,169 bytes
sha256: 233550e3dd28c1e091bbbab87358e9e09a51fe042c2fe84cbc08aa2b582446b7
```

Runtime error, reproduced on two library candidate paths:

```text
CjguiApp: XComponent loaded
CjguiHost: dlopen libcjgui_app.so failed: Error relocating
.../libcjgui_app.so: cjgui_ohos_surface_ready: symbol not found
CjguiHost: cangjie library not loadable; host stays idle
```

`llvm-readelf -Ws` on the packaged `libcjgui_app.so`:

```text
NOTYPE GLOBAL DEFAULT UND cjgui_ohos_surface_ready
FUNC   GLOBAL DEFAULT 11  _Z24cjgui_ohos_surface_readyv
FUNC   GLOBAL DEFAULT 11  cjgui_ohos_app_main_cangjie
FUNC   GLOBAL DEFAULT 11  cjgui_ohos_app_main
```

Source correlation:

```text
ohos_renderer.cpp:1426 closes the extern "C" block.
ohos_renderer.cpp:1431 defines cjgui_ohos_surface_ready afterward.
ohos_app.cj declares foreign func cjgui_ohos_surface_ready(): UInt8.
```

Root-cause status: confirmed C++ name mangling at the language boundary. No
source fix was made by this review. The active implementer then moved the
function into the existing `extern "C"` block. The 13:00 packaged symbol table
showed a defined, unmangled `cjgui_ohos_surface_ready` and no same-name `UND`;
runtime advanced to the next dependency.

### 13:00 platform-native closure leg

Current HAP at the 13:01 cutoff:

```text
path: labs/ohos_cjgui_app/entry/build/default/outputs/default/entry-default-unsigned.hap
mtime: 2026-09-25 13:00:37 +0800
size: 32,469,169 bytes
sha256: c9c49891d164ffd6df70d7c89d282739f52834f435007fe419b91c408d3b85c9
```

Runtime advanced past `cjgui_ohos_surface_ready` and failed at:

```text
Error relocating .../libcjgui.so:
cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked: symbol not found
CjguiHost: cangjie library not loadable; host stays idle
```

Full inventory, not just the first loader complaint:

```text
255 unique undefined symbols in packaged libcjgui.so match
^cjgui_native_bridge_
Examples include AppKit, Metal, CAMetalLayer, command queue, command buffer,
render-pass, and drawable probe symbols.
```

The OHOS renderer implements `cjgui_internal_renderer_*`, not the macOS
`cjgui_native_bridge_*` family. The copied `entry/cjgui` package compiles every
file in `src` without an OHOS source-set split, so macOS-only foreign references
remain in the ELF even when the settings-counter route does not call them.

Root-cause status: platform source-set/foreign-symbol closure mismatch. The
next proof must inventory all `UND` symbols and either route the public Cangjie
APIs through an `os.ohos` implementation or provide centralized, truthful
fail-closed OHOS bridge implementations. Iteratively stubbing only the first
loader error or switching to lazy binding would not prove a loadable framework.

## E1 — Cangjie UIAbility with an ArkTS page in the same module

Base: isolated copy of `labs/ohos_cjgui_app` at
`/private/tmp/cjgui-cangjie-host-review.ssie7x/app`.

Only experiment edits:

```diff
- "srcEntry": "./ets/entryability/EntryAbility.ets"
+ "srcEntry": "cjgui_app.MainAbility"
```

Added a Cangjie `MainAbility <: UIAbility` that calls:

```cangjie
windowStage.loadContent("pages/Index")
```

Command:

```sh
source scripts/env.sh
"$DEVECO_CLI" build --build-mode debug
```

Exact decisive output:

```text
ERROR: Failed :entry:default@CangjiePreBuild...
01103043 Configuration Error
Invalid configuration of 'module-abilities-srcEntry' field.
If the module contains the ArkTS code, the ArkTS code must be used as the entry.
Relative file path(like ./**) is required for srcEntry.
BUILD FAILED
```

Status: negative build proof for the simple same-module arrangement. It does
not prove every possible multi-module topology impossible.

## E2 — direct Cangjie XComponent import

Base: isolated copy of `labs/ohos_cangjie_smoke` at
`/private/tmp/cjgui-cangjie-xcomponent-review.q1Oz08/app`.

Change:

```cangjie
import kit.ArkUI.XComponent
```

Command: the same `devecocli build --build-mode debug` invocation.

Exact decisive output:

```text
ERROR: Failed :entry:default@CompileCangjie...
error: 'XComponent' is not accessible in package 'kit.ArkUI'
.../entry/src/main/cangjie/index.cj:7:8
1 error generated
BUILD FAILED
```

After removing only that import, the unchanged pure-Cangjie baseline built:

```text
Finished :entry:default@CompileCangjie...
Finished :entry:default@PackageHap...
BUILD SUCCESSFUL in 20 s 995 ms
```

Status: direct binding unavailable in this installed SDK. This is not a claim
about future SDKs.

## E3 — pure-Cangjie Canvas host candidate

The same isolated pure-Cangjie app page was replaced with the documented API:

```cangjie
package ohos_app_cangjie_entry

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*

@Entry
@Component
class Index {
    var settings: RenderingContextSettings = RenderingContextSettings(antialias: true)
    var context: CanvasRenderingContext2D = CanvasRenderingContext2D(this.settings)

    func build() {
        Canvas(this.context)
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(0xff101820)
            .onReady({ =>
                this.context.fillRect(16.0, 16.0, 96.0, 64.0)
            })
    }
}
```

Build result:

```text
Finished :entry:default@CompileCangjie... after 1 s 846 ms
Finished :entry:default@PackageHap... after 257 ms
BUILD SUCCESSFUL in 2 s 533 ms
```

Output:

```text
path: /private/tmp/cjgui-cangjie-xcomponent-review.q1Oz08/app/entry/build/default/outputs/default/entry-default-unsigned.hap
size: 817 KiB
sha256: cc8de9dbdc9e8e022b37522003eff2ba864cf43f2ae8218db932c16f15477a8c
contains: libs/arm64-v8a/libohos_app_cangjie_entry.so
```

Status: build/package proven only. Installation, visible rendering, repeated
frames, text correctness, input, owner readback, lifecycle recovery, and
performance are `not_run` because the connected emulator was in active use by
another implementation task.

## E4 — public native mounting API inventory

Installed headers contain:

```text
arkui/native_node.h:
  ARKUI_NODE_XCOMPONENT = 12
  ArkUI_NativeNodeAPI_1::createNode(ArkUI_NodeType)
  ArkUI_NativeNodeAPI_1::addChild(parent, child)
  OH_ArkUI_NodeContent_AddNode(content, node)
  OH_ArkUI_NativeModule_GetPageRootNodeHandleByContext(context, rootNode) [since 24]

ace/xcomponent/native_interface_xcomponent.h:
  OH_NativeXComponent_GetNativeXComponent(ArkUI_NodeHandle) [since 12]

arkui/native_node_napi.h:
  OH_ArkUI_GetNodeHandleFromNapiValue(env, ArkTS FrameNode, ...)
  OH_ArkUI_GetContextFromNapiValue(env, ArkTS UIContext, ...)
  OH_ArkUI_GetNodeContentFromNapiValue(env, ArkTS NodeContent, ...)
```

No public `CreateNodeContent`-style API was found in the installed native
headers, and no Cangjie `XComponent`, `NodeContent`, or native-handle export was
found in the installed Cangjie ArkUI package or bundled Cangjie docs.

Interpretation: Native can create and manage an XComponent after it has a
mounting handle, but the documented route for obtaining that handle is an
ArkTS NAPI value. This is the present public-contract gap, not a proof that an
internal or future route cannot exist.
