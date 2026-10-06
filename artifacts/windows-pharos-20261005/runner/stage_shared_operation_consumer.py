#!/usr/bin/env python3
"""Freeze canonical shared-operation sources and the Windows TCP owner consumer."""
from __future__ import annotations

import hashlib
import json
import pathlib
import shutil
import zipfile

ROOT = pathlib.Path('/Users/jiangxuanyang/Desktop/cangjie')
ARTIFACTS = ROOT / 'artifacts/windows-pharos-20261005'
CORE = ROOT / 'runtime/cjgui/shared_operation_core'
STAGE = ARTIFACTS / 'runner/staging/shared-operation-consumer'
CONSUMER = STAGE / 'transport-probe'
CANONICAL_CONSUMER = ARTIFACTS / 'transport-probe/src/main.cj'
ZIP = ARTIFACTS / 'guest-transfer/shared-operation-consumer.zip'
MANIFEST = ARTIFACTS / 'shared-operation-consumer-manifest.json'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    main_source = CANONICAL_CONSUMER
    if not main_source.is_file():
        raise SystemExit(f'missing_consumer_source:{main_source}')
    consumer_bytes = main_source.read_bytes()
    shutil.rmtree(STAGE, ignore_errors=True)
    CORE_DST = STAGE / 'runtime/cjgui/shared_operation_core'
    (CORE_DST / 'src').mkdir(parents=True)
    CONSUMER_DST = STAGE / 'transport-probe'
    (CONSUMER_DST / 'src').mkdir(parents=True)

    files: list[dict[str, object]] = []

    def copy(source: pathlib.Path, destination: pathlib.Path, relative: str) -> None:
        data = source.read_bytes()
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        files.append({
            'source': str(source),
            'relative': relative,
            'bytes': len(data),
            'sha256': sha(data),
        })

    copy(CORE / 'cjpm.toml', CORE_DST / 'cjpm.toml', 'runtime/cjgui/shared_operation_core/cjpm.toml')
    for source in sorted((CORE / 'src').glob('*.cj')):
        if source.name.endswith('_test.cj'):
            continue
        copy(source, CORE_DST / 'src' / source.name,
             f'runtime/cjgui/shared_operation_core/src/{source.name}')
    copy(ROOT / 'artifacts/windows-pharos-20261005/transport-probe/cjpm.toml',
         CONSUMER_DST / 'cjpm.toml', 'transport-probe/cjpm.toml')
    (CONSUMER_DST / 'src/main.cj').write_bytes(consumer_bytes)
    files.append({
        'source': str(main_source),
        'relative': 'transport-probe/src/main.cj',
        'bytes': len(consumer_bytes),
        'sha256': sha(consumer_bytes),
    })
    manifest = {
        'schema': 'windows-pharos-shared-operation-consumer-v1',
        'target': 'x86_64-w64-mingw32 (Windows 11 ARM64 guest, x64 emulation)',
        'source_policy': 'All shared core sources are byte-identical to canonical source; transport-probe is the standalone public-client consumer.',
        'files': files,
    }
    STAGE.mkdir(parents=True, exist_ok=True)
    (STAGE / 'source-manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    ZIP.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ZIP, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        for path in sorted(STAGE.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(STAGE).as_posix())
    output = {
        'staging': str(STAGE),
        'archive': str(ZIP),
        'archive_bytes': ZIP.stat().st_size,
        'archive_sha256': sha(ZIP.read_bytes()),
        'source_files': len(files),
        'source_bytes': sum(int(item['bytes']) for item in files),
        'source_manifest': str(MANIFEST),
        'files': files,
    }
    MANIFEST.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: output[key] for key in (
        'staging', 'archive', 'archive_bytes', 'archive_sha256', 'source_files', 'source_bytes')},
        ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
