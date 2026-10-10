#!/usr/bin/env python3
"""Enumerate source/config inputs reachable from this lab's actual cjpm entry."""
import os
from pathlib import Path
import sys
import tomllib


def source_inputs(lab):
    visited = set()
    inputs = set()

    def visit(module):
        module = module.resolve(strict=True)
        if module in visited:
            return
        visited.add(module)
        manifest = module / 'cjpm.toml'
        data = tomllib.loads(manifest.read_text())
        inputs.add(manifest)
        package = data['package']
        sources = (module / package.get('src-dir', 'src')).resolve(strict=True)
        if not sources.is_dir():
            raise ValueError(f'package source is not a directory: {sources}')
        inputs.update(p for p in sources.rglob('*') if p.is_file())
        dependencies = [data.get('dependencies', {})]
        dependencies += [target.get('dependencies', {}) for target in data.get('target', {}).values()
                         if isinstance(target, dict)]
        for table in dependencies:
            for dependency in table.values():
                if isinstance(dependency, dict) and 'path' in dependency:
                    visit(module / dependency['path'])

    visit(lab / 'entry')
    for name in ('cpp', 'ets', 'resources'):
        directory = lab / 'entry/src/main' / name
        if directory.is_dir():
            inputs.update(p for p in directory.rglob('*') if p.is_file())
    return sorted(inputs, key=os.fsencode)


if __name__ == '__main__':
    paths = source_inputs(Path(sys.argv[1]))
    # Emit only after the complete dependency graph has passed validation.
    for path in paths:
        sys.stdout.buffer.write(os.fsencode(path) + b'\0')
