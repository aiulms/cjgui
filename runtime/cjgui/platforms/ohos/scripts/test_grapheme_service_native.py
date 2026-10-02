#!/usr/bin/env python3
"""Execute the production OHOS grapheme ABI against a real system ICU.

The macOS harness uses the SDK C declarations and the host system ICU, not a
fake segmenter. Device/HAP system-ICU evidence is recorded separately.
"""
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host/ohos_renderer.cpp"
SDK_INCLUDE = Path("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include")

PREFIX = r'''
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <memory>
#include <string>
#include <vector>
#include <dlfcn.h>
#include <unicode/ubrk.h>
#include <unicode/ustring.h>
#define RLOGW(...) ((void)0)
enum CjguiInternalRendererStatus {
 CJGUI_INTERNAL_RENDERER_OK=0, CJGUI_INTERNAL_RENDERER_INVALID_UTF8=14,
 CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED=16,
 CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID=24,
 CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED=32,
 CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR=99
};
'''

MAIN = r'''
static int failures=0;
static void query(const std::string& text,uint64_t declared,uint64_t offset,
                  int expected,uint64_t lo=0,uint64_t hi=0) {
 uint64_t start=123,end=456;
 auto status=cjgui_internal_renderer_grapheme_cluster_range(text.c_str(),declared,offset,&start,&end);
 if(status!=expected||start!=lo||end!=hi){
  fprintf(stderr,"range failed offset=%llu status=%d range=%llu:%llu expected=%d/%llu:%llu\n",
   (unsigned long long)offset,status,(unsigned long long)start,(unsigned long long)end,expected,
   (unsigned long long)lo,(unsigned long long)hi);++failures;
 }
}
int main() {
 const std::vector<std::string> clusters={"e\xCC\x81", "a\xCC\x81\xCC\x88",u8"中",u8"👨‍👩‍👧‍👦",u8"👍🏽",u8"🇨🇳","\r\n"};
 for(const auto& cluster:clusters){
  std::string text="X"+cluster+"Y";
  for(size_t i=1;i<1+cluster.size();++i){
#ifdef EXPECT_UNAVAILABLE
   query(text,text.size(),i,32);
#else
   query(text,text.size(),i,0,1,1+cluster.size());
#endif
  }
 }
#ifndef EXPECT_UNAVAILABLE
 query("a",1,0,0,0,1);
 query("a",1,1,24);
 query("",0,0,24);
 query("a",0,0,14);
 query("abc",2,0,14);
 query(std::string("a\0b",3),3,0,14);
 query(std::string("\xC0\xAF",2),2,0,14);
 query(std::string("\xED\xA0\x80",3),3,0,14);
 query(std::string("\xE4\xB8",2),2,0,14);
 query("a",UINT64_MAX,0,16);
 uint64_t start=123;
 if(cjgui_internal_renderer_grapheme_cluster_range("a",1,0,&start,nullptr)!=99||start!=0)++failures;
#endif
 return failures?1:0;
}
'''


def production_service():
    source = SOURCE.read_text()
    begin = "// OHOS_GRAPHEME_SERVICE_BEGIN"
    end = "// OHOS_GRAPHEME_SERVICE_END"
    if begin in source:
        return source[source.index(begin):source.index(end) + len(end)]
    start = source.index('extern "C" CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(')
    return source[start:source.index("// 关闭链第 5 步", start)]


class SystemGraphemeTests(unittest.TestCase):
    def compile_and_run(self, unavailable=False):
        with tempfile.TemporaryDirectory(prefix="cjgui-ohos-grapheme-") as tmp:
            tmp = Path(tmp)
            lib = "/definitely/missing/cjgui-icu.so" if unavailable else "/usr/lib/libicucore.dylib"
            flags = f'#define CJGUI_OHOS_ICU_LIBRARY "{lib}"\n'
            if unavailable:
                flags += "#define EXPECT_UNAVAILABLE 1\n"
            source = tmp / "main.cpp"
            source.write_text(PREFIX + flags + production_service() + MAIN)
            build = subprocess.run(["xcrun", "clang++", "-std=c++17", "-idirafter", str(SDK_INCLUDE),
                                    str(source), "-o", str(tmp / "probe")], capture_output=True, text=True)
            self.assertEqual(build.returncode, 0, build.stderr)
            run = subprocess.run([str(tmp / "probe")], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_real_system_clusters_all_internal_bytes_and_invalid_inputs(self):
        self.compile_and_run()

    def test_unavailable_service_never_falls_back_to_scalars(self):
        self.compile_and_run(unavailable=True)


if __name__ == "__main__":
    unittest.main()
