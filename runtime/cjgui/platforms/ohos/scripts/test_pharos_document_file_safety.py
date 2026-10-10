#!/usr/bin/env python3
"""Execute the production small-file import/receipt functions on owned temp files."""
from pathlib import Path
import subprocess
import tempfile
import sys

PRODUCT = Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src')

def run():
    source = (PRODUCT / 'pharos_ohos_document.cj').read_text()
    code = source[source.index('public class PharosOhosImportOutcome'):]
    token = '"request-1"' if 'requestIdentity: String' in code else '1'
    with tempfile.TemporaryDirectory(prefix='pharos-file-safety-') as temp:
        root = Path(temp)
        test = '''
main(): Int64 {
    var failures = 0
    let root = "ROOT"
    let stage = root + "/staging.bin"
    File.writeTo(stage, "first private document".toArray())
    let first = pharosOhosImportWorkingCopy(stage, root, TOKEN)
    File.writeTo(stage, "late replacement".toArray())
    let second = pharosOhosImportWorkingCopy(stage, root, TOKEN)
    if (!first.ok() || second.ok() || String.fromUtf8(File.readFrom(first.workingPath)) != "first private document") {
        println("FAIL repeated/restarted request overwrites private work")
        failures += 1
    } else { println("PASS private work is exclusive") }
    let receipt = root + "/r1.result.json"
    File.writeTo(receipt, "{\\\"status\\\":\\\"staged\\\"}".toArray())
    let one = pharosOhosReadIntentResult(receipt)
    let two = pharosOhosReadIntentResult(receipt)
    if (one.isNone() || two.isSome()) {
        println("FAIL old receipt can be consumed twice")
        failures += 1
    } else { println("PASS receipt consumed exactly once") }
    return failures
}
'''.replace('ROOT', str(root)).replace('TOKEN', token)
        (root / 'main.cj').write_text('package safety\nimport std.fs.*\n'
            'public let PHAROS_OHOS_SMALL_DOCUMENT_MAX_BYTES: Int64 = 262144\n'
            'public let PHAROS_OHOS_LARGE_DOCUMENT_MAX_BYTES: Int64 = 1073741824\n'
            'public let PHAROS_OHOS_STREAM_CHUNK_BYTES: Int64 = 262144\n' + code + test)
        subprocess.run(['cjc', str(root / 'main.cj'), '-Woff', 'unused', '-o', str(root / 'safety')], check=True)
        return subprocess.run([str(root / 'safety')]).returncode

if __name__ == '__main__':
    sys.exit(run())
