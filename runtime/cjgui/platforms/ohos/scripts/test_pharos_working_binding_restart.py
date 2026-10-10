#!/usr/bin/env python3
"""Production work binding on temporary files, including a fresh reader and failed publication."""
from pathlib import Path
import tempfile, subprocess, sys
P=Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src')
CORE=Path('/Users/jiangxuanyang/Desktop/Pharos Mark/packages/document_core/src/persistence.cj')
def balanced(s,start):
    i=s.index('{',start); depth=0
    for j in range(i,len(s)):
        depth+=(s[j]=='{')-(s[j]=='}')
        if not depth: return s[start:j+1]
def run():
    production=P/'pharos_ohos_working_binding.cj'
    if production.exists():
        code=production.read_text().split('import pharos_document_core.*',1)[1]
        code+='\nforeign func renameat(fd: Int32, from: CString, toFd: Int32, to: CString): Int32\nlet PHAROS_AT_FDCWD: Int32 = -2\n'
        core=CORE.read_text(); code+='\n'+balanced(core,core.index('public class PharosPublishOutcome'))+'\n'+balanced(core,core.index('public func pharosPublishCandidateFile'))
    else:
        code='func pharosOhosPublishWorkingBinding(d:String,p:String,c:String):String { return "" }\nfunc pharosOhosReadWorkingBinding(d:String):String { return d + "/pharos-mark.md" }'
    with tempfile.TemporaryDirectory(prefix='pharos-restart-binding-') as temp:
        root=Path(temp)
        fixture=r'''
main(): Int64 {
    let d="ROOT"
    let work=d+"/pharos-mark-import-i100-0-r1/working.md"
    Directory.create(pharosOhosParentDirectory(work))
    File.writeTo(work,"saved imported work".toArray())
    let c=d+"/binding.pending"
    var fail=0
    let result=pharosOhosPublishWorkingBinding(d,work,c)
    if (result!="" || pharosOhosReadWorkingBinding(d)!=work || String.fromUtf8(File.readFrom(work))!="saved imported work") {
        println("FAIL fresh instance cannot reopen imported work binding");fail+=1
    } else { println("PASS fresh reader opens exact imported work") }
    let original=if(exists(d+"/pharos-working-binding")){File.readFrom(d+"/pharos-working-binding")}else{"".toArray()}
    let refusal=pharosOhosPublishWorkingBinding(d,d+"/../external.md",c)
    if (refusal=="" || pharosOhosReadWorkingBinding(d)!=work || (exists(d+"/pharos-working-binding") && File.readFrom(d+"/pharos-working-binding")!=original)) {
        println("FAIL rejected binding changes previous publication");fail+=1
    } else { println("PASS rejected binding preserves exact previous pointer") }
    return fail
}
'''.replace('ROOT',str(root))
        document=(P/'pharos_ohos_document.cj').read_text()
        code+='\n'+balanced(document,document.index('public func pharosOhosParentDirectory'))
        (root/'test.cj').write_text('package binding\nimport std.fs.*\n'+code+fixture)
        subprocess.run(['cjc',str(root/'test.cj'),'-Woff','unused','-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode
if __name__=='__main__': sys.exit(run())
