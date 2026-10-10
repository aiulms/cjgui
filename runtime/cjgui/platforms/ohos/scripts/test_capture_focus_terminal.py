#!/usr/bin/env python3
"""Run the production branch: held selection defers, terminal UP reopens focus."""
from pathlib import Path
import subprocess,tempfile,sys
S=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'
def run(withdraw=False):
 s=S.read_text();a=s.index('            if (ownedTextSessionNodeId == node.nodeId && focusedNodeId == node.nodeId &&');b=s.index('            if (revealAcceptedNodeIfNeeded',a);branch=s[a:b]
 if withdraw:branch=branch.replace('pointerCaptureActive && !pointerCaptureTerminalDispatch','pointerCaptureActive')
 code='''package test
var focusNotifications=0
class Node {let nodeId=190;let resourceId = -1;let nodeKind=1}
class Window {
 var pointerCaptureActive=false;var pointerCaptureTerminalDispatch=false
 let ownedTextSessionNodeId=190;let focusedNodeId=190;let focusedResourceId = -1;let focusedNodeKind=1
 func ownedAnchorFocusable(n:Node):Bool{return true}
 func focusProjectedNode(id:Int64):Bool{focusNotifications+=1;return true}
 func call(active:Bool,terminal:Bool):Bool {pointerCaptureActive=active;pointerCaptureTerminalDispatch=terminal;let node=Node();BRANCH return false}
}
main():Int64{let w=Window();for(_ in 0..100){if(!w.call(true,false)){return 2}};if(focusNotifications!=0){println("FAIL active gesture emitted repeated whole-proxy focus notifications");return 1};if(!w.call(true,true)||focusNotifications!=1){println("FAIL terminal UP was suppressed as held focus after native blur");return 3};println("PASS held focus stays stable; real terminal UP reopens native focus even while capture verifies its final range");return 0}
'''.replace('BRANCH',branch)
 with tempfile.TemporaryDirectory()as t:
  p=Path(t);(p/'x.cj').write_text(code);subprocess.run(['cjc',str(p/'x.cj'),'-Woff','unused','-o',str(p/'x')],check=True);return subprocess.run([str(p/'x')]).returncode
if __name__=='__main__':
 c=run()
 if c:sys.exit(c)
 if '--selftest'in sys.argv:
  r=run(True);print('isolated withdrawal RED:',r);sys.exit(99 if not r else 0)
