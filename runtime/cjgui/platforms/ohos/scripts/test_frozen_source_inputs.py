"""Source binding must reject drift before a consumer sync or build can run."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name('source_inputs.py')


class FrozenInputTest(unittest.TestCase):
    def test_bound_source_and_environment(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'shared core'
            source.mkdir()
            contract = source / 'contract.cj'
            original = b'class CjguiSharedOperationOwnerWriteAdmission {}\n'
            contract.write_bytes(original)
            header = root / 'shared_abi.h'
            header.write_text('struct Event {};\n')
            manifest = root / 'frozen.json'
            manifest.write_text(json.dumps({
                'bindings': {'CJGUI_SHARED_CORE_SRC': str(source)},
                'roots': [{'path': str(source), 'files': {
                    'contract.cj': hashlib.sha256(original).hexdigest()}},
                    {'path': str(header), 'files': {
                        '': hashlib.sha256(header.read_bytes()).hexdigest()}}]}))
            env = dict(os.environ, CJGUI_SHARED_CORE_SRC=str(source))

            def verify():
                return subprocess.run(
                    ['python3', str(SCRIPT), '--verify-frozen-inputs', str(manifest)],
                    capture_output=True, text=True, env=env)

            result = verify()
            self.assertEqual(result.returncode, 0, result.stderr)
            header.write_text('struct Event { int changed; };\n')
            result = verify()
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('SOURCE-DRIFT', result.stderr)
            header.write_text('struct Event {};\n')
            # Keeping the admission type name must not hide a content change.
            contract.write_bytes(original + b'// changed protocol\n')
            result = verify()
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('SOURCE-DRIFT', result.stderr)
            contract.write_bytes(original)
            extra = source / 'unexpected.cj'
            extra.write_text('class Unfrozen {}')
            result = verify()
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('SOURCE-DRIFT', result.stderr)
            extra.unlink()
            copied = root / 'consumer copy'
            copied.mkdir()
            copied_contract = copied / contract.name
            copied_contract.write_bytes(original)
            command = ['python3', str(SCRIPT), '--verify-frozen-inputs',
                       str(manifest), str(source), str(copied)]
            result = subprocess.run(command, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            copied_contract.write_bytes(original.replace(b'class', b'CLASS'))
            result = subprocess.run(command, env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('SOURCE-DRIFT', result.stderr)
            env['CJGUI_SHARED_CORE_SRC'] = str(root / 'live')
            result = verify()
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('SOURCE-DRIFT', result.stderr)


if __name__ == '__main__':
    unittest.main()
