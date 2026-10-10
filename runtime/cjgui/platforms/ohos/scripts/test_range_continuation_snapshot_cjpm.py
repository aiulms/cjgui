#!/usr/bin/env python3
"""Real snapshot text-session + production window range handoff seam.

Only event/scene/controller storage and the unused grapheme service are stubs.
The real Source/Sink test owner, actual snapshot range/session code, window
routing, accepted-local stamping and continuation resolver are exercised.
"""
from pathlib import Path
import re, shutil, subprocess, tempfile, sys
HERE=Path(__file__).resolve().parent
SNAPSHOT=HERE.parent/'snapshot/src'
WINDOW=SNAPSHOT/'composable_ui_window.cj'
ROOT=HERE.parents[2]

def balanced(source,start):
    opening=source.index('{',start);depth=0
    for i in range(opening,len(source)):
        if source[i]=='{':depth+=1
        elif source[i]=='}':
            depth-=1
            if depth==0:return source[start:i+1]
    raise ValueError('unbalanced production source')

def method(source,name):
    marker=f'    private func {name}('
    assert source.count(marker)==1,name
    return balanced(source,source.index(marker)).replace(marker,f'    func {name}(',1)

def harness(red=None):
    source=WINDOW.read_text()
    owner_source=(ROOT/'src/text_session_test.cj').read_text()
    owner=balanced(owner_source,owner_source.index('class FakeTextOwner <:'))
    # Test-owner only: exercise a normalized Sink result against real session
    # reads. No production owner or window decision is replaced. 两处替换都必须
    # 命中（静默漂移会让 normalizeNext 失效、归一化用例假通过）。
    _reject_anchor='    var rejectAll: Bool = false'
    assert owner.count(_reject_anchor)==1,'owner rejectAll anchor drift'
    owner=owner.replace(_reject_anchor,_reject_anchor+'\n    var normalizeNext: Bool = false',1)
    _splice_anchor='this.splice(startByte, endByte, inserted)\n        if (this.refuseReadsAfterNextAccept) {'
    assert owner.count(_splice_anchor)==1,'owner splice anchor drift'
    owner=owner.replace(_splice_anchor,
                        'this.splice(startByte, endByte, if (normalizeNext) { "normalized" } else { inserted })\n        if (this.refuseReadsAfterNextAccept) {',1)
    # The old compact owner throws beyond EOF. Real bounded sources return an
    # EOF-adjusted slice after a wide replacement shortens the document.
    eof='let start = if (startByte < 0) { 0 } else { startByte }'
    assert owner.count(eof)==1
    owner=owner.replace(eof,'let start = min(max(startByte, 0), Int64(this.data.size))',1)
    selection_owner=(ROOT/'src/text_selection_authority_test.cj').read_text()
    owner+='\n'+balanced(selection_owner,selection_owner.index('class SelectionAuthorityTestOwner <:'))
    wide_owner=(ROOT/'src/text_selection_wide_input_test.cj').read_text()
    owner+='\n'+balanced(wide_owner,wide_owner.index('class WideSelectionInputTestOwner <:'))
    authority=(SNAPSHOT/'text_selection_authority.cj').read_text()
    authority=authority[authority.index('public class CjguiSourceSelectionSnapshot'):]
    constants='\n'.join(re.findall(r'^public let CJGUI_COMPOSABLE_UI_(?:TEXT_INPUT|INTEGER_INPUT|MULTILINE_TEXT_INPUT): Int64 = \d+$',(SNAPSHOT/'composable_ui.cj').read_text(),re.M))
    marker='                    if (nativeEvent.eventKind == 28u32 && dispatch.didApply && isEditableTextNodeKind('
    assert source.count(marker)==1
    start=source.index(marker);end=source.index('                    if (nativeEvent.eventKind == 31u32 && controller.uiSceneVersion()',start)
    stamp=source[start:end]
    methods='\n'.join(method(source,n) for n in ('finishOhosInput','noteRefusedOhosInput','flushOhosInputCompletions','admitOhosRangeInput','routeOwnedTextSessionRangeEdit','resolveLocalTextContinuation','isEditableTextNodeKind','clearLocalTextContinuation','clearPendingLocalTextValue','ownedTextBindingHolds','recordOwnedRangeLocalAcceptance','resolveOwnedRangeContinuation','ownedRangeMirrorMatches','noteUnresolvedOwnedRangeEvent','adoptOwnedTextSelection'))
    methods+='\n'+method(source,'resolvePlatformSelectionEvent')
    local_class=balanced(source,source.index('private class CjguiLocalRangeContinuation {')).replace('private class','class',1)
    local_class+='\n'+balanced(source,source.index('private class CjguiOhosRangeInputAdmission {')).replace('private class','class',1)
    binding_func=balanced(source,source.index('func cjguiSameFocusedTextBinding('))
    binding_func+='\n'+balanced(source,source.index('func cjguiSameOwnedAnchorBinding('))
    runtime=(SNAPSHOT/'runtime_renderer_session.cj').read_text()
    constants+='\n'+balanced(runtime,runtime.index('class CjguiOhosInputTicketFact {'))
    constants+='\nvar testInputOrigin: ?CjguiOhosInputTicketFact = None\nfunc internalRendererInputTicket(token: UInt64): ?CjguiOhosInputTicketFact { return testInputOrigin }'
    constants+='\nfunc internalRendererWindowLog(message: String): Unit {}'
    constants+='\n'+authority
    constants+='\n'+local_class+'\n'+binding_func+'\n'+ '\n'.join(re.findall(r'^private let CJGUI_OWNED_SELECTION_[^\n]+',source,re.M)).replace('private let','let')
    selection_source=balanced((SNAPSHOT/'composable_ui.cj').read_text(),(SNAPSHOT/'composable_ui.cj').read_text().index('    public func resolveSelection('))
    template=HERE/'fixtures/range_continuation_snapshot_harness.cj.txt'
    result=template.read_text().replace('// @CONSTANTS',constants).replace('// @OWNER',owner).replace('// @METHODS',methods).replace('// @STAMP',stamp).replace('// @RESOLVE_SELECTION',selection_source)
    if red is not None:
        old,new=RED_GUARDS[red]
        assert result.count(old)==1,(red,result.count(old))
        result=result.replace(old,new,1)
    return result

