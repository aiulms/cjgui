#ifndef CJGUI_OHOS_TEXT_COVERAGE_H
#define CJGUI_OHOS_TEXT_COVERAGE_H
#include "cjgui_ohos_focus_authority.h"
#include <algorithm>
#include <limits>
#include <memory>
#include <string>
#include <vector>
struct CjguiOhosEditOwnerReceipt;
struct CjguiOhosEditTicket;
// Immutable bounded facts shared by the candidate, actual layout and observations.
// No Typography or owner pointer crosses threads. Invalid UTF-16 offsets are -1.
struct CjguiOhosTextCoverage {
    int64_t ownerVersion=-1, layoutOrigin=-1, platformOrigin=-1, begin=-1, end=-1;
    uint64_t focus=0,node=0,acceptedBinding=0,ownerBinding=0;
    int64_t resource=-1; uint32_t kind=0;
    CjguiOhosProxyKey key;
    bool qualified=false;
    std::shared_ptr<const CjguiOhosTextCoverage> body; // Original present identity, never rebound.
    std::string bodyBasis;
    // Candidate/accepted declarations own the receipt while it can be consumed.
    // An observation keeps its original identity, not every preceding choice's
    // input payload. Immutable layout/platform facts below survive independently.
    std::weak_ptr<const CjguiOhosEditOwnerReceipt> acceptance;
    std::shared_ptr<const std::u16string> layout,platform;
    std::vector<int32_t> layoutBytes,platformBytes;
    static bool index(const std::u16string &s,std::vector<int32_t> &out) {
        out.assign(s.size()+1,-1);int64_t bytes=0;out[0]=0;
        for(size_t i=0;i<s.size();++i) {
            uint32_t c=s[i];
            if(c>=0xd800 && c<=0xdbff) {
                if(i+1==s.size() || s[i+1]<0xdc00 || s[i+1]>0xdfff)return false;
                c=0x10000+((c-0xd800)<<10)+(s[++i]-0xdc00);
            } else if(c>=0xdc00 && c<=0xdfff)return false;
            bytes+=c<0x80?1:c<0x800?2:c<0x10000?3:4;out[i+1]=bytes;
        }
        return bytes<=32768;
    }
    static bool local(const std::vector<int32_t>&index,int64_t byte,uint32_t &out) {
        // Scalar indexes contain -1 in surrogate interiors, so no binary search.
        for(size_t i=0;i<index.size();++i)if(index[i]==byte){out=static_cast<uint32_t>(i);return true;}
        return false;
    }
    static std::shared_ptr<const CjguiOhosTextCoverage> prove(CjguiOhosTextCoverage value) {
        if(!value.layout || !value.platform || value.ownerVersion<0 || value.layoutOrigin<0 || value.platformOrigin<0 ||
           value.layout->size()>12288 || !index(*value.layout,value.layoutBytes) || !index(*value.platform,value.platformBytes))return {};
        if(value.layoutOrigin>std::numeric_limits<int64_t>::max()-value.layoutBytes.back() ||
           value.platformOrigin>std::numeric_limits<int64_t>::max()-value.platformBytes.back())return {};
        value.begin=std::max(value.layoutOrigin,value.platformOrigin);
        value.end=std::min(value.layoutOrigin+value.layoutBytes.back(),value.platformOrigin+value.platformBytes.back());
        uint32_t la,lb,pa,pb;
        if(value.end<value.begin || !local(value.layoutBytes,value.begin-value.layoutOrigin,la) ||
           !local(value.layoutBytes,value.end-value.layoutOrigin,lb) ||
           !local(value.platformBytes,value.begin-value.platformOrigin,pa) ||
           !local(value.platformBytes,value.end-value.platformOrigin,pb) ||
           lb-la!=pb-pa || value.layout->compare(la,lb-la,*value.platform,pa,pb-pa)!=0)return {};
        return std::make_shared<const CjguiOhosTextCoverage>(std::move(value));
    }
    size_t retainedUnits()const {
        // Exact conservative charge, counted once per shared proof in the choice ledger.
        return layout->capacity()+((platform==layout)?0:platform->capacity())+
            (layoutBytes.capacity()+platformBytes.capacity())*sizeof(int32_t)/sizeof(char16_t)+
            (bodyBasis.capacity()+sizeof(CjguiOhosTextCoverage)+1)/sizeof(char16_t)+(body?body->retainedUnits():0);
    }
    bool position(bool fromLayout,uint32_t offset,int64_t &absolute)const {
        const auto &v=fromLayout?layoutBytes:platformBytes;
        if(offset>=v.size() || v[offset]<0)return false;
        absolute=(fromLayout?layoutOrigin:platformOrigin)+v[offset];return true;
    }
    bool source(bool fromLayout,uint32_t offset,int64_t &absolute)const {
        return position(fromLayout,offset,absolute) && absolute>=begin && absolute<=end;
    }
    bool map(bool fromLayout,uint32_t offset,uint32_t &out)const {
        int64_t absolute;
        return source(fromLayout,offset,absolute) && local(fromLayout?platformBytes:layoutBytes,
            absolute-(fromLayout?platformOrigin:layoutOrigin),out);
    }
};
using CjguiOhosCoverage=std::shared_ptr<const CjguiOhosTextCoverage>;
#endif
