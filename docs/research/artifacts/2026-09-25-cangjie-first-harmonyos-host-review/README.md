# Cangjie-first HarmonyOS host review evidence

Captured: 2026-09-25 13:01 +0800.

This directory contains the bounded experiments and Laya decisions used by
`docs/research/2026-09-25-cangjie-first-harmonyos-host-review.md`.

The experiments were run in isolated copies under `/private/tmp`; they did not
edit, install, start, stop, or replace the active `labs/ohos_cjgui_app` task.
The already-running Pura 90 emulator belonged to the active implementation
work, so this review performed only a read-only `hilog` query and inspected an
existing screenshot. No review build was installed.

Environment:

- HarmonyOS Native and ETS SDK: `26.0.0.105`, API 26, release.
- HarmonyOS Cangjie SDK: `26.0.0.105`, platform 26, release.
- Cangjie DevEco plugin: `26.0.0.821`.
- Cangjie compiler reported `1.2.0-beta.rc3 (cjnative)`.
- Project target: `targetSdkVersion 26.0.0`, `compatibleSdkVersion 6.1.1(24)`.
- Connected emulator observed: Pura 90 image `6.1.0.117`, API 24.

Live-source snapshot hashes used for the static review:

```text
248cd4661ce06865ef2ef20b3f58cb1c500a6d6b23c602099c407381f3a99b49  labs/ohos_cjgui_app/entry/src/main/ets/entryability/EntryAbility.ets
daaab06a25103c5b1de32c30ac04e577fec933bbc519b806512dc90a217ab1ea  labs/ohos_cjgui_app/entry/src/main/ets/pages/Index.ets
ce0bc89c1fb098de5df60410c6595de9feb1b59cca6950e9d2b7b8be48469a66  labs/ohos_cjgui_app/entry/src/main/cpp/cjgui_host_bridge.cpp
ab5b3d64141b8e3849ec4275dffa2ecfebbb23395d218c1e327405d54e06153d  labs/ohos_cjgui_app/entry/src/main/cpp/ohos_renderer.cpp
015c660e674fb99b4493046b9e252530eb99973af0b3826940011c457f7ea9ba  labs/ohos_cjgui_app/entry/src/main/cangjie/ohos_app.cj
cdaa43303f2c0abcb193b0dd056301d5d3ab9216b513804d3fc4644c7c6e2b07  labs/ohos_cangjie_smoke/entry/src/main/cangjie/main_ability.cj
3aef0ab64eefe9cf10d4755ae81bc60f8031f0e937a06a99fd55fe864f193205  labs/ohos_cangjie_smoke/entry/src/main/cangjie/index.cj
```

See `experiments.md` for exact changes and outcomes. Laya evidence is kept as
request, response, and adoption files; it is advisory classification evidence,
not technical acceptance.

Concurrency note: the active implementer replaced the earlier
`ohos_probe.cj` with `ohos_app.cj` while this review was running. The final
static conclusions use the newer file. The 12:32/12:35 HAP and screenshot are
labeled A1 probe evidence. Newer HAPs were built and installed during the
review. The implementer fixed the missing runtime library and the mangled
`cjgui_ohos_surface_ready`; at the 13:01 cutoff loading had advanced to the
unresolved macOS native-bridge closure in `libcjgui.so`. The newer HAP is still
build/package proof, not owner-loop or E2E proof.
