#!/usr/bin/env python3
"""Run the real semantic focus entry. Existing owned focus must not reveal its whole document."""
from pathlib import Path
import tempfile,subprocess,sys
P=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'
s=P.read_text();start=s.index('    public func focusAcceptedSemanticNode(');end=s.index('    /// Satisfies a focus request',start);method=s[start:end]
code='''package focus
class Node {let semanticId="body";let nodeId:Int64=190;let resourceId:Int64 = -1;let nodeKind:Int64=1;func canReceiveFocus():Bool{return false}}
class Scene {func nodes():Array<Node>{return [Node()]}}
func cjguiFocusNextAttemptCount(a:Int64,b:Bool):Int64{return a+1}
func cjguiFocusRetryAllowed(a:Int64,b:Bool):Bool{return false}
let CJGUI_INTERNAL_RENDERER_OK:Int32=0
class Window {
var pendingSemanticFocusNode:?Node=None
var pendingSemanticFocusAttempts:Int64=0
var pendingSemanticFocusBindingEpoch=0u64
var pendingScopedFocusScope:?String=None
var pendingScopedFocusKey=""
var lastNativeFailure=""
var focusedNodeId:Int64=190
var focusedResourceId:Int64 = -1
var focusedNodeKind:Int64=1
var ownedTextSessionNodeId:Int64=190
var reveals:Int64=0
var focuses:Int64=0
let nativeInputScene=Scene()
func ownedAnchorFocusable(n:Node):Bool{return true}
func revealAcceptedNodeIfNeeded(n:Int64):Bool{reveals+=1;return true}
func focusProjectedNode(n:Int64):Bool{focuses+=1;return true}
func currentAcceptedBindingEpoch(n:Node):UInt64{return 3u64}
func requestRefresh():Unit{}
METHOD
}
main():Int64 {
 let w=Window()
 var failures=0
 if(!w.focusAcceptedSemanticNode("body") || w.reveals!=0 || w.focuses!=1){println("FAIL owned focus reassert resets document viewport");failures+=1}else{println("PASS owned focus reassert keeps viewport")}
 w.reveals=0
 w.focusedNodeId=999
 if(!w.focusAcceptedSemanticNode("body") || w.reveals!=1){println("FAIL real focus navigation lost reveal");failures+=1}else{println("PASS real focus navigation retains reveal")}
 return failures
}
'''.replace('METHOD',method)
with tempfile.TemporaryDirectory(prefix='cjgui-focus-reassert-') as t:
 p=Path(t);p.joinpath('main.cj').write_text(code);subprocess.run(['cjc',str(p/'main.cj'),'-Woff','unused','-o',str(p/'test')],check=True);sys.exit(subprocess.run([str(p/'test')]).returncode)
