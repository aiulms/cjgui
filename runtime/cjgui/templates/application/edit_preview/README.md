# Linux edit + preview starter

An opt-in Linux composition created with:

```sh
platforms/linux/scripts/create_linux_application.sh edit-preview ../my-app
```

It is a thin consumer of existing framework assets, not a second platform
stack:

- one `CjguiNotificationThresholdDomain` owner shared by both windows;
- one `CjguiLinuxApplicationHostGroup` serialized owner loop;
- the same `CjguiFontResourceRegistry` leases and generated-UI region used by
  the handwritten and generated sections;
- `linux_application.py` build/package/run and the existing manifest format.

The main window edits the draft; the preview window renders the same draft with
handwritten styled runs and the runtime-generated label. Preview open/close,
font-generation switch and the external owner protocol are already wired.

Window lifecycle contract: each preview window owns its controller and
generated region (the domain and font registry stay shared), and button-driven
open/close requests are settled at the group turn boundary — creating or
destroying a second window re-entrantly inside another window's event dispatch
corrupts the native session state, so `OPEN_PREVIEW` acknowledges immediately
and the window appears one turn later. The host reference is kept until the
window confirmed its discard; submitted candidates settle through the window's
own close path.

`ui-only` remains the default lightweight starter and does not copy these
sources, fonts or the preview loop.

Build and run (Linux):

```sh
CJGUI_CANGJIE_TOOLCHAIN=/path/to/envsetup.sh ./run.sh
```

Package:

```sh
CJGUI_CANGJIE_TOOLCHAIN=/path/to/envsetup.sh ./run.sh package /tmp/my-app.tar.gz
```
