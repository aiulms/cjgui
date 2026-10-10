#!/usr/bin/env python3
"""Execute production identity, frozen-origin, and atomic permit functions."""
from pathlib import Path
import subprocess
import tempfile
import sys

PRODUCT = Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src')
def run():
    production = (PRODUCT / 'pharos_ohos_document_intent.cj').read_text()
    with tempfile.TemporaryDirectory(prefix='pharos-intent-basis-') as temp:
        root = Path(temp)
        code = '''
main(): Int64 {
    var failures = 0
    let root = "ROOT"
    let a = pharosOhosNewIntentNamespace(root)
    let b = pharosOhosNewIntentNamespace(root)
    if (a == "" || b == "" || a == b) { failures += 1; println("FAIL exclusive instance namespace") }
    else { println("PASS exclusive instance namespace") }
    let one = PharosOhosDocumentIntent("import", 1, a, "doc😀", 7, 3)
    let restart = PharosOhosDocumentIntent("import", 1, b, "doc😀", 7, 3)
    if (restart.matchesReceipt(one.payload()) || !one.matchesReceipt(one.payload())) {
        failures += 1; println("FAIL old instance receipt")
    } else { println("PASS old instance receipt refused") }
    let later = PharosOhosDocumentIntent("import", 2, a, "doc😀", 7, 3)
    if (later.matchesReceipt(one.payload())) { failures += 1; println("FAIL old request receipt") }
    else { println("PASS old request receipt refused") }
    // savedContentVersion may become 4, but the launching origin was 3.
    if (one.matchesOrigin("doc😀", 7, 4) || one.matchesOrigin("doc😀", 8, 3) ||
        one.matchesOrigin("other", 7, 3) || !one.matchesOrigin("doc😀", 7, 3)) {
        failures += 1; println("FAIL edit then save / binding change accepts late import")
    } else { println("PASS frozen origin rejects edit then save and rebinding") }
    if (!one.cancelBeforeClaim()) { failures += 1; println("FAIL cancel did not claim waiting permit") }
    var lateWriteClaimed = false
    try { rename(one.requestDir + "/waiting", to: one.requestDir + "/executing"); lateWriteClaimed = true }
    catch (e: Exception) { () }
    if (lateWriteClaimed) { failures += 1; println("FAIL late writer after cancel") }
    else { println("PASS cancellation forbids late writer") }
    rename(restart.requestDir + "/waiting", to: restart.requestDir + "/executing")
    if (restart.cancelBeforeClaim()) { failures += 1; println("FAIL cancellation steals claimed execution") }
    else { println("PASS already claimed writer retains settlement") }
    return failures
}
'''.replace('ROOT', str(root))
        (root / 'main.cj').write_text(production + code)
        subprocess.run(['cjc', str(root / 'main.cj'), '-Woff', 'unused', '-o', str(root / 'basis')], check=True)
        return subprocess.run([str(root / 'basis')]).returncode
if __name__ == '__main__':
    sys.exit(run())
