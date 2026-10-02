#!/usr/bin/env python3
"""Production plain-change entry: unchanged mount echoes preserve placed ranges.

Device RED: first long press after blur painted 5:10; TextInput's unchanged
onChange then collapsed native to 60:60 before its selection installation.
Compile the actual common entry plus the actual range-delta implementation.
"""
import pathlib
import subprocess
import tempfile
import unittest
import test_ime_range_delta_native as delta

SOURCE = delta.SOURCE
SIGNATURE = 'bool editorCommitPlainChangeLocked(Session &s, const std::u16string &next)'
GUARD = '    if (next == s.editingText && !s.previewActive && !s.markedActive) return true;\n'
MAIN = r'''
int main() {
  const std::u16string text=u"first\nsecond\nthird";
  for (bool range : {false,true}) {
    Session s; s.ownedTextSessionEnabled=s.rangeEditDeltaRequested=true;
    s.editingNodeId=s.ownedTextSessionNodeId=107;
    s.editingResourceId=s.ownedTextSessionResourceId=1;
    s.editingNodeKind=s.ownedTextSessionNodeKind=10;
    s.editingProjectionVersion=3;s.ownedTextSessionBindingEpoch=9;
    s.editingText=text;s.selStartUtf16=6;s.selEndUtf16=s.caretUtf16=range?12:6;
    s.caretAffinity=1;s.humanCaretNotificationPending=true;
    s.textMenuIntent=2;
    if(!editorCommitPlainChangeLocked(s,text))return 10;
    if(s.selStartUtf16!=6||s.selEndUtf16!=(range?12u:6u)||s.caretUtf16!=(range?12u:6u))return 11;
    if(s.cancelCount||!s.events.empty()||s.editingText!=text||s.caretAffinity!=1||
       !s.humanCaretNotificationPending||s.caretBlinkResetPending)return 12;
    if(s.textMenuIntent!=2)return 21; // a mount echo has no new user intent
    // Distinct text still cancels the old restoration and emits one exact delta.
    if(!editorCommitPlainChangeLocked(s,u"first\nsecondX\nthird"))return 13;
    if(s.cancelCount!=1||s.events.size()!=1||s.editingText!=u"first\nsecondX\nthird")return 14;
    if(s.textMenuIntent!=0)return 22;
    const auto &ev=s.events.front();
    if(ev.kind!=51||ev.selectionStart!=12||ev.selectionEnd!=12||ev.text!="X")return 15;
    if(!editorCommitPlainChangeLocked(s,text)||s.textMenuIntent!=0)return 23; // type/delete back cannot revive a menu
  }
  // Equal owner text can also mean real composition cancellation/settlement.
  // A live preview must still be cleared through the original common entry.
  for(bool marked:{false,true}) {
    Session s;s.ownedTextSessionEnabled=s.rangeEditDeltaRequested=true;
    s.editingNodeId=s.ownedTextSessionNodeId=107;
    s.editingResourceId=s.ownedTextSessionResourceId=1;
    s.editingNodeKind=s.ownedTextSessionNodeKind=10;
    s.editingText=text;s.previewActive=true;s.previewText=u"draft";s.markedActive=marked;
    if(!editorCommitPlainChangeLocked(s,text)||s.cancelCount!=1||s.previewActive||
       !s.previewText.empty()||s.markedActive||s.events.size()!=1||
       s.events.front().kind!=kEvTextChanged||s.events.front().text!="first\nsecond\nthird")return 16;
  }
  Session other;other.editingText=text;other.selStartUtf16=6;other.selEndUtf16=12;
  if(!editorCommitPlainChangeLocked(other,text)||other.cancelCount||
     other.selStartUtf16!=6||other.selEndUtf16!=12)return 17;
  // The actual generic preview entry must treat a mount echo as no draft.
  currentSession=&other;other.caretUtf16=12;
  if(ohos_renderer_ime_preview_text_ctx("first\nsecond\nthird",18,1)!=0||
     other.previewActive||other.markedActive||other.caretUtf16!=12||
     other.selStartUtf16!=6||other.selEndUtf16!=12||!other.events.empty())return 18;
  // Distinct generic text remains a draft and never writes the explicit-submit owner.
  if(ohos_renderer_ime_preview_text_ctx("warmX",5,1)!=0||!other.previewActive||
     other.previewText!=u"warmX"||other.editingText!=text||!other.events.empty())return 19;
  // Returning to the original value while a draft is active still preserves
  // generic explicit-submit semantics, rather than silently canceling it.
  if(ohos_renderer_ime_preview_text_ctx("first\nsecond\nthird",18,1)!=0||
     !other.previewActive||composedBuffer(other)!=text||!other.events.empty())return 20;
  return 0;
}
'''

