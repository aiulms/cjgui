#!/usr/bin/env python3
"""Execute real editing layout acquisition and successful-publication ownership."""
from pathlib import Path
import subprocess,tempfile,sys
S=Path(__file__).resolve().parents[1]/'host/ohos_renderer.cpp'
def block(s,key):
 a=s.index(key);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
def run(withdraw=False):
 s=S.read_text();draw=s[s.index('    void drawNodeText('):];a=draw.index('        const bool reuseEditing') if '        const bool reuseEditing'in draw else draw.index('        Measured m')
 acquire=draw[a:draw.index('        if (!m.typography)',a)]
 helper=block(s,'static bool cjguiOhosCanReuseEditingTypography(') if 'static bool cjguiOhosCanReuseEditingTypography('in s else ''
 if withdraw:acquire=acquire.replace('const bool reuseEditing = isEditingNode &&','const bool reuseEditing = false &&')
 publish=block(s,'    void publishPaintedLayout(TextPaintFrame &frame)');publish=publish[publish.index('{')+1:publish.index('        // A2：整表替换')]
 code=r'''#include "cjgui_ohos_font_lease.h"
#include <memory>
#include <string>
#include <vector>
#include <cstdint>
#include <cstdio>
#include <chrono>
#define RLOGI(...) ((void)0)
int builds=0,destroyed=0;struct OH_Drawing_Typography{};
struct FontCollection{};using OhosFontPool=CjguiOhosFontPool<FontCollection>;
OhosFontPool testFontPool{[]{return new FontCollection;},[](FontCollection*p){delete p;}};
uint64_t activeFontConfiguration=1;
void OH_Drawing_DestroyTypography(OH_Drawing_Typography*p){if(p){++destroyed;delete p;}}
struct Pod{uint64_t nodeId=107,acceptedBindingEpoch=1;int resourceId=77;uint32_t nodeKind=6,fontWeight=400;double fontSize=16,textRed=1,textGreen=1,textBlue=1,textAlpha=1;int width=377;};
using CjguiInternalRendererComposableNode=Pod;
struct PaintedTextLayout {OhosFontPool::Lease fontLease;int64_t layoutSourceContext=1;uint64_t layoutOwnedBinding=1,layoutOwnedDeclaredBinding=1;std::unique_ptr<OH_Drawing_Typography,decltype(&OH_Drawing_DestroyTypography)>typography{nullptr,&OH_Drawing_DestroyTypography};Pod node;std::u16string text;uint64_t session=1,renderEpoch=1,generation=1,geometryRevision=1;void*window=(void*)1;int width=1320,height=2622;int64_t paintContext=1;double density=3.5;bool plainTextLayout=true,borrowsEditingTypography=false;};
struct TextPaintFrame{uint64_t session=1,ownedMirrorBindingEpoch=1,ownedMirrorDeclaredBindingEpoch=1;std::unique_ptr<PaintedTextLayout>candidate;};
struct Node{Pod pod;std::vector<int>textStyleRuns;};
struct Measured{OhosFontPool::Lease fontLease;OH_Drawing_Typography*typography=nullptr;double height=0,longestLine=0,maxWidth=0;size_t lineCount=0;double alphabeticBaseline=0;};
double OH_Drawing_TypographyGetHeight(OH_Drawing_Typography*){return 10;}double OH_Drawing_TypographyGetLongestLine(OH_Drawing_Typography*){return 1;}double OH_Drawing_TypographyGetMaxWidth(OH_Drawing_Typography*){return 377;}size_t OH_Drawing_TypographyGetLineCount(OH_Drawing_Typography*){return 1;}double OH_Drawing_TypographyGetAlphabeticBaseline(OH_Drawing_Typography*){return 8;}
Measured layoutTextStyled(const std::string&,double,uint32_t,double,bool,uint32_t,const int*,size_t){++builds;return {testFontPool.acquire(3,activeFontConfiguration),new OH_Drawing_Typography,10,1,377,1,8};}
HELPER
struct Renderer{OhosFontPool &fontPool=testFontPool;uint64_t fontConfigurationGeneration=1;std::unique_ptr<PaintedTextLayout>lastPaintLayout;uint64_t renderEpoch=1,boundGeneration=1,permitGeometryRevision=1;void*boundWindow=(void*)1;int surfaceW=1320,surfaceH=2622;double surfaceDensity=3.5;
 void paint(TextPaintFrame&frame,Node node,std::u16string editComposed=u"ABC",int64_t caretContext=1){bool isEditingNode=true;int64_t layoutSourceContext=caretContext;activeFontConfiguration=fontConfigurationGeneration;std::string text(editComposed.begin(),editComposed.end());uint32_t textColor=0;
ACQUIRE
 auto candidate=std::make_unique<PaintedTextLayout>();candidate->text=editComposed;candidate->node=node.pod;candidate->paintContext=caretContext;candidate->layoutSourceContext=layoutSourceContext;candidate->fontLease=m.fontLease;
#ifdef HAS_REUSE
 candidate->borrowsEditingTypography=reuseEditing;
 if(!reuseEditing)candidate->typography.reset(m.typography);
#else
 candidate->typography.reset(m.typography);
#endif
 frame.candidate=std::move(candidate);
 }
 void publish(TextPaintFrame&frame){PUBLISH}
};
int main(){Renderer r;Node n;{TextPaintFrame f;r.paint(f,n);r.publish(f);}auto*original=r.lastPaintLayout->typography.get();
 {TextPaintFrame failed;r.paint(failed,n);if(builds!=1){puts("FAIL unchanged source was laid out again");return 1;}if(r.lastPaintLayout->typography.get()!=original){return 2;}}
 if(destroyed!=0 || r.lastPaintLayout->typography.get()!=original)return 3;
 {TextPaintFrame success;r.paint(success,n);r.publish(success);if(r.lastPaintLayout->typography.get()!=original || builds!=1)return 4;}
 {TextPaintFrame changed;r.paint(changed,n,u"ABCD");if(builds!=2)return 5;}
 {TextPaintFrame binding;n.pod.acceptedBindingEpoch=2;r.paint(binding,n);if(builds!=3)return 6;}
 n.pod.acceptedBindingEpoch=1;
 {TextPaintFrame style;n.pod.fontSize=18;r.paint(style,n);if(builds!=4)return 7;}
 n.pod.fontSize=16;
 {TextPaintFrame context;r.paint(context,n,u"ABC",2);if(builds!=5)return 8;}
 {TextPaintFrame geometry;r.permitGeometryRevision=2;r.paint(geometry,n);if(builds!=6)return 9;}
 puts("PASS same layout reuse; failed frame keeps old ownership; text/style/binding/context/geometry invalidate");return 0;}
'''.replace('HELPER',helper).replace('ACQUIRE',acquire).replace('PUBLISH',publish)
 if helper:code='#define HAS_REUSE\n'+code
 with tempfile.TemporaryDirectory() as t:
  p=Path(t);(p/'a.cpp').write_text(code);subprocess.run(['clang++','-std=c++17','-I'+str(S.parent),str(p/'a.cpp'),'-o',str(p/'a')],check=True);return subprocess.run([str(p/'a')]).returncode
if __name__=='__main__':
 code=run()
 if code:sys.exit(code)
 if '--selftest'in sys.argv:
  r=run(True);print('isolated withdrawal RED:',r);sys.exit(99 if not r else 0)
