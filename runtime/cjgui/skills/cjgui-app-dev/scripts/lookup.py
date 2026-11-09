#!/usr/bin/env python3
"""Locate same-version CJGUI documentation and declaration text; never builds or runs code."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

from identify import app_path, identify


# Navigation hints, not copies of API contracts. Every result is read from the
# selected dependency; missing files/symbols are never synthesized from a newer SDK.
TOPICS = (
    (('布局', '空白', 'layout', 'stretch', 'grow'),
     ('LAYOUT_PRIMITIVES.md',), ('growX', 'growY', 'alignX', 'alignY', 'contentBounds')),
    (('主题', '美感', '配色', 'theme', 'warmpaper'),
     ('STYLE_ROLES.md',), ('CjguiComposableUiTheme', 'boundStyle', 'warmPaper')),
    (('保存', '持久', '工作会话', 'worksession', 'work-session'),
     ('WORK_SESSION.md', 'MACOS_APPLICATION_HOST.md'), ('CjguiComposableUiWorkSession',)),
    (('字段', '输入', '事件', 'event', 'controller'),
     ('FIELD_CONTROLS.md',), ('CjguiComposableUiController', 'TEXT_CHANGED', 'INTEGER_CHANGED')),
    (('诊断', 'inspector', 'diagnostic'),
     ('LAYOUT_PRIMITIVES.md',), ('diagnosticSnapshot', 'inspector')),
    (('生成', '混合', 'owner', 'generated', 'mixed'),
     ('GENERATED_EDITING.md', 'mixed_form/README.md'), ('CjguiComposableUiBoundForm',)),
    (('滚动', 'scroll', 'viewport'),
     ('LAYOUT_PRIMITIVES.md',), ('CjguiComposableUiScrollViewport', 'cjguiComposableScrollArea')),
    (('窗口', 'window', 'bundle'),
     ('MACOS_APPLICATION_HOST.md',), ('CjguiMacosApplicationWindowConfiguration',)),
)


def inventory(root):
    docs = set(root.glob('*.md'))
    for directory in ('templates', 'shared_operation_core'):
        docs.update((root / directory).rglob('*.md'))
    docs.add(root / 'preview/MACOS_DEVELOPER_QUICKSTART.md')
    sources = {p for p in (root / 'src').rglob('*.cj') if not p.name.endswith('_test.cj')}
    for path in sorted(docs | sources):
        if not path.is_file() or not path.resolve().is_relative_to(root):
            continue
        if path.name == 'ACTIVE_DIRECTION.md' or path.name.startswith('DIRECTION_HISTORY'):
            continue
        raw = path.read_bytes()
        yield path, raw.decode('utf-8', errors='replace').splitlines(), hashlib.sha256(raw).hexdigest()


def search_terms(query):
    # Each Latin word or Chinese phrase has one score budget. Bigram spans
    # recover partial Chinese matches, but overlapping spans share that budget.
    groups = [[(word, 0, len(word))] for word in sorted(set(re.findall(r'[a-z0-9_]+', query)))]
    for phrase in re.findall(r'[\u4e00-\u9fff]+', query):
        if len(phrase) == 1:
            continue
        groups.append([(phrase, 0, len(phrase))] +
                      [(phrase[i:i + 2], i, i + 2) for i in range(len(phrase) - 1)])
    return groups


def direct_score(groups, haystack):
    score = 0
    for terms in groups:
        covered = set()
        for term, start, end in terms:
            if term in haystack:
                covered.update(range(start, end))
        score += 12 * len(covered) / terms[0][2]
    return score


def text_blocks(lines, source):
    if source:
        for index, line in enumerate(lines):
            if not re.match(r'^\s*public\s+', line):
                continue
            end = index + 1
            text = line.split('//', 1)[0]
            if '(' in text and '{' not in text:
                while end < len(lines) and not re.match(r'^\s*(public\s+|})', lines[end]):
                    text += '\n' + lines[end].split('//', 1)[0]
                    end += 1
                    if '{' in text:
                        break
            # Locate the declaration header, not its implementation body.
            if '{' in text:
                text = text.split('{', 1)[0] + '{'
            yield index, end, text, 'declaration_header', None
    else:
        index = 0; section = None
        while index < len(lines):
            if not lines[index].strip():
                index += 1; continue
            start = index
            if re.match(r'^#{1,6}\s', lines[index]):
                section = lines[index].lstrip('#').strip()
                index += 1
            else:
                while index < len(lines) and lines[index].strip() and not re.match(r'^#{1,6}\s', lines[index]):
                    index += 1
            yield start, index, '\n'.join(lines[start:index]), 'paragraph', section


def lookup(files, query, limit):
    q = query.casefold().strip()
    if not q:
        raise ValueError('query must not be empty')
    tokens = search_terms(q)
    routes = set(); aliases = set()
    for words, paths, symbols in TOPICS:
        if any(word in q for word in words):
            routes.update(paths); aliases.update(s.casefold() for s in symbols)
    available_docs = [path.as_posix() for path, _, _ in files if path.suffix == '.md']
    absent = sorted(route for route in routes if not any(p.endswith(route) for p in available_docs))
    matches = []
    for path, lines, checksum in files:
        source = path.suffix == '.cj'
        routed = not source and any(path.as_posix().endswith(route) for route in routes)
        local = []
        for index, end, text, scope, section in text_blocks(lines, source):
            haystack = text.casefold()
            direct = direct_score(tokens, haystack)
            alias = sum(term in haystack for term in aliases)
            score = direct + alias * 5 + (60 if source else 25) * (q in haystack)
            name = re.match(r'^\s*public\s+(?:(?:open|abstract|sealed|static|override)\s+)*(?:class|interface|struct|enum|func|let|var|const|type)\s+([A-Za-z_]\w*)', text) if source else None
            if name:
                symbol = name.group(1).casefold()
                if q in symbol:
                    score += 200 if q == symbol else 100
                elif any(term in symbol for term in aliases):
                    score += 30
            # Routing identifies useful files. It must not outrank a paragraph
            # that actually answers the query, or make every heading a hit.
            if routed and score:
                score += 3
            elif routed and index == 0:
                score = 1
            if not score:
                continue
            excerpt = '\n'.join(text.splitlines()[:12])
            hit = {'path':str(path), 'line':index + 1,
                   'kind':'declaration_text' if source else 'documentation',
                   'file_sha256':checksum, 'snippet':excerpt[:1600], 'snippet_scope':scope,
                   'snippet_truncated':len(text.splitlines()) > 12 or len(excerpt) > 1600,
                   'has_more_context_before':index > 0, 'has_more_context_after':end < len(lines)}
            if section is not None:
                hit['section'] = section
            local.append((score, hit))
        matches.extend(sorted(local, key=lambda item: (-item[0], item[1]['line']))[:limit])
    matches.sort(key=lambda item: (-item[0], item[1]['path'], item[1]['line']))
    return {'query':query, 'status':'found' if matches else 'no_match',
            'routes_not_present':absent,
            'matches':[item for _, item in matches[:limit]], 'more_matches':len(matches) > limit}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument('--app', type=app_path, help='existing application; follow its actual local dependencies')
    target.add_argument('--framework', type=app_path, help='explicit selected CJGUI package (contains cjpm.toml), including before app creation')
    parser.add_argument('--query', action='append', required=True, help='repeat for independent symbols or intents')
    parser.add_argument('--max-results', type=int, default=3, choices=range(1, 11), metavar='1..10')
    args = parser.parse_args()
    references, _, warnings = identify(args.app if args.app is not None else args.framework, False)
    if args.framework is not None:
        references = [r for r in references if Path(r['path']) == args.framework.resolve()]
    if not references:
        raise ValueError('no CJGUI package identified; check the dependency path; this does not prove a capability is unsupported')
    if len(references) != 1:
        raise ValueError('multiple CJGUI dependencies; inspect identify output and choose the actual package with --framework')
    framework = references[0]
    files = list(inventory(Path(framework['path'])))
    coverage = {'documentation_files':sum(path.suffix == '.md' for path, _, _ in files),
                'root_documentation_files':sum(path.suffix == '.md' and path.parent == Path(framework['path']) for path, _, _ in files),
                'source_files':sum(path.suffix == '.cj' for path, _, _ in files),
                'templates_present':(Path(framework['path']) / 'templates').is_dir()}
    if coverage['documentation_files'] == 0:
        warnings.append('no public documentation found in the selected package search scope; routed guides may be absent; source matches do not replace their contracts')
    if coverage['root_documentation_files'] == 0:
        warnings.append('no root-level public guides found in the selected package; nested protocol documentation does not replace application guides')
    if not coverage['templates_present']:
        warnings.append('templates directory not present in the selected package; application skeletons cannot be located here')
    queries = [lookup(files, q, args.max_results) for q in args.query]
    missing = sorted({route for query in queries for route in query['routes_not_present']})
    if missing:
        warnings.append('requested documentation routes not present in the selected package: ' + ', '.join(missing))
    print(json.dumps({'schema_version':2,'framework':framework, 'coverage':coverage, 'evidence_kind':'source_lookup_only', 'warnings':warnings,
                      'queries':queries,
                      'note':'A found status only locates declaration/documentation text; read the declaration and same-version contract before use. '
                             'No match is not a capability verdict. Build/runtime are not verified.'}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, TypeError) as error:
        print(f'lookup: {error}', file=sys.stderr)
        sys.exit(2)
