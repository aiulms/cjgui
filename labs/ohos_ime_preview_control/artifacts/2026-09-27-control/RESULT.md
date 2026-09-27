# 2026-09-27 ArkUI TextInput control

## Identity and build

- Bundle: `com.example.cjguiimecontrol`; separate from `com.example.cjguiapp`.
- Source: `entry/src/main/ets/pages/Index.ets`, visible ArkUI `TextInput` with `.enablePreviewText(true)`, no value roundtrip into the field.
- Build: `/Users/jiangxuanyang/.local/bin/devecocli build --build-mode debug` returned `BUILD SUCCESSFUL`; `CompileArkTS` and `PackageHap` passed. No signing profile was configured; the simulator accepted the unsigned HAP.
- Archived HAP: `entry-default-unsigned.hap`, SHA-256 `f373b16476750a9e36e5deba3e182ee9421519ee45c13a3c61dd9326a0ce5574` (matches the build output).
- Source SHA-256: `Index.ets` `bbaf2b831a7260628651e651eaecfd97615c02ac7d5597c8c6983628b7d0e5ef`; `EntryAbility.ets` `13e796dce0b5680eaf4c553523b26f5cb22304b791bc4cf58d16ad7338a85486`; bundle manifest `AppScope/app.json5` `663c8554ccbc6d9c7b58ea9446657a859cb6d93bd891d9186c20ee288cbe5767` (`source.sha256`). The build task log is `build.log`.
- HAP listing contains `ets/modules.abc` and resources, with no `.so` or Cangjie files.
- HDC target: `127.0.0.1:5555`; launched control PID `28616` and the same PID remained through the last screenshot.
- Local ETS SDK: `26.0.0.105` (`sdk-ets-oh-uni-package.json`). Simulator: API 24, `emulator 6.1.0.117(SP37DEVC00E115R4P11)` (`device-version.txt`). Active IME: `com.huawei.hmos.inputmethod`, BASIC_MODE, version `1.2.1.307` (`ime-current.txt`, `ime-bundle-dump.txt`).

## System Pinyin observations

1. Tapped the visible field; `focused.jpeg` shows the system keyboard and the app's focused state.
2. Tapped keyboard keys for `nihao`. `composition.jpeg` shows the IME's “你好” candidate while the field remains empty and the app still displays `onChange count: 0`. No `ImeControl` `onChange` line was emitted at this point.
3. Tapped “你好”. `after_commit.jpeg` shows the field and readout as `你好`. The one callback was: `onChange seq=1 value=你好 previewPresent=1 previewOffset=-1 previewValue= optionsPresent=1`. `PreviewText` was present as an empty, offset `-1` value; this is no observed marked range.
4. Tapped `ni` and then the keyboard backspace twice. `cancel_before.jpeg` shows the fresh candidate state with the committed field still `你好`; `cancel_after.jpeg` shows the candidate gone. The callback count stayed 1, with no additional `onChange` on composition cancellation.
5. Tapped keyboard “完成”. `ime_control_hilog.txt` shows `submitted after 1 changes` followed by `blurred`; `after_submit.jpeg` records the final field.

`raw_hilog.txt` is the unmodified full device hilog buffer captured at the end; `ime_control_hilog.txt` preserves complete original lines for this app's tag. Screenshots are direct `snapshot_display` captures. No global hilog clear was used. These results characterize this simulator, SDK, and input method combination; they do not establish behavior on another IME or device.

After capture, `aa force-stop com.example.cjguiimecontrol` returned success and `pidof` returned no PID (`pid_after_stop.txt`). The separate app remains installed for reproduction; no CJGUI bundle was stopped or uninstalled.
