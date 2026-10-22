#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
python3 - "$runtime_dir" "${CJGUI_MODAL_RETURN_OUTPUT:?set an owned bounded evidence directory}" <<'PY'
from pathlib import Path
import json, os, subprocess, sys, time
runtime, output = map(Path, sys.argv[1:])
output.mkdir(parents=True, exist_ok=True)
binary = output / 'modal-return-commit-test'
record_path = output / 'modal-return-native-run.json'
previous = json.loads(record_path.read_text()) if record_path.exists() else {}
if binary.exists():
    assert previous.get('task') == 'cjgui-modal-return' and previous.get('binary') == str(binary)
    assert subprocess.run(['ps', '-p', str(previous['pid'])], capture_output=True).returncode != 0
    assert not subprocess.run(['/usr/sbin/lsof', '-t', '--', str(binary)], capture_output=True).stdout
    binary.unlink()
record = dict(task='cjgui-modal-return', binary=str(binary), pid=os.getpid(),
              started_epoch=time.time(), compiler_exit=None, test_exit=None, binary_removed=False)
record_path.write_text(json.dumps(record, indent=2) + '\n')
try:
    sdk = subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], text=True).strip()
    command = ['clang', '-fobjc-arc', '-fno-objc-msgsend-selector-stubs', '-fmodules',
               '-fstack-protector-strong', '-isysroot', sdk, '-mmacosx-version-min=12.0',
               str(runtime / 'native/tests/composable_modal_return_commit_test.m'),
               str(runtime / 'native/cjgui_native_bridge.m'), '-framework', 'AppKit',
               '-framework', 'Metal', '-framework', 'MetalKit', '-framework', 'QuartzCore',
               '-lobjc', '-o', str(binary)]
    with (output / 'modal-return-native-build.log').open('w') as log:
        record['compiler_exit'] = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=120).returncode
    if record['compiler_exit'] == 0:
        with (output / 'modal-return-native-result.log').open('w') as log:
            record['test_exit'] = subprocess.run([str(binary)], stdout=log, stderr=subprocess.STDOUT, timeout=45).returncode
finally:
    if binary.exists():
        record['released_allocated_bytes'] = binary.stat().st_blocks * 512
        binary.unlink()
    record['binary_removed'] = not binary.exists()
    record_path.write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record))
sys.exit(record['compiler_exit'] or record['test_exit'] or 0)
PY
