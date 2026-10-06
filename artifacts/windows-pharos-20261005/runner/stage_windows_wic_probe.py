#!/usr/bin/env python3
"""Freeze the canonical Windows WIC decoder and independent pixel fixture."""
from __future__ import annotations

import hashlib
import json
import pathlib
import zipfile

ROOT = pathlib.Path('/Users/jiangxuanyang/Desktop/cangjie')
ARTIFACTS = ROOT / 'artifacts/windows-pharos-20261005'
STAGE = ARTIFACTS / 'runner/staging/windows-wic-probe'
ZIP = ARTIFACTS / 'guest-transfer/windows-wic-probe.zip'
MANIFEST = ARTIFACTS / 'windows-wic-probe-manifest.json'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    sources = [
        (ROOT / 'runtime/cjgui/platforms/windows/native/cjgui_windows_wic.h',
         'native/cjgui_windows_wic.h'),
        (ROOT / 'runtime/cjgui/platforms/windows/native/cjgui_windows_wic.c',
         'native/cjgui_windows_wic.c'),
        (ARTIFACTS / 'wic-probe/wic_png_probe.c', 'probe/wic_png_probe.c'),
        (ARTIFACTS / 'wic-probe/asymmetric-rgba.png', 'fixture/asymmetric-rgba.png'),
    ]
    STAGE.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, object]] = []
    for source, destination in sources:
        data = source.read_bytes()
        target = STAGE / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        entries.append({
            'source': str(source),
            'destination': destination,
            'bytes': len(data),
            'sha256': sha(data),
        })
    manifest = {
        'schema': 'windows-pharos-wic-probe-v1',
        'target': 'x86_64-w64-mingw32 (Windows 11 ARM64 guest, x64 emulation)',
        'pixel_oracle_rgba8_hex': 'FF0000FF00FF00FF0000FFFF00000000FF00FF8000FFFF40',
        'files': entries,
    }
    (STAGE / 'source-manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with zipfile.ZipFile(ZIP, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        for path in sorted(STAGE.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(STAGE).as_posix())
    output = {
        'archive': str(ZIP),
        'archive_bytes': ZIP.stat().st_size,
        'archive_sha256': sha(ZIP.read_bytes()),
        'manifest': str(MANIFEST),
        'files': entries,
        'pixel_oracle_rgba8_hex': manifest['pixel_oracle_rgba8_hex'],
    }
    MANIFEST.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: output[key] for key in (
        'archive', 'archive_bytes', 'archive_sha256', 'pixel_oracle_rgba8_hex')},
        ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
