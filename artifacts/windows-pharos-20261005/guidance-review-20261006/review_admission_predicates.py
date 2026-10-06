"""Bounded offline review of current source predicates; no VM/build/product writes.

This extracts the production script's literal match and the wrapper's C branch
condition. Python evaluates only their equivalent string/boolean predicates.
It does not claim to execute PowerShell, Win32 CopyFile, or the built wrapper.
"""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ACCEPT = ROOT / 'artifacts/windows-pharos-20261005/runner/batches/acceptance/pharos-writing-chain-acceptance.ps1'
NATIVE = ROOT / 'runtime/cjgui/platforms/windows/native/cjgui_windows_renderer.c'
WRAPPER = ROOT / 'artifacts/windows-pharos-20261005/guest-transfer/llc-relay/llc_wrapper.c'


def at_line(source, offset):
    return source.count('\n', 0, offset) + 1


a, n, w = [p.read_text() for p in (ACCEPT, NATIVE, WRAPPER)]
click = re.search(r"if\(\$c107 -notmatch '([^']+)'\)\{ Fail 30", a)
missing = re.search(r'fprintf\(clickOut, "(CLICK_RESULT %llu missing)\\n", clickId\)', n)
assert click and missing
pattern = click.group(1)
missing_reply = missing.group(1).replace('%llu', '107')
click_cases = [
    {'name': 'positive', 'reply': 'CLICK_RESULT 107 at=100,200', 'expected_accept': True},
    {'name': 'missing_node_negative', 'reply': missing_reply, 'expected_accept': False},
    {'name': 'other_node_negative', 'reply': 'CLICK_RESULT 108 at=100,200', 'expected_accept': False},
]
for case in click_cases:
    case['actual_accept'] = re.search(pattern, case['reply'], re.I) is not None
    case['matches_expectation'] = case['actual_accept'] == case['expected_accept']

branch = re.search(r'if \((inPath && outPath && strstr\(inPath, "pharos_mark\.opt\.bc"\) != NULL)\) \{', w)
assert branch
condition = branch.group(1)
python_condition = condition.replace('&&', ' and ').replace('NULL', 'None')


def strstr(haystack, needle):
    offset = haystack.find(needle)
    return None if offset < 0 else haystack[offset:]


same_hash = hashlib.sha256(b'bc snapshot A').hexdigest()
changed_hash = hashlib.sha256(b'bc snapshot B').hexdigest()
relay_cases = []
for name, input_hash in [('matching_snapshot_positive', same_hash), ('different_snapshot_negative', changed_hash)]:
    values = {'inPath': r'C:\build\pharos_mark.opt.bc', 'outPath': r'C:\build\pharos_mark.o', 'strstr': strstr}
    actual = bool(eval(python_condition, {'__builtins__': {}}, values))
    relay_cases.append({'name': name, 'input_bc_sha256': input_hash,
                        'object_built_from_bc_sha256': same_hash,
                        'expected_injection_admitted': input_hash == same_hash,
                        'actual_injection_branch_entered': actual,
                        'object_copy_success_assumed': True,
                        'capture_copy_success_required_by_source': False,
                        'successful_object_copy_returns_zero': bool(re.search(
                            r'if \(CopyFileA\(RELAY_OBJ, outPath, FALSE\)\) \{[^}]*return 0;', w, re.S))})

result = {
    'scope': __doc__.strip(),
    'sources': [{'path': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in (ACCEPT, NATIVE, WRAPPER)],
    'probe_click': {'accept_line': at_line(a, click.start()),
                    'native_missing_line': at_line(n, missing.start()),
                    'source_match_pattern': pattern, 'cases': click_cases},
    'relay': {'wrapper_condition_line': at_line(w, branch.start()),
              'source_condition': condition, 'python_equivalent': python_condition,
              'cases': relay_cases},
}
out = Path(__file__).with_name('admission-predicate-results.json')
out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False, indent=2))
