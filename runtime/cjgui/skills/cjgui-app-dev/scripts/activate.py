#!/usr/bin/env python3
"""Connect a scoped CJGUI skill entry to an explicitly selected project rules file.

Does not configure a host, alter user memory, or claim that a model loaded it.
Refresh replaces only an unchanged generated block, never surrounding user rules.
"""
import argparse
import difflib
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
from urllib.parse import quote, unquote

BEGIN = '<!-- cjgui-app-dev:begin -->'
END = '<!-- cjgui-app-dev:end -->'
LINK = re.compile(r'\[CJGUI 应用开发技能\]\(<([^>]+)>\)')
STAMP = re.compile(r'\n<!-- cjgui-app-dev:generated content-sha256=([0-9a-f]{64}) template-sha256=([0-9a-f]{64}) -->\n')
# v3 generated blocks predate content stamps. Normalize only the generated link,
# then require the exact shipped template; arbitrary legacy edits are not trusted.
LEGACY_TEMPLATE_SHA256 = {'6b2fc7c3ac6b2aeee8faf23120897685f3e3879b504e45a5d26c563e5c6c2051'}


def digest(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def existing_block(text, path):
    if BEGIN not in text and END not in text:
        return None
    if text.count(BEGIN) != 1 or text.count(END) != 1 or text.index(END) < text.index(BEGIN):
        return {'managed':False, 'reason':'duplicate, missing or reversed block markers', 'block':''}
    start = text.index(BEGIN); end = text.index(END) + len(END)
    block = text[start:end]
    stamp = STAMP.search(block)
    if stamp and stamp.start() == len(BEGIN) and len(STAMP.findall(block)) == 1:
        unstamped = block[:stamp.start()] + '\n' + block[stamp.end():]
        managed = digest(unstamped) == stamp.group(1)
        provenance = 'content_stamp'
    else:
        normalized, count = LINK.subn('__CJGUI_SKILL_LINK__', block)
        managed = count == 1 and digest(normalized) in LEGACY_TEMPLATE_SHA256
        provenance = 'known_v3_template' if managed else 'unknown_or_edited'
    link = LINK.search(block)
    link_status = 'unknown'
    if link:
        link_status = 'present' if (path.parent / unquote(link.group(1))).is_file() else 'missing'
    return {'managed':managed, 'reason':provenance, 'block':block, 'span':(start,end),
            'existing_link_status':link_status}


def activate(project, rules_name, skill, dry_run=False, refresh=False):
    project = project.expanduser().resolve()
    skill = skill.expanduser().resolve()
    if not project.is_dir():
        raise ValueError('project must be an existing directory; choose its actual rules scope')
    name = Path(rules_name)
    path = project / name
    if path.is_symlink():
        raise ValueError('rules file must not be a symlink')
    if name.is_absolute() or not path.resolve().is_relative_to(project):
        raise ValueError('rules file is outside project')
    if path.exists() and not path.is_file():
        raise ValueError('rules file must be a regular file')
    entry = skill / 'SKILL.md'
    if not entry.is_file():
        raise ValueError(f'skill entrypoint unavailable: {entry}')
    relative = os.path.relpath(entry, path.parent)
    template = (skill / 'assets/PROJECT_RULE.md').read_text(encoding='utf-8')
    if template.count('__CJGUI_SKILL_LINK__') != 1:
        raise ValueError('project rule template is missing its single skill entry placeholder')
    if template.count(BEGIN) != 1 or template.count(END) != 1 or not template.strip().startswith(BEGIN) or not template.strip().endswith(END):
        raise ValueError('project rule template must contain one complete bounded block')
    # Inside <...> a Markdown destination may contain literal spaces, and a reader
    # that copies the path into a tool call must get a path that opens as written.
    # Percent-encoding spaces would turn a valid path into a nonexistent one.
    destination = Path(relative).as_posix()
    encoded = any(c in destination for c in '<>#?%\\') or any(ord(c) < 32 for c in destination)
    target = quote(destination, safe='/.-_') if encoded else destination
    link = f'[CJGUI 应用开发技能](<{target}>)'
    if encoded:
        raw_path = json.dumps(destination, ensure_ascii=False).replace('`', '\\u0060')
        link += f'（文件路径 JSON：`{raw_path}`）'
    base = template.replace('__CJGUI_SKILL_LINK__', link).strip()
    stamp = f'<!-- cjgui-app-dev:generated content-sha256={digest(base)} template-sha256={digest(template.rstrip())} -->'
    block = base.replace(BEGIN, BEGIN + '\n' + stamp, 1)
    result = {'status':'planned', 'rules_file':str(path), 'skill_entrypoint':str(entry),
              'host_loading':'not_verified'}
    original = path.read_bytes() if path.exists() else b''
    prior = existing_block(original.decode('utf-8'), path)
    if prior:
        result.update(existing_block=prior['block'], block_origin=prior['reason'],
                      existing_link_status=prior.get('existing_link_status','unknown'))
        result['diff'] = ''.join(difflib.unified_diff(prior['block'].splitlines(True),
                                block.splitlines(True), fromfile='existing CJGUI block', tofile='proposed CJGUI block'))
        if prior['block'] == block or (prior['managed'] and prior['block'] == base and not refresh):
            result['status'] = 'already_present'
        else:
            result['status'] = 'update_available' if prior['managed'] else 'conflict'
    if dry_run:
        result['proposed_block'] = block
        return result
    if result['status'] == 'already_present':
        return result
    if result['status'] == 'conflict':
        raise ValueError(f'existing CJGUI activation block differs and is edited or unrecognized; preserved: {path}\n'
                         f'Use --dry-run to inspect existing/proposed blocks; merge manually.\n{result["diff"][:12000]}')
    if result['status'] == 'update_available' and not refresh:
        raise ValueError(f'unchanged generated CJGUI block needs an update: {path}\n'
                         f'Use --dry-run to review, then --refresh to replace only this block.\n{result["diff"][:12000]}')
    path.parent.mkdir(parents=True, exist_ok=True)
    lock = path.with_name(path.name + '.cjgui-activation-lock')
    try:
        lock.mkdir()
    except FileExistsError as error:
        raise ValueError(f'activation is busy or interrupted; inspect this project lock before retrying: {lock}') from error
    try:
        if path.is_symlink() or (path.read_bytes() if path.exists() else b'') != original:
            raise ValueError(f'rules changed while planning activation; re-run to inspect: {path}')
        if prior:
            start,end = prior['span']; text = original.decode('utf-8')
            updated = (text[:start] + block + text[end:]).encode('utf-8')
            mode = stat.S_IMODE(path.stat().st_mode)
            fd, tmp = tempfile.mkstemp(prefix='.cjgui-activation-', dir=path.parent)
            try:
                with os.fdopen(fd, 'wb') as output:
                    os.fchmod(output.fileno(), mode)
                    output.write(updated); output.flush(); os.fsync(output.fileno())
                if path.is_symlink() or path.read_bytes() != original:
                    raise ValueError(f'rules changed before refresh; preserved: {path}')
                os.replace(tmp, path)
            finally:
                Path(tmp).unlink(missing_ok=True)
            result['status'] = 'refreshed'
        else:
            prefix = b'\n\n' if original else b''
            flags = os.O_WRONLY | os.O_CREAT | os.O_APPEND | getattr(os, 'O_NOFOLLOW', 0)
            with os.fdopen(os.open(path, flags, 0o644), 'ab') as output:
                output.write(prefix + block.encode('utf-8') + b'\n')
                output.flush(); os.fsync(output.fileno())
            result['status'] = 'added'
        if block not in path.read_bytes().decode('utf-8'):
            raise ValueError(f'activation readback failed; rules may have changed concurrently: {path}')
        return result
    finally:
        lock.rmdir()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', required=True, type=Path)
    parser.add_argument('--rules-file', default='AGENTS.md', help='relative path of a Markdown rules file this host actually reads')
    parser.add_argument('--skill', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--refresh', action='store_true', help='replace only a verifiably unchanged generated block; preserves user edits and surrounding rules')
    args = parser.parse_args()
    try:
        report = activate(args.project, args.rules_file, args.skill, args.dry_run, args.refresh)
    except (OSError, ValueError) as error:
        parser.exit(2, f'activate: {error}\n')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__': main()
