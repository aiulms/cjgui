#!/usr/bin/env python3
"""Stage the existing Pharos owner and shared packages for a Windows x64 guest build."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import zipfile

ROOT = pathlib.Path('/Users/jiangxuanyang/Desktop/cangjie')
PHAROS = pathlib.Path('/Users/jiangxuanyang/Desktop/Pharos Mark')
ARTIFACTS = ROOT / 'artifacts/windows-pharos-20261005'
# 隔离 run 用 stem 参数化输出位置（默认与旧固定路径一致，避免旧批次行为变化）。
STAGE_BASE = ARTIFACTS / 'staging'
TRANSFER_BASE = ARTIFACTS / 'guest-transfer'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def add_source(entries: list[dict[str, object]], stage: pathlib.Path,
              source: pathlib.Path, destination: pathlib.Path) -> None:
    data = source.read_bytes()
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    entries.append({
        'source': str(source),
        'destination': str(destination.relative_to(stage)),
        'size': len(data),
        'sha256': sha(data),
    })


def main(stem: str = 'pharos-windows-source') -> None:
    stage = STAGE_BASE / stem
    out_zip = TRANSFER_BASE / (stem + '.zip')
    if stage.exists():
        shutil.rmtree(stage)
    stage.mkdir(parents=True)
    entries: list[dict[str, object]] = []

    source_set_script = ROOT / 'runtime/cjgui/native/scripts/lib_cjgui_source_set.sh'
    # R7 混合基线模式（环境变量开启，默认关闭以保持旧批次行为不变）：
    # 阶段页第 4 轮定位到 live cjgui 全量在 Windows 目标下触发 Cangjie 编译器崩溃
    # （0xC0000005，早于 llc，llc 从未被调用），而 R6 冻结 cjgui 可编过；且单独叠加
    # live 的 runtime_renderer_session.cj / text_selection_authority.cj 都能在 R6 基线上
    # 编过。因此 Windows 交付输入用"R6 冻结 cjgui + R7 必需的 live 文件"，
    # 而不是把 E/H 在途改动整树带进 Windows 目标。
    base_root_early = os.environ.get('PHAROS_R7_BASE', '')
    cjgui_base = os.environ.get('PHAROS_R7_CJGUI_BASE', '') or (
        str(pathlib.Path(base_root_early) / 'runtime/cjgui') if base_root_early else '')
    live_override = [n for n in os.environ.get('PHAROS_R7_CJGUI_LIVE', '').split(',') if n]
    live_extra = [n for n in os.environ.get('PHAROS_R7_CJGUI_EXTRA', '').split(',') if n]
    if cjgui_base:
        base_dir = pathlib.Path(cjgui_base)
        names = sorted(p.name for p in (base_dir / 'src').glob('*.cj'))
        # 本包新增的最小应用宿主接口（R6 基线里没有）：它只含接口与两个平台的包级停止入口，
        # 平台相关部分由 @When 各自生效，纳入 Windows 源集后普通消费者才能只依赖这一份公共面。
        if ('application_host.cj' not in names
                and (ROOT / 'runtime/cjgui/src/application_host.cj').is_file()):
            names.append('application_host.cj')
            names = sorted(names)
        names = [n for n in names if n not in live_extra]
        override_dir = os.environ.get('PHAROS_R7_CJGUI_OVERRIDE_DIR', '')
        for name in names:
            if name in live_override:
                candidate = (pathlib.Path(override_dir) / name) if override_dir else None
                source = candidate if (candidate is not None and candidate.is_file()) else (ROOT / 'runtime/cjgui/src' / name)
            else:
                source = base_dir / 'src' / name
            add_source(entries, stage, source, stage / 'runtime/cjgui/src' / name)
        for name in live_extra:
            add_source(entries, stage, ROOT / 'runtime/cjgui/src' / name,
                       stage / 'runtime/cjgui/src' / name)
        names = names + live_extra
    else:
        names = subprocess.run(
            ['zsh', '-c', f'source {source_set_script}; cjgui_framework_source_names true'],
            check=True, capture_output=True, text=True,
        ).stdout.splitlines()
        for name in names:
            add_source(entries, stage, ROOT / 'runtime/cjgui/src' / name,
                       stage / 'runtime/cjgui/src' / name)
    # R7 基线模式：Windows 交付输入 = R6 冻结源 + live 新增模块 + 逐文件 override。
    # 动机（阶段页第 4/5 轮）：live 的若干既有文件在 Windows 目标下触发 Cangjie 编译器
    # 崩溃（已定位 composable_ui_window.cj、pharos_editor_surface/surface.cj），而 R6 冻结
    # 版可编过；本包真正改过的文件用 override 换入。
    base_root = os.environ.get('PHAROS_R7_BASE', '')
    overrides = {o for o in os.environ.get('PHAROS_R7_OVERRIDE', '').split(',') if o}
    base_path = pathlib.Path(base_root) if base_root else None
    # 严格基线：源集只取 R6 冻结文件（不含 live 新增模块），用于判别崩溃来自
    # "live 新增模块/本包 override" 还是 "cjgui 侧混合"。
    strict_base = bool(os.environ.get('PHAROS_R7_STRICT_BASE'))


    def native_src(rel: str) -> pathlib.Path:
        """native 侧可选地取基线（用于复现 R6 的完整构建输入）。"""
        if base_path is not None and os.environ.get('PHAROS_R7_BASE_NATIVE'):
            cand = base_path / 'runtime/cjgui' / rel
            if cand.is_file():
                return cand
        return ROOT / 'runtime/cjgui' / rel

    # 本包 override 的**源目录**：早期版本在 override 时直接取 live 树的文件，导致
    # r7-overrides-*/ 里为 Windows 目标准备好的文件（如 "R6 基线 + 本包 14 块" 的
    # main.cj）从未被打包（第 35 轮定位：EXE 里其实是 R6 的 main.cj）。
    override_root_env = os.environ.get('PHAROS_R7_OVERRIDE_ROOT', '')
    override_root = pathlib.Path(override_root_env) if override_root_env else None

    def pick(rel: str, base_file: pathlib.Path, live_file: pathlib.Path) -> pathlib.Path:
        if base_path is None:
            return live_file
        if rel in overrides:
            if override_root is not None:
                cand = override_root / rel
                if cand.is_file():
                    return cand
            return live_file
        return base_file if base_file.is_file() else live_file

    sh_base = (base_path / 'runtime/cjgui/shared_operation_core/src') if base_path else None
    sh_live = ROOT / 'runtime/cjgui/shared_operation_core/src'
    if strict_base and sh_base:
        sh_names = sorted(p.name for p in sh_base.glob('*.cj'))
    else:
        sh_names = sorted({p.name for p in sh_live.glob('*.cj')} |
                          ({p.name for p in sh_base.glob('*.cj')} if sh_base else set()))
    for name in sh_names:
        if name.endswith('_test.cj'):
            continue
        rel = f'runtime/cjgui/shared_operation_core/src/{name}'
        source = pick(rel, (sh_base / name) if sh_base else sh_live / name, sh_live / name)
        add_source(entries, stage, source, stage / rel)
    # 第二消费者（普通范围消费者）：runtime/cjgui/examples/range_text_window_app。
    # 它的 Windows cjpm.toml 由 override 提供（去掉 AppKit/Metal，改用 Windows 系统库）。
    app_rel = 'runtime/cjgui/examples/range_text_window_app'
    app_dir = ROOT / app_rel
    if app_dir.is_dir():
        for f in sorted(app_dir.rglob('*')):
            if not f.is_file():
                continue
            rel_f = f.relative_to(app_dir)
            if ('target' in rel_f.parts or 'build-script-cache' in rel_f.parts
                    or '.cjgui' in rel_f.parts
                    or f.name in ('cjpm.lock', 'run.sh', 'cjgui_macos_app.sh')
                    or f.suffix in ('.cjo', '.a', '.o', '.exe')):
                continue
            ov = (override_root / app_rel / rel_f) if override_root is not None else None
            src = ov if (ov is not None and ov.is_file()) else f
            add_source(entries, stage, src, stage / app_rel / rel_f)
    for name in ('cjgui_windows_wic.h', 'cjgui_windows_wic.c'):
        source = native_src('platforms/windows/native/' + name)
        add_source(entries, stage, source, stage / 'runtime/cjgui/platforms/windows/native' / name)
    # Windows POSIX 垫片（fsync/pread/renameat）随框架原生库一起编译。
    add_source(entries, stage, native_src('platforms/windows/native/cjgui_windows_posix_compat.c'),
               stage / 'runtime/cjgui/platforms/windows/native/cjgui_windows_posix_compat.c')
    # 应用清单：activeCodePage=UTF-8。Cangjie Windows 运行时按 ANSI 代码页解码
    # argv；zh-CN(936) 下非 ASCII 路径会变成 GBK 字节而被 fromUtf8 拒绝，该清单
    # 令进程 ACP 变为 UTF-8（与 macOS 行为对齐）。prepare 用 windres 编成 .res
    # 并作为链接输入（见 app manifest link-option）。
    for name in ('pharos_windows_app.manifest', 'pharos_windows_app.rc'):
        add_source(entries, stage, native_src('platforms/windows/native/' + name),
                   stage / 'runtime/cjgui/platforms/windows/native' / name)
    # Pharos 应用原生支持（Agent 通道/计时/进程等真实实现 + macOS 诊断具名拒绝），
    # 由 guest prepare 编进应用包自有 native lib（见 prepare-source 批次）。
    add_source(entries, stage, native_src('platforms/windows/native/pharos_windows_app_support.c'),
               stage / 'apps/pharos_mark/native/pharos_windows_app_support.c')
    for name in ('cjgui_internal_renderer.h',):
        source = native_src('native/' + name)
        add_source(entries, stage, source, stage / 'runtime/cjgui/native' / name)
    for name in ('cjgui_windows_renderer.c',):
        source = native_src('platforms/windows/native/' + name)
        add_source(entries, stage, source, stage / 'runtime/cjgui/platforms/windows/native' / name)

    package_names = ('document_core', 'markdown_engine', 'app_services', 'editor_surface')
    package_src_names: dict[str, list[str]] = {}
    for package in package_names:
        live_dir = PHAROS / 'packages' / package / 'src'
        base_dir = (base_path / 'packages' / package / 'src') if base_path else None
        if strict_base and base_dir:
            names_in_package = sorted(p.name for p in base_dir.glob('*.cj'))
        else:
            names_in_package = sorted({p.name for p in live_dir.glob('*.cj')} |
                                      ({p.name for p in base_dir.glob('*.cj')} if base_dir else set()))
        names_in_package = [n for n in names_in_package if not n.endswith('_test.cj')]
        package_src_names[package] = names_in_package
        for name in names_in_package:
            rel = f'packages/{package}/src/{name}'
            source = pick(rel, (base_dir / name) if base_dir else live_dir / name, live_dir / name)
            add_source(entries, stage, source, stage / rel)
    live_app_dir = PHAROS / 'apps/pharos_mark/src'
    base_app_dir = (base_path / 'apps/pharos_mark/src') if base_path else None
    if strict_base and base_app_dir:
        app_source_names = sorted(p.name for p in base_app_dir.glob('*.cj'))
    else:
        app_source_names = sorted({p.name for p in live_app_dir.glob('*.cj')} |
                                  ({p.name for p in base_app_dir.glob('*.cj')} if base_app_dir else set()))
    app_source_names = [n for n in app_source_names if not n.endswith('_test.cj')]
    for name in app_source_names:
        rel = f'apps/pharos_mark/src/{name}'
        source = pick(rel, (base_app_dir / name) if base_app_dir else live_app_dir / name, live_app_dir / name)
        add_source(entries, stage, source, stage / rel)

    manifests = {
        'runtime/cjgui/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui"\nversion = "0.0.0"\noutput-type = "static"\nsrc-dir = "src"\nlink-option = "--gc-sections -ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -luuid -luser32 -lgdi32 -limm32 -ladvapi32 -lole32 -lwindowscodecs"\n\n[dependencies]\ncjgui_shared_operation_core = { path = "./shared_operation_core" }\n\n[ffi.c]\ncjgui_internal_renderer = { path = "./native/lib" }\n''',
        'runtime/cjgui/shared_operation_core/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "cjgui_shared_operation_core"\nversion = "0.0.0"\noutput-type = "static"\nsrc-dir = "src"\n''',
        'packages/document_core/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_document_core"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n''',
        'packages/markdown_engine/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_markdown_engine"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n\n[dependencies]\npharos_document_core = { path = "../document_core" }\n''',
        'packages/app_services/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_app_services"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n\n[dependencies]\npharos_document_core = { path = "../document_core" }\npharos_markdown_engine = { path = "../markdown_engine" }\ncjgui_shared_operation_core = { path = "../../runtime/cjgui/shared_operation_core" }\n''',
        'packages/editor_surface/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_editor_surface"\nversion = "1.0.0"\noutput-type = "static"\nsrc-dir = "src"\n\n[dependencies]\npharos_document_core = { path = "../document_core" }\npharos_markdown_engine = { path = "../markdown_engine" }\npharos_app_services = { path = "../app_services" }\ncjgui = { path = "../../runtime/cjgui" }\n''',
        'runtime/cjgui/examples/range_text_window_app/cjpm.toml': '[package]\ncjc-version = "1.1.3"\nname = "cjgui_range_text_window_app"\nversion = "0.0.0"\noutput-type = "executable"\nsrc-dir = "src"\ncompile-option = "-O1"\nlink-option = "--gc-sections -ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -limm32 -luuid -luser32 -lgdi32 -ladvapi32 -lole32 -lwindowscodecs"\n\n[dependencies]\ncjgui = { path = "../.." }\n\n[ffi.c]\ncjgui_internal_renderer = { path = "./.cjgui/native/lib" }\n',
        'apps/pharos_mark/cjpm.toml': '''[package]\ncjc-version = "1.1.3"\nname = "pharos_mark"\nversion = "0.1.0"\noutput-type = "executable"\nsrc-dir = "src"\nlink-option = "--gc-sections -ld3d11 -ld3dcompiler -ldxgi -ldxguid -ldwrite -limm32 -luuid -luser32 -lgdi32 -ladvapi32 -lole32 -lwindowscodecs -lws2_32 -lpsapi -ldwmapi pharos-windows-manifest.res"\n\n[dependencies]\ncjgui = { path = "../../runtime/cjgui" }\npharos_document_core = { path = "../../packages/document_core" }\npharos_app_services = { path = "../../packages/app_services" }\npharos_editor_surface = { path = "../../packages/editor_surface" }\npharos_markdown_engine = { path = "../../packages/markdown_engine" }\ncjgui_shared_operation_core = { path = "../../runtime/cjgui/shared_operation_core" }\n\n[ffi.c]\npharos_windows_support = { path = "./native/lib" }\n''',
    }
    for relative, contents in manifests.items():
        path = stage / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding='utf-8', newline='\n')

    for entry in entries:
        source = pathlib.Path(str(entry['source']))
        if sha(source.read_bytes()) != entry['sha256']:
            raise RuntimeError('source_changed_during_staging:' + str(source))

    manifest = {
        'schema': 'pharos-windows-x64-canonical-source-v1',
        'stem': stem,
        'target': 'x86_64-w64-mingw32 (Windows ARM64 guest, x64 emulation)',
        'source_policy': 'Every listed Cangjie source is byte-identical to its canonical owner file when packaged.',
        'source_set_manifest': str(source_set_script),
        'cjgui_source_names': names,
        'pharos_package_source_names': package_src_names,
        'pharos_app_source_names': app_source_names,
        'generated_manifests': {rel: sha(contents.encode()) for rel, contents in manifests.items()},
        'files': entries,
    }
    (stage / 'source-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    out_zip.unlink(missing_ok=True)
    with zipfile.ZipFile(out_zip, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        for path in sorted(stage.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(stage).as_posix())
    print(json.dumps({
        'staging': str(stage),
        'archive': str(out_zip),
        'archive_sha256': sha(out_zip.read_bytes()),
        'source_file_count': len(entries),
        'source_bytes': sum(int(item['size']) for item in entries),
        'package_source_counts': {key: len(value) for key, value in package_src_names.items()},
        'pharos_main_sha256': next(e['sha256'] for e in entries if e['destination'] == 'apps/pharos_mark/src/main.cj'),
        'pharos_app_source_count': len(app_source_names),
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--stem', default='pharos-windows-source')
    main(**vars(parser.parse_args()))
