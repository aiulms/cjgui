#!/usr/bin/env python3
"""Stage the existing Pharos owner and shared packages for a Windows x64 guest build."""
from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import subprocess
import zipfile

ROOT = pathlib.Path('/Users/jiangxuanyang/Desktop/cangjie')
PHAROS = pathlib.Path('/Users/jiangxuanyang/Desktop/Pharos Mark')
ARTIFACTS = ROOT / 'artifacts/windows-pharos-20261005'
STAGE = ARTIFACTS / 'staging/pharos-windows-source'
ZIP = ARTIFACTS / 'guest-transfer/pharos-windows-source.zip'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def add_source(entries: list[dict[str, object]], source: pathlib.Path, destination: pathlib.Path) -> None:
    data = source.read_bytes()
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    entries.append({
        'source': str(source),
        'destination': str(destination.relative_to(STAGE)),
        'size': len(data),
        'sha256': sha(data),
    })


def main() -> None:
    if STAGE.exists():
        shutil.rmtree(STAGE)
    STAGE.mkdir(parents=True)
    entries: list[dict[str, object]] = []

    source_set_script = ROOT / 'runtime/cjgui/native/scripts/lib_cjgui_source_set.sh'
    names = subprocess.run(
        ['zsh', '-c', f'source {source_set_script}; cjgui_framework_source_names true'],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines()
    for name in names:
        add_source(entries, ROOT / 'runtime/cjgui/src' / name,
                   STAGE / 'runtime/cjgui/src' / name)
    for source in sorted((ROOT / 'runtime/cjgui/shared_operation_core/src').glob('*.cj')):
        if not source.name.endswith('_test.cj'):
            add_source(entries, source, STAGE / 'runtime/cjgui/shared_operation_core/src' / source.name)
    for name in ('cjgui_windows_wic.h', 'cjgui_windows_wic.c'):
        source = ROOT / 'runtime/cjgui/platforms/windows/native' / name
        add_source(entries, source, STAGE / 'runtime/cjgui/platforms/windows/native' / name)
    # Windows POSIX 垫片（fsync/pread/renameat）随框架原生库一起编译。
    add_source(entries, ROOT / 'runtime/cjgui/platforms/windows/native/cjgui_windows_posix_compat.c',
               STAGE / 'runtime/cjgui/platforms/windows/native/cjgui_windows_posix_compat.c')
    # 应用清单：activeCodePage=UTF-8。Cangjie Windows 运行时按 ANSI 代码页解码
    # argv；zh-CN(936) 下非 ASCII 路径会变成 GBK 字节而被 fromUtf8 拒绝，该清单
    # 令进程 ACP 变为 UTF-8（与 macOS 行为对齐）。prepare 用 windres 编成 .res
    # 并作为链接输入（见 app manifest link-option）。
    for name in ('pharos_windows_app.manifest', 'pharos_windows_app.rc'):
        add_source(entries, ROOT / 'runtime/cjgui/platforms/windows/native' / name,
                   STAGE / 'runtime/cjgui/platforms/windows/native' / name)
    # Pharos 应用原生支持（Agent 通道/计时/进程等真实实现 + macOS 诊断具名拒绝），
    # 由 guest prepare 编进应用包自有 native lib（见 prepare-source 批次）。
    add_source(entries, ROOT / 'runtime/cjgui/platforms/windows/native/pharos_windows_app_support.c',
               STAGE / 'apps/pharos_mark/native/pharos_windows_app_support.c')
    for name in ('cjgui_internal_renderer.h',):
        source = ROOT / 'runtime/cjgui/native' / name
        add_source(entries, source, STAGE / 'runtime/cjgui/native' / name)
    for name in ('cjgui_windows_renderer.c',):
        source = ROOT / 'runtime/cjgui/platforms/windows/native' / name
        add_source(entries, source, STAGE / 'runtime/cjgui/platforms/windows/native' / name)

    package_names = ('document_core', 'markdown_engine', 'app_services', 'editor_surface')
    package_src_names: dict[str, list[str]] = {}
    for package in package_names:
        source_dir = PHAROS / 'packages' / package / 'src'
        names_in_package = sorted(p.name for p in source_dir.glob('*.cj') if not p.name.endswith('_test.cj'))
        package_src_names[package] = names_in_package
        for name in names_in_package:
            add_source(entries, source_dir / name, STAGE / 'packages' / package / 'src' / name)
    app_source_dir = PHAROS / 'apps/pharos_mark/src'
    app_source_names = sorted(p.name for p in app_source_dir.glob('*.cj') if not p.name.endswith('_test.cj'))
    for name in app_source_names:
        add_source(entries, app_source_dir / name, STAGE / 'apps/pharos_mark/src' / name)

    manifests = {
        'runtime/cjgui/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui"\nversion = "0.0.0"\noutput-type = "static"\nsrc-dir = "src"\nlink-option = "--gc-sections -ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -luuid -luser32 -lgdi32 -limm32 -ladvapi32 -lole32 -lwindowscodecs"\n\n[dependencies]\ncjgui_shared_operation_core = { path = "./shared_operation_core" }\n\n[ffi.c]\ncjgui_internal_renderer = { path = "./native/lib" }\n''',
        'runtime/cjgui/shared_operation_core/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui_shared_operation_core"\nversion = "0.0.0"\noutput-type = "static"\nsrc-dir = "src"\n''',
        'packages/document_core/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_document_core"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n''',
        'packages/markdown_engine/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_markdown_engine"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n\n[dependencies]\npharos_document_core = { path = "../document_core" }\n''',
        'packages/app_services/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_app_services"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n\n[dependencies]\npharos_document_core = { path = "../document_core" }\npharos_markdown_engine = { path = "../markdown_engine" }\ncjgui_shared_operation_core = { path = "../../runtime/cjgui/shared_operation_core" }\n''',
        'packages/editor_surface/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_editor_surface"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n\n[dependencies]\npharos_document_core = { path = "../document_core" }\npharos_markdown_engine = { path = "../markdown_engine" }\npharos_app_services = { path = "../app_services" }\ncjgui = { path = "../../runtime/cjgui" }\n''',
        'apps/pharos_mark/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_mark"\nversion = "0.1.0"\noutput-type = "executable"\nsrc-dir = "src"\nlink-option = "--gc-sections -ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -limm32 -luuid -luser32 -lgdi32 -ladvapi32 -lole32 -lwindowscodecs -lws2_32 -lpsapi -ldwmapi pharos-windows-manifest.res"\n\n[dependencies]\ncjgui = { path = "../../runtime/cjgui" }\npharos_document_core = { path = "../../packages/document_core" }\npharos_app_services = { path = "../../packages/app_services" }\npharos_editor_surface = { path = "../../packages/editor_surface" }\npharos_markdown_engine = { path = "../../packages/markdown_engine" }\ncjgui_shared_operation_core = { path = "../../runtime/cjgui/shared_operation_core" }\n\n[ffi.c]\npharos_windows_support = { path = "./native/lib" }\n''',
    }
    for relative, contents in manifests.items():
        path = STAGE / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding='utf-8', newline='\n')

    for entry in entries:
        source = pathlib.Path(str(entry['source']))
        if sha(source.read_bytes()) != entry['sha256']:
            raise RuntimeError('source_changed_during_staging:' + str(source))

    manifest = {
        'schema': 'pharos-windows-x64-canonical-source-v1',
        'target': 'x86_64-w64-mingw32 (Windows ARM64 guest, x64 emulation)',
        'source_policy': 'Every listed Cangjie source is byte-identical to its canonical owner file when packaged.',
        'source_set_manifest': str(source_set_script),
        'cjgui_source_names': names,
        'pharos_package_source_names': package_src_names,
        'pharos_app_source_names': app_source_names,
        'generated_manifests': {rel: sha(contents.encode()) for rel, contents in manifests.items()},
        'files': entries,
    }
    (STAGE / 'source-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    ZIP.parent.mkdir(parents=True, exist_ok=True)
    ZIP.unlink(missing_ok=True)
    with zipfile.ZipFile(ZIP, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        for path in sorted(STAGE.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(STAGE).as_posix())
    print(json.dumps({
        'staging': str(STAGE),
        'archive': str(ZIP),
        'archive_sha256': sha(ZIP.read_bytes()),
        'source_file_count': len(entries),
        'source_bytes': sum(int(item['size']) for item in entries),
        'package_source_counts': {key: len(value) for key, value in package_src_names.items()},
        'pharos_main_sha256': next(e['sha256'] for e in entries if e['destination'] == 'apps/pharos_mark/src/main.cj'),
        'pharos_app_source_count': len(app_source_names),
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
