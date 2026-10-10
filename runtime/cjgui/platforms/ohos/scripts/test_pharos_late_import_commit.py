#!/usr/bin/env python3
"""Run the actual controller result-commit method with temporary file IO.

The service fixture supplies current owner facts; the import and origin functions
are production code. The withdrawal removes the real controller origin barrier.
"""
from pathlib import Path
import subprocess
import tempfile
import sys

PRODUCT = Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src')
def balanced(source, start):
    opening = source.index('{', start); depth = 0
    for i in range(opening, len(source)):
        depth += (source[i] == '{') - (source[i] == '}')
        if depth == 0: return source[start:i+1]
    raise ValueError('production function unbalanced')

def run(withdraw=False):
    document = (PRODUCT/'pharos_ohos_document.cj').read_text()
    functions = document[document.index('public class PharosOhosImportOutcome'):]
    intent = (PRODUCT/'pharos_ohos_document_intent.cj').read_text().split('import std.time.*',1)[1]
    controller = (PRODUCT/'pharos_ohos_controller.cj').read_text()
    method = balanced(controller, controller.index('    public func applyDocumentIntentResult('))
    if withdraw:
        guard = 'if (!pending.matchesOrigin('
        method = method.replace(balanced(method, method.index(guard)), '', 1)
    with tempfile.TemporaryDirectory(prefix='pharos-late-import-') as temp:
        root = Path(temp)
        fixture = '''
var privateDir: String = "ROOT"
func pharosOhosPrivateFilesDir(): String { return privateDir }
class Owner {
    let documentId = "current"
    let sessionEpoch: Int64 = 7
    var version: Int64 = 3
    var saved: Int64 = 3
    func contentVersion(): Int64 { return version }
    func savedContentVersion(): Int64 { return saved }
}
class Service { let session = Owner() }
class Opened {
    let service: ?Service = Some(Service())
    let reason = ""
    func available(): Bool { return true }
}
func pharosOhosOpenLargeDocument(path: String): Opened { return Opened() }
func pharosOhosPublishWorkingBinding(d: String, w: String, c: String): String { return "" }
class Controller {
    var service = Service()
    var pendingDocumentIntent: ?PharosOhosDocumentIntent = None
    var documentIntentEmitted = true
    var documentIntentResultPath = ""
    var documentIntentStartedMs: Int64 = 1
    var lastImportOutcome = ""
    var lastExportOutcome = ""
    var lastDocumentIntentFact = ""
    var lastCommandFact = ""
    var commandCount: Int64 = 0
    var switched = false
    var documentBindingFailure = ""
    func replaceDocument(s: Service, bindingCandidate!: String = ""): Bool { switched = true; service = s; return true }
METHOD
}
main(): Int64 {
    var failures = 0
    let namespace = pharosOhosNewIntentNamespace(privateDir)
    let launch = PharosOhosDocumentIntent("import", 1, namespace, "current", 7, 3)
    File.writeTo(launch.staging, "late picker document".toArray())
    let receipt = launch.payload()[0..launch.payload().size-1] + ",\\\"status\\\":\\\"staged\\\"}"
    let c = Controller()
    c.pendingDocumentIntent = Some(launch)
    c.service.session.version = 4
    c.service.session.saved = 4
    let current = privateDir + "/current.md"
    File.writeTo(current, "edited and saved v4".toArray())
    c.applyDocumentIntentResult(receipt)
    if (c.switched || exists(privateDir + "/pharos-mark-import-" + launch.requestIdentity) ||
        String.fromUtf8(File.readFrom(current)) != "edited and saved v4") {
        println("FAIL late picker after edit and save reaches import commit"); failures += 1
    } else { println("PASS late picker rejected before work creation; saved bytes preserved") }
    let next = PharosOhosDocumentIntent("import", 2, namespace, "current", 7, 4)
    c.pendingDocumentIntent = Some(next)
    c.applyDocumentIntentResult(receipt)
    if (c.pendingDocumentIntent.isNone() || c.switched) {
        println("FAIL old receipt consumes new request"); failures += 1
    } else { println("PASS exact old receipt cannot settle new pending request") }
    return failures
}
'''.replace('ROOT', str(root)).replace('METHOD', method)
        (root/'main.cj').write_text('package late\nimport std.fs.*\nimport std.time.*\n'
            'public let PHAROS_OHOS_SMALL_DOCUMENT_MAX_BYTES: Int64 = 262144\n'
            'public let PHAROS_OHOS_LARGE_DOCUMENT_MAX_BYTES: Int64 = 1073741824\n'
            'public let PHAROS_OHOS_STREAM_CHUNK_BYTES: Int64 = 262144\n' +
            functions + intent + fixture)
        subprocess.run(['cjc', str(root/'main.cj'), '-Woff','unused','-o',str(root/'test')], check=True)
        return subprocess.run([str(root/'test')]).returncode
if __name__ == '__main__':
    clean = run()
    if clean: sys.exit(clean)
    if '--selftest' in sys.argv:
        red = run(withdraw=True)
        print(f'origin-barrier withdrawal exit={red}')
        if red == 0: sys.exit(99)
