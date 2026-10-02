"""Exact production menu command: stale async return must not mutate any owner/draft.
Native guard and existing range enqueue are compiled together; mutation controls
remove text/version/range guards and must fail the very same binary assertions.
"""
from pathlib import Path
import unittest,subprocess,tempfile
import test_ime_range_delta_native as delta
ROOT=Path(__file__).resolve().parents[1]
SIG='bool editorApplyMenuCommandLocked('
MAIN=r'''
int main(int argc,char **argv){
 std::string t=argc>1?argv[1]:"";Session s;
 s.editingText=u"first\nalpha😆 tail";s.selStartUtf16=6;s.selEndUtf16=s.caretUtf16=11;
 s.editingContextGeneration=4;s.editingContextBaseVersion=7;
 s.ownedTextSessionEnabled=true;s.rangeEditDeltaRequested=true;
 s.editingNodeId=s.ownedTextSessionNodeId=10;s.editingResourceId=s.ownedTextSessionResourceId=1;
 s.editingNodeKind=s.ownedTextSessionNodeKind=10;s.ownedTextSessionBindingEpoch=9;
 auto expected=s.editingText;uint64_t gen=4,base=7;int start=6,end=11;std::string action="replace";
 std::u16string insert=u"X😆";
 if(t=="stale_text")expected+=u"old";
 if(t=="stale_version")base=6;
 if(t=="stale_generation")gen=3;
 if(t=="stale_range")start=5;
 if(t=="marked")s.markedActive=true;
 if(t=="restore")s.proxyRestore.armed=true;
 if(t=="drag")s.selectionDrag.active=true;
 if(t=="retired")s.editorRetired=true;
 if(t=="preview")s.previewActive=true;
 if(t=="bad_boundary"){s.selStartUtf16=start=12;s.selEndUtf16=end=13;}
 if(t=="bad_insert")insert=std::u16string(1,0xd800);
 if(t=="invalid")action="other";
 if(t=="all")action="selectAll";
 if(t=="copy")action="validate";
 if(t=="cut")insert=u"";
 if(t=="generic")s.ownedTextSessionEnabled=false;
 auto before=s.editingText;auto a=s.selStartUtf16,b=s.selEndUtf16;
 bool ok=editorApplyMenuCommandLocked(s,action,expected,insert,gen,base,start,end);
 if(t.rfind("stale_",0)==0||t=="marked"||t=="restore"||t=="drag"||t=="retired"||t=="preview"||t=="bad_boundary"||t=="bad_insert"||t=="invalid"){
  return !ok&&s.editingText==before&&s.selStartUtf16==a&&s.selEndUtf16==b&&s.events.empty()?0:30;
 }
 if(!ok)return 31;
 if(t=="copy")return s.editingText==before&&s.selStartUtf16==a&&s.selEndUtf16==b&&s.events.empty()?0:32;
 if(t=="all")return s.editingText==before&&s.selStartUtf16==0&&s.selEndUtf16==before.size()&&s.humanCaretNotificationPending?0:33;
 auto next=t=="cut"?u"first\n😆 tail":u"first\nX😆😆 tail";
 unsigned caret=t=="cut"?6:9;
 if(t=="generic")return s.editingText==before&&s.previewActive&&s.previewText==next&&s.caretUtf16==caret&&s.events.empty()?0:34;
 if(s.editingText!=next||s.selStartUtf16!=caret||s.selEndUtf16!=caret||s.events.size()!=1)return 35;
 auto e=s.events.front();auto replay=before.substr(0,e.selectionStart)+utf8ToUtf16(e.text)+before.substr(e.selectionEnd);
 return e.kind==51&&replay==next&&s.humanCaretNotificationPending?0:36;
}
'''
def harness(source):
 replica=delta.REPLICA.replace('struct Session {','''struct Session {
 bool editingContextLive=true,editorRetired=false,previewActive=false,markedActive=false;
 uint64_t editingContextGeneration=4,editingContextBaseVersion=7;
 uint32_t previewStart=0,previewEnd=0;std::u16string previewText;
 struct {bool armed=false,awaitingAck=false,platformInstalled=false;} proxyRestore;
 struct {bool active=false,terminal=false;} selectionDrag;
''')
 code=delta.STUBS+replica
 code+='static void cancelProxyRestoreRequest(Session&,const char*){}\n'
 code+='\n'.join(delta.extract_method(source,s) for s in delta.SIGNATURES)
 code+='\n'+delta.extract_method(source,SIG)+'\n'+MAIN
 return code
class TextMenuNativeTest(unittest.TestCase):
 def compile_run(self,source):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);(p/'main.cpp').write_text(harness(source))
   c=subprocess.run(['clang++','-std=c++17',str(p/'main.cpp'),'-o',str(p/'main')],capture_output=True,text=True)
   self.assertEqual(c.returncode,0,c.stderr)
   return {t:subprocess.run([str(p/'main'),t]).returncode for t in ['replace','cut','copy','all','generic','stale_text','stale_version','stale_generation','stale_range','marked','restore','drag','retired','preview','bad_boundary','bad_insert','invalid']}
 def test_exact_command(self):
  self.assertEqual(set(self.compile_run((ROOT/'host/ohos_renderer.cpp').read_text()).values()),{0})
 def test_guard_mutations_are_red(self):
  s=(ROOT/'host/ohos_renderer.cpp').read_text()
  for guard in ['expected != s.editingText','base != s.editingContextBaseVersion','static_cast<uint32_t>(start) != s.selStartUtf16']:
   with self.subTest(guard=guard):
    method=delta.extract_method(s,SIG);self.assertIn(guard,method)
    self.assertNotEqual(set(self.compile_run(s.replace(method,method.replace(guard,'false',1),1)).values()),{0})
if __name__=='__main__':unittest.main()