GENERIC_MAIN = r'''
int main(){
  Session s;s.editingText=u"warm";s.selStartUtf16=0;s.selEndUtf16=s.caretUtf16=4;
  currentSession=&s;
  if(ohos_renderer_ime_preview_text_ctx("warm",4,1)!=0)return 30;
  if(s.previewActive||s.markedActive||!s.events.empty()||s.cancelCount)return 31;
  if(s.selStartUtf16!=0||s.selEndUtf16!=4||s.caretUtf16!=4)return 32;
  return 0;
}
'''

def harness(source,main=MAIN):
    replica=delta.REPLICA.replace('struct Session {','struct Session {\n  bool previewActive=false,markedActive=false;\n  uint32_t previewStart=0,previewEnd=0;\n  std::u16string previewText;\n  int cancelCount=0;')
    replica=replica.replace('static std::u16string composedBuffer(Session &s) { return s.editingText; }',delta.extract_method(source,'std::u16string composedBuffer(const Session &s)\n{'))
    code='#include <mutex>\n#include <memory>\n'+delta.STUBS+replica
    code+='static void cancelProxyRestoreRequest(Session &s,const char*){++s.cancelCount;}\n'
    code+='struct { std::mutex lock; } g_sessions;\nstatic Session *currentSession=nullptr;\nstatic Session *takeEditingContextLocked(int64_t id){return id==1?currentSession:nullptr;}\nstruct RedrawJob{};\nstruct { void post(std::shared_ptr<RedrawJob>){} } g_render;\n'
    code+='\n'.join(delta.extract_method(source,s) for s in delta.SIGNATURES)
    return code+'\n'+delta.extract_method(source,SIGNATURE)+'\n'+delta.extract_method(source,'extern "C" int32_t ohos_renderer_ime_preview_text_ctx(')+'\n'+main

class PlainMountEchoNativeTest(unittest.TestCase):
    def run_source(self,source,main=MAIN):
        with tempfile.TemporaryDirectory() as tmp:
            p=pathlib.Path(tmp);cpp=p/'echo.cpp';cpp.write_text(harness(source,main));exe=p/'echo'
            q=subprocess.run(['clang++','-std=c++17','-Wall','-Wextra','-Werror',str(cpp),'-o',str(exe)],capture_output=True,text=True)
            self.assertEqual(q.returncode,0,q.stderr)
            return subprocess.run([str(exe)],capture_output=True,text=True).returncode

    def test_unchanged_echo_and_real_changes(self):
        self.assertEqual(self.run_source(SOURCE.read_text()),0)

    def test_actual_generic_preview_entry_has_no_false_preview(self):
        self.assertEqual(self.run_source(SOURCE.read_text(),GENERIC_MAIN),0)

    def test_negative_owned_only_echo_guard(self):
        source=SOURCE.read_text();ownership='    if (!editorOwnsTextSession(s)) {\n        return false;\n    }\n'
        current=delta.extract_method(source,SIGNATURE)
        changed=current.replace(ownership,'').replace(GUARD,ownership+GUARD)
        self.assertNotEqual(self.run_source(source.replace(current,changed),GENERIC_MAIN),0)

    def test_negative_without_echo_guard(self):
        source=SOURCE.read_text();self.assertIn(GUARD,source)
        self.assertNotEqual(self.run_source(source.replace(GUARD,'')),0)

    def test_negative_guard_must_not_swallow_real_changes(self):
        source=SOURCE.read_text();self.assertIn(GUARD,source)
        self.assertNotEqual(self.run_source(source.replace(GUARD,'    return true;\n')),0)

if __name__=='__main__':
    unittest.main()
