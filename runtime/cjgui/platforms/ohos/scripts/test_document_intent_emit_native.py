#!/usr/bin/env python3
"""The real emitter must report a failed delivery rather than a queued success."""
from pathlib import Path
import subprocess
import tempfile
import sys
SRC = Path(__file__).resolve().parents[1] / 'host/ohos_renderer.cpp'
def run():
    source = SRC.read_text()
    start = source.index('void (*g_documentIntentSink)') if 'void (*g_documentIntentSink)' in source else source.index('int32_t (*g_documentIntentSink)')
    end = source.index('void ohos_renderer_ime_preview_text', start)
    production = source[start:end]
    returning = 'int32_t (*g_documentIntentSink)' in production
    callback = 'int32_t failSink(const char*) { return 0; }' if returning else 'void failSink(const char*) {}'
    code = '#include <cstdint>\n#include <cstdio>\n' + production + callback + '''
int main() {
  if (cjgui_ohos_emit_document_intent("request") != 0) return 2;
  ohos_renderer_set_document_intent_sink(failSink);
  const int result = cjgui_ohos_emit_document_intent("request");
  std::printf("%s failed delivery result=%d\\n", result == 0 ? "PASS" : "FAIL", result);
  return result == 0 ? 0 : 1;
}
'''
    with tempfile.TemporaryDirectory(prefix='cjgui-intent-emit-') as temp:
        root = Path(temp); (root/'main.cpp').write_text(code)
        subprocess.run(['clang++', '-std=c++17', str(root/'main.cpp'), '-o', str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode
if __name__ == '__main__': sys.exit(run())