RED_GUARDS={
    'postimage-origin':('let proposedOrigin = sourceStart - prefix','let proposedOrigin = beforeMirror.startByte'),
    'input-source-choice':('rootBasis == basis && t.before == session.mirrorText()', 'true && t.before == session.mirrorText()'),
    'owner-revision':('mirror.sourceVersion == c.mirror.contentVersion','true'),
    'exact-postimage':('!exactLocalPostimage || !before.prepared','false || !before.prepared'),
    'full-mirror':('pendingLocalTextValue = after.text','pendingLocalTextValue = eventText'),
    'selection-context':('nativeEvent.nodeId == 0u64 || nativeEvent.recordIndex != 0u32','nativeEvent.nodeId == 0u64'),
    'selection-postimage':('eventText != mirror.text','false'),
    'selection-bounds':('cjguiUtf16OffsetToUtf8(mirror.text, Int64(nativeEvent.selectionEnd)).isNone()','false'),
    'binding':('nativeEvent.bindingEpoch != 0u64 && nativeEvent.bindingEpoch != textSessionBindingEpoch','false'),
}

def run(red=None):
    with tempfile.TemporaryDirectory(prefix='cjgui-ohos-range-continuation-') as tmp:
        root=Path(tmp)
        subprocess.run(['cjpm','init','--name','cjgui','--type=static'],cwd=root,check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        src=root/'src'
        for p in src.glob('*.cj'):p.unlink()
        for name in ('text_session.cj','range_text.cj'):shutil.copy2(SNAPSHOT/name,src/name)
        (src/'window_harness.cj').write_text(harness(red))
        shutil.copy2(HERE/'fixtures/range_continuation_snapshot_test.cj',src/'range_continuation_snapshot_test.cj')
        p=subprocess.run(['cjpm','test','--no-color','--no-progress'],cwd=root,capture_output=True,text=True)
        sys.stdout.write(p.stdout);sys.stderr.write(p.stderr)
        return p.returncode

if __name__=='__main__':
    clean=run()
    if clean:sys.exit(clean)
    if '--selftest' in sys.argv:
        for red in RED_GUARDS:
            code=run(red)
            print(f'[negative-control:{red}] exit={code}')
            if code==0:sys.exit(1)
    print('PASS actual snapshot session + production window range continuation')
