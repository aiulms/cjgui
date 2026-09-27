# ArkUI IME preview control

This standalone HarmonyOS app tests what a visible, native ArkUI `TextInput` receives from the system input method. It has no CJGUI, Cangjie, NAPI, or native rendering dependency. Its bundle is `com.example.cjguiimecontrol`, separate from the CJGUI app.

The field explicitly enables preview text. `onChange` logs the full value, whether the optional `PreviewText` object is present, its offset and value, and whether `TextChangeOptions` is present. The value shown below the field is a readout only; it is never fed back to `TextInput.text`.

Build from this directory:

```sh
/Users/jiangxuanyang/.local/bin/devecocli build --build-mode debug
```

On the existing simulator, select its exact HDC target before installing or launching:

```sh
HDC=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc
TARGET=127.0.0.1:5555
"$HDC" -t "$TARGET" install -r entry/build/default/outputs/default/entry-default-unsigned.hap
"$HDC" -t "$TARGET" shell 'aa start -a EntryAbility -b com.example.cjguiimecontrol'
"$HDC" -t "$TARGET" shell 'hilog -x' | rg ImeControl
```

The debug HAP is unsigned and installs on the current simulator. Device signing requirements may differ. Use the visible system keyboard to type pinyin; `uitest uiInput inputText` pastes text and does not test the same IME composition path.

The observed run and exact HAP are in [artifacts/2026-09-27-control](artifacts/2026-09-27-control/RESULT.md).
