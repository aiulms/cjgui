#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
output_dir="${CJGUI_CONTROL_AX_TMPDIR:-$(mktemp -d /private/tmp/cjgui-control-ax.XXXXXX)}"
python3 - "$runtime_dir" "$output_dir" <<'PY'
from pathlib import Path
import json, os, subprocess, sys
runtime, output = [Path(p).resolve() for p in sys.argv[1:]]
output.mkdir(parents=True, exist_ok=True)
binary = output / 'composable_control_ax_semantics_test'
record_path = output / 'control-ax-run.json'
previous = json.loads(record_path.read_text()) if record_path.exists() else {}
if binary.exists():
    assert previous.get('task') == 'cjgui-control-ax' and previous.get('binary') == str(binary)
    assert subprocess.run(['ps', '-p', str(previous['pid'])], capture_output=True).returncode != 0
    assert not subprocess.run(['/usr/sbin/lsof', '-t', '--', str(binary)], capture_output=True).stdout
    binary.unlink()
record = dict(task='cjgui-control-ax', binary=str(binary), pid=os.getpid(),
              compiler_exit=None, test_exit=None, binary_removed=False)
record_path.write_text(json.dumps(record, indent=2) + '\n')
try:
    sdk = subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], text=True).strip()
    command = ['clang', '-fobjc-arc', '-fno-objc-msgsend-selector-stubs', '-fmodules',
               '-fstack-protector-strong', '-isysroot', sdk, '-mmacosx-version-min=12.0',
               str(runtime / 'native/tests/composable_control_ax_semantics_test.m'),
               str(runtime / 'native/cjgui_native_bridge.m'), '-framework', 'AppKit',
               '-framework', 'Metal', '-framework', 'MetalKit', '-framework', 'QuartzCore',
               '-lobjc', '-o', str(binary)]
    with (output / 'build.log').open('w') as log:
        record['compiler_exit'] = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=120).returncode
    if record['compiler_exit'] == 0:
        record['test_exit'] = subprocess.run([str(binary)], timeout=45).returncode
    else:
        print('\n'.join((output / 'build.log').read_text().splitlines()[-40:]))
finally:
    if binary.exists():
        assert not subprocess.run(['/usr/sbin/lsof', '-t', '--', str(binary)], capture_output=True).stdout
        record['released_allocated_bytes'] = binary.stat().st_blocks * 512
        binary.unlink()
    record['binary_removed'] = not binary.exists()
    record_path.write_text(json.dumps(record, indent=2) + '\n')
status = record['compiler_exit'] or record['test_exit'] or 0
if status == 0: print('PASSED composable control AX semantics')
sys.exit(status)
PY
