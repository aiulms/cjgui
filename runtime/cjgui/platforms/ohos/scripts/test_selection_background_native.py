#!/usr/bin/env python3
"""Production style admission: background decoration may overlap ordinary styles.
Tests keep the ordinary overlap rejection and bounded admission. Device frames
separately verify that the decoration is visible through the real painter.
"""
from pathlib import Path
import subprocess,tempfile,sys,re
s=(Path(__file__).resolve().parents[1]/'host/ohos_renderer.cpp').read_text()
def block(marker):
 a=s.index(marker);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
parser=block('static bool parseTextStyleRuns(')
if '--withdraw-guard' in sys.argv:
 old='if (out[i].selectionBackgroundOnly) continue;';assert parser.count(old)==1
 parser=parser.replace(old,'if (false && out[i].selectionBackgroundOnly) continue;')
code='''
#include <algorithm>
#include <string>
#include <vector>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
%STRUCT%;
static constexpr size_t kMaxTextStyleRunsPerNode=64;
%PARSER%
%UTF%
%OFFSET%
%ADMIT%
int main(){
 int failures=0;auto check=[&](bool ok,const char*n){std::printf("%s %s\\n",ok?"PASS":"FAIL",n);failures+=!ok;};std::vector<OhosTextStyleRun> runs,converted;
 const char*background="0:6:0:0:0:0:0:0:0:1:0.3:0.5:0.8:0.55:1";
 std::string ordinary="0:6:26:700:0:0.1:0.1:0.1:1";
 check(parseTextStyleRuns((ordinary+";"+background).c_str(),runs),"explicit selection background overlaps ordinary font run");
 check(!parseTextStyleRuns((ordinary+";0:3:12:400:0:0:0:0:1").c_str(),runs),"ordinary overlapping styles still refused");
 check(!parseTextStyleRuns("0:6:0:0:0:0:0:0:0:0:0.3:0.5:0.8:0.55:1",runs),"background-only flag requires a background");
 check(parseTextStyleRuns(background,runs) && admitTextRunsAgainstValue(runs,"中文",converted) && converted.size()==1 && converted[0].end==2,"decoration converts actual UTF-8 boundaries to UTF-16");
 check(!admitTextRunsAgainstValue(runs,"a",converted),"past current text end refused");
 parseTextStyleRuns("1:6:0:0:0:0:0:0:0:1:0.3:0.5:0.8:0.55:1",runs);
 check(!admitTextRunsAgainstValue(runs,"中文",converted),"decoration splitting a scalar refused");
 std::string batch;for(int i=0;i<65;++i){if(i)batch+=';';batch+=background;}
 check(!parseTextStyleRuns(batch.c_str(),runs),"existing 64-run budget retained");
 return failures;
}
'''
parts={'STRUCT':block('struct OhosTextStyleRun {'),'PARSER':parser,'UTF':block('std::u16string utf8ToUtf16('),'OFFSET':block('uint32_t utf8ByteOffsetToUtf16('),'ADMIT':block('static bool admitTextRunsAgainstValue(')}
code=re.sub(r'%(STRUCT|PARSER|UTF|OFFSET|ADMIT)%',lambda m:parts[m[1]],code)
with tempfile.TemporaryDirectory(prefix='h-selection-background-')as t:
 p=Path(t);p.joinpath('main.cpp').write_text(code);subprocess.run(['clang++','-std=c++17',str(p/'main.cpp'),'-o',str(p/'test')],check=True);sys.exit(subprocess.run([str(p/'test')]).returncode)
