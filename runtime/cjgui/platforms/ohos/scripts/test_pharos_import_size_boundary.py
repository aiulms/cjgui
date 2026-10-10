#!/usr/bin/env python3
"""Run actual import/candidate publication on owned files at 256 KiB and refusals."""
from pathlib import Path
import subprocess,tempfile,sys
P=Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src/pharos_ohos_document.cj')
s=P.read_text();production=s[s.index('public class PharosOhosImportOutcome'):]
with tempfile.TemporaryDirectory(prefix='h-import-limit-')as tmp:
 p=Path(tmp);p.joinpath('limit.bin').write_bytes(b'a'*262144);p.joinpath('over.bin').write_bytes(b'a'*262145);p.joinpath('invalid.bin').write_bytes(b'\xff')
 test="""
main():Int64 {
 let root="ROOT"
 let limit=pharosOhosImportWorkingCopy(root+"/limit.bin",root,"boundary-limit")
 if(!limit.ok() || File.readFrom(limit.workingPath).size!=262144){println("FAIL exact 256KiB private publication");return 1}
 let over=pharosOhosImportWorkingCopy(root+"/over.bin",root,"boundary-over")
 let invalid=pharosOhosImportWorkingCopy(root+"/invalid.bin",root,"boundary-invalid")
 if(over.ok() || invalid.ok() || File.readFrom(limit.workingPath).size!=262144){println("FAIL oversize/invalid refusal preserves previous work");return 2}
 if(exists(root+"/pharos-mark-import-boundary-over") || exists(root+"/pharos-mark-import-boundary-invalid")){println("FAIL refused import published a candidate directory");return 3}
 println("PASS actual 262144-byte import exact; 262145 bytes and invalid UTF-8 refused before candidate publication")
 return 0
}
""".replace('ROOT',str(p))
 p.joinpath('x.cj').write_text('package safety\nimport std.fs.*\npublic let PHAROS_OHOS_SMALL_DOCUMENT_MAX_BYTES:Int64=262144\npublic let PHAROS_OHOS_LARGE_DOCUMENT_MAX_BYTES:Int64=1073741824\npublic let PHAROS_OHOS_STREAM_CHUNK_BYTES:Int64=262144\n'+production+test)
 subprocess.run(['cjc',str(p/'x.cj'),'-Woff','unused','-o',str(p/'x')],check=True);sys.exit(subprocess.run([str(p/'x')]).returncode)
