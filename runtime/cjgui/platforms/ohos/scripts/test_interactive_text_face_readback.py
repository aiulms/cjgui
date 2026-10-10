#!/usr/bin/env python3
"""The actual accepted publisher reports an interactive presentation text face."""
from pathlib import Path
import importlib.util
import sys

path = Path(__file__).parent / 'test_readback_publish_consistency.py'
spec = importlib.util.spec_from_file_location('publisher', path)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
case = r'''
    auto block = mkNode(1000, "presentation-body", 0, 0, 333, 46, kKindText);
    block.pod.isInteractive = 1;
    auto label = mkNode(1001, "ordinary-label", 0, 46, 333, 46, kKindText);
    label.pod.isInteractive = 0;
    PendingSettlement textFace = p;
    textFace.projectionVersion = 40; textFace.ticketId = 40; textFace.frameIndex = 40;
    std::vector<SceneNode> presentation{block, label};
    publishSuccess(s2.token, textFace, presentation, 40, 40);
    show("PRESENTATION", s2.token);
    std::vector<SceneNode> labels{label};
    publishSuccess(s2.token, textFace, labels, 40, 40);
    show("LABEL_ONLY", s2.token);
'''
end = '    return 0;\n}\n'
assert m.MAIN.count(end) == 1
m.MAIN = m.MAIN.replace(end, case + end)
source = m.HOST.read_text()
if '--withdraw' in sys.argv:
    guard = 'if (n.pod.nodeKind != kOhosFaceTextKind && !(n.pod.nodeKind == kKindText && n.pod.isInteractive != 0)) continue;'
    assert source.count(guard) == 1
    source = source.replace(guard, 'if (n.pod.nodeKind != kOhosFaceTextKind) continue;')
out = m.run_probe(source)
assert 'faces=1 facesTruncated=0 F1000:presentation-body' in out['PRESENTATION'], out['PRESENTATION']
assert 'F1001:' not in out['PRESENTATION']
assert 'faces=0 facesTruncated=0' in out['LABEL_ONLY'], out['LABEL_ONLY']
print('PASS actual publisher: interactive text face, ordinary label exclusion, next accepted face reset')
