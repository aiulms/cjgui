#!/usr/bin/env python3
from pathlib import Path
import subprocess,tempfile,sys
P=Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src/pharos_ohos_controller.cj')
def block(s,key):
 a=s.index(key);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
def run(withdraw=False):
 s=P.read_text();replace=block(s,'public func replaceDocument(')
 if withdraw:replace=replace.replace('case Some(window) => this.rebindBodySession()','case Some(window) => true')
 code='''package test
import std.collection.*
let CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT=10
let PHAROS_OHOS_SMALL_DOCUMENT_MAX_BYTES=262144
func pharosOhosPrivateFilesDir():String {return "/owned"}
func pharosOhosPublishWorkingBinding(root:String,id:String,pending:String):String {return ""}
class Owner {let documentId:String;let sessionEpoch:Int64=1;init(id:String){documentId=id};func contentVersion():Int64{return 1};func savedContentVersion():Int64{return 1};func byteLength():Int64{return 10}}
class PharosDocumentService {let session:Owner;init(id:String){session=Owner(id)}}
class PharosSessionRangeBridge {let owner:String;init(s:PharosDocumentService,viewId!:String=""){owner=s.session.documentId}}
class Range {let owner:String;init(id:String){owner=id};func isBound():Bool{return true};func boundNode():Int64{return 107}}
class CjguiComposableUiWindow {var releases=0;var binds=0;var owner="old";func releaseTextSession():Unit{releases+=1};func bindRangeTextSession(node:Int64,semantic:String,reader:PharosSessionRangeBridge,writer:PharosSessionRangeBridge,res:Int64,kind:Int64,materializeLimit!:Int64=0,compositionArbitration!:Bool=false):Range{binds+=1;owner=reader.owner;return Range(owner)}}
class Ids {let editor=107;let visualCarrier=190}
class PharosFragmentPresentation {}
class Controller {
 var service=PharosDocumentService("old");var bridge=PharosSessionRangeBridge(service);var boundWindow:?CjguiComposableUiWindow=None;var session:?Range=Some(Range("old"));let ids=Ids()
 var documentBindingFailure="";var activeOwnerIsNote=false;var noteBound=false;var boundSessionDocumentId="old";var boundSessionEpoch=1;var lastSessionDecisionCount=0;var visualVersion=1;var visualFragments:Array<PharosFragmentPresentation>=[];var cachedVisualBinding:?Int64=None;var acceptedVisualBinding:?Int64=None;var candidateVisualBinding:?Int64=None;var previewMode=false;var focusReassertRequested=false;var revision=1;var commandCount=0;var lastCommandFact=""
 func resetVisualEditState():Unit{}
 PREVIEW
 REBIND
 REPLACE
}
main():Int64{let w=CjguiComposableUiWindow();let c=Controller();c.boundWindow=Some(w);if(!c.replaceDocument(PharosDocumentService("new"))){return 2};if(w.releases!=1 || w.binds!=1 || w.owner!="new" || c.session.isNone() || c.boundSessionDocumentId!="new"){println("FAIL imported owner has no current range session");return 1};println("PASS imported owner rebinds the existing source session before focus");return 0}
'''.replace('PREVIEW',block(s,'private func previewBoundNode():')).replace('REBIND',block(s,'public func rebindBodySession():')).replace('REPLACE',replace)
 with tempfile.TemporaryDirectory() as t:
  p=Path(t);(p/'a.cj').write_text(code);subprocess.run(['cjc',str(p/'a.cj'),'-Woff','unused','-o',str(p/'a')],check=True);return subprocess.run([str(p/'a')]).returncode
if __name__=='__main__':
 r=run()
 if r:sys.exit(r)
 if '--selftest'in sys.argv:
  red=run(True);print('isolated withdrawal RED:',red);sys.exit(99 if not red else 0)
