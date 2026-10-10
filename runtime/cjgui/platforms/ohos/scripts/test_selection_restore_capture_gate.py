#!/usr/bin/env python3
"""Execute production restore entry: one native handoff after captured UP."""
from pathlib import Path
import subprocess,tempfile,sys
SOURCE=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'
def run(withdraw=False):
 s=SOURCE.read_text();a=s.index('private func restoreOwnedTextSelectionAfterAcceptedScene(): Unit {');b=s.index('        let session = match (ownedTextSession)',a);entry=s[a:b]
 if withdraw:entry=entry.replace('if (pointerCaptureActive) {','if (false) {',1)
 code='''package test
var nativeIssuances=0
func internalRendererWindowLog(text:String):Unit {}
class Window {
 var pointerCaptureActive=false
 ENTRY
 nativeIssuances+=1
 }
 func call(active:Bool):Unit {pointerCaptureActive=active;restoreOwnedTextSelectionAfterAcceptedScene()}
}
main():Int64 {let w=Window();for(_ in 0..100){w.call(true)};if(nativeIssuances!=0){println("FAIL moving selection issued 100 platform restores before UP");return 1};w.call(false);if(nativeIssuances!=1){return 2};println("PASS active capture leaves source pending, UP permits one frozen platform restore");return 0}
'''.replace('ENTRY',entry)
 with tempfile.TemporaryDirectory() as t:
  p=Path(t);(p/'a.cj').write_text(code);subprocess.run(['cjc',str(p/'a.cj'),'-Woff','unused','-o',str(p/'a')],check=True);return subprocess.run([str(p/'a')]).returncode
if __name__=='__main__':
 code=run()
 if code:sys.exit(code)
 if '--selftest'in sys.argv:
  red=run(True);print('isolated withdrawal RED:',red);sys.exit(99 if not red else 0)
