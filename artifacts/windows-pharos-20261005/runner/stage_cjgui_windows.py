#!/usr/bin/env python3
"""Create a hash-verified Windows staging package from canonical CJGUI sources."""
from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import subprocess
import zipfile

ROOT = pathlib.Path('/Users/jiangxuanyang/Desktop/cangjie')
ARTIFACTS = ROOT / 'artifacts/windows-pharos-20261005'
RUNTIME = ROOT / 'runtime/cjgui'
STAGE = ARTIFACTS / 'staging/cjgui-windows'
ZIP = ARTIFACTS / 'guest-transfer/cjgui-windows-source.zip'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def add_source(entries: list[dict[str, object]], source: pathlib.Path, destination: pathlib.Path) -> None:
    data = source.read_bytes()
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    entries.append({
        'source': str(source.relative_to(ROOT)),
        'destination': str(destination.relative_to(STAGE)),
        'size': len(data),
        'sha256': sha(data),
    })


def main() -> None:
    if STAGE.exists():
        shutil.rmtree(STAGE)
    STAGE.mkdir(parents=True)
    names = subprocess.run(
        ['zsh', '-c', f'source {RUNTIME / "native/scripts/lib_cjgui_source_set.sh"}; cjgui_framework_source_names true'],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines()
    entries: list[dict[str, object]] = []
    for name in names:
        add_source(entries, RUNTIME / 'src' / name, STAGE / 'runtime/cjgui/src' / name)
    core_source = RUNTIME / 'shared_operation_core/src'
    core_names = sorted(p.name for p in core_source.glob('*.cj') if not p.name.endswith('_test.cj'))
    for name in core_names:
        add_source(entries, core_source / name, STAGE / 'runtime/cjgui/shared_operation_core/src' / name)

    windows_native = RUNTIME / 'platforms/windows/native'
    for name in ('cjgui_windows_wic.h', 'cjgui_windows_wic.c', 'cjgui_windows_renderer.c'):
        add_source(entries, windows_native / name, STAGE / 'runtime/cjgui/platforms/windows/native' / name)
    add_source(entries, RUNTIME / 'native/cjgui_internal_renderer.h',
               STAGE / 'runtime/cjgui/native/cjgui_internal_renderer.h')
    add_source(entries, ARTIFACTS / 'renderer-contract/cjgui_windows_scene_contract.c',
               STAGE / 'renderer-contract/cjgui_windows_scene_contract.c')
    add_source(entries, ARTIFACTS / 'renderer-contract/cjgui_windows_geometry_budget_contract.c',
               STAGE / 'renderer-contract/cjgui_windows_geometry_budget_contract.c')
    add_source(entries, ARTIFACTS / 'renderer-contract/cjgui_windows_grapheme_contract.c',
               STAGE / 'renderer-contract/cjgui_windows_grapheme_contract.c')
    add_source(entries, ARTIFACTS / 'renderer-contract/cjgui_windows_input_contract.c',
               STAGE / 'renderer-contract/cjgui_windows_input_contract.c')
    add_source(entries, ARTIFACTS / 'renderer-contract/cjgui_windows_source_install_contract.c',
               STAGE / 'renderer-contract/cjgui_windows_source_install_contract.c')

    manifests = {
        'runtime/cjgui/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui"\nversion = "0.0.0"\nsrc-dir = "src"\noutput-type = "static"\nlink-option = "--gc-sections -ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -luuid -luser32 -lgdi32 -limm32 -ladvapi32 -lole32 -lwindowscodecs"\n\n[dependencies]\ncjgui_shared_operation_core = { path = "./shared_operation_core" }\n\n[ffi.c]\ncjgui_internal_renderer = { path = "./native/lib" }\n''',
        'runtime/cjgui/shared_operation_core/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui_shared_operation_core"\nversion = "0.0.0"\noutput-type = "static"\nsrc-dir = "src"\n''',
        'window-link-probe/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui_windows_link_probe"\nversion = "0.1.0"\noutput-type = "executable"\nlink-option = "--gc-sections"\n\n[dependencies]\ncjgui = { path = "../runtime/cjgui" }\n''',
    }
    for rel, contents in manifests.items():
        (STAGE / rel).parent.mkdir(parents=True, exist_ok=True)
        (STAGE / rel).write_text(contents, encoding='utf-8', newline='\n')
    add_source(entries, ARTIFACTS / 'wic-probe/cjgui_window_link_probe.cj',
               STAGE / 'window-link-probe/src/main.cj')
    manifest = {
        'schema': 'windows-pharos-cjgui-source-stage-v1',
        'target': 'x86_64-w64-mingw32 (Windows x64 guest/emulation)',
        'source_policy': 'Every listed CJGUI/shared core .cj source is byte-identical to canonical source at generation time.',
        'source_set_manifest': str((RUNTIME / 'native/scripts/lib_cjgui_source_set.sh').relative_to(ROOT)),
        'source_set_names': names,
        'shared_operation_core_sources': core_names,
        'generated_manifests': {rel: sha(contents.encode()) for rel, contents in manifests.items()},
        'files': entries,
    }
    (STAGE / 'source-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    ZIP.parent.mkdir(parents=True, exist_ok=True)
    if ZIP.exists():
        ZIP.unlink()
    with zipfile.ZipFile(ZIP, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        for path in sorted(STAGE.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(STAGE).as_posix())
    print(json.dumps({
        'staging': str(STAGE),
        'archive': str(ZIP),
        'archive_sha256': sha(ZIP.read_bytes()),
        'source_files': len(entries),
        'source_bytes': sum(int(item['size']) for item in entries),
        'cjgui_source_names': names,
        'core_source_names': core_names,
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
