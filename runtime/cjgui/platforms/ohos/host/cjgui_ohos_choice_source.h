#ifndef CJGUI_OHOS_CHOICE_SOURCE_H
#define CJGUI_OHOS_CHOICE_SOURCE_H
#include "cjgui_ohos_focus_authority.h"
#include <array>
#include <charconv>
#include <memory>
#include <vector>
#include <algorithm>
// Session-lock confined. Origins are immutable; an adoption receipt is separate.
struct CjguiOhosSourceBasis {
    std::array<int64_t,12> value{};
    bool valid = false;
    explicit CjguiOhosSourceBasis(const std::string &text) {
        const char *at=text.data(), *end=at+text.size();
        for(size_t i=0;i<12;++i) {
            const char *stop=std::find(at,end,',');
            auto r=std::from_chars(at,stop,value[i]);
            if(r.ec!=std::errc{} || r.ptr!=stop || at==stop || value[i]<0 ||
               (i<11 && stop==end) || (i==11 && stop!=end)) return;
            at=stop==end ? end : stop+1;
        }
        valid=value[10]<=value[11];
    }
    bool sameBody(const CjguiOhosSourceBasis &b) const {
        return valid && b.valid && std::equal(value.begin(),value.begin()+6,b.value.begin());
    }
};
struct CjguiOhosChoiceOrigin {
    uint32_t sourceKind=1; uint64_t restoreRequest=0,refusedInputId=0;int64_t restoreDeadline=0;
    uint64_t id=0, focus=0, node=0, acceptedBinding=0, ownerBinding=0, predecessor=0;
    int64_t resource=-1; uint32_t kind=0,start=0,end=0;
    CjguiOhosProxyKey key;
    std::u16string text; std::string bodyBasis;
};
struct CjguiOhosChoiceReceipt {
    std::shared_ptr<const CjguiOhosChoiceOrigin> origin;
    bool settled=false, accepted=false;
    std::string basis;
};
class CjguiOhosChoiceSources {
public:
    using Receipt=std::shared_ptr<CjguiOhosChoiceReceipt>;
    Receipt observe(CjguiOhosChoiceOrigin origin) {
        reap(); size_t units=origin.text.size();
        for(auto &w:live_) if(auto p=w.lock()) units+=p->origin->text.size();
        if(live_.size()>=32 || units>1048576) return {};
        origin.id=++next_; auto r=std::make_shared<CjguiOhosChoiceReceipt>();
        r->origin=std::make_shared<const CjguiOhosChoiceOrigin>(std::move(origin));
        live_.push_back(r); latest_=r; return r;
    }
    bool settle(const Receipt &r,bool accepted,const std::string &basis) {
        if(!r)return false;
        if(r->settled)return r->accepted==accepted && r->basis==basis;
        if(accepted) {
            CjguiOhosSourceBasis old(r->origin->bodyBasis), next(basis);
            if(!old.sameBody(next) || next.value[10]!=r->origin->start || next.value[11]!=r->origin->end) return false;
        }
        r->basis=basis;r->accepted=accepted;r->settled=true;
        // Older FIFO receipts can resolve their dependent tickets but never replace the published choice.
        if(accepted && (!published_ || r->origin->id>published_->origin->id)) published_=r;
        return true;
    }
    Receipt latest()const{return latest_;}
    Receipt published()const{return published_;}
    void clear(){latest_.reset();published_.reset();reap();}
    size_t liveCount(){reap();return live_.size();}
private:
    void reap(){live_.erase(std::remove_if(live_.begin(),live_.end(),[](const auto&w){return w.expired();}),live_.end());}
    uint64_t next_=0;
    Receipt latest_,published_;
    std::vector<std::weak_ptr<CjguiOhosChoiceReceipt>> live_;
};
#endif
