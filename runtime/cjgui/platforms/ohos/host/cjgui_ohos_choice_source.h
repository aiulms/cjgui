#ifndef CJGUI_OHOS_CHOICE_SOURCE_H
#define CJGUI_OHOS_CHOICE_SOURCE_H
#include "cjgui_ohos_focus_authority.h"
#include "cjgui_ohos_text_coverage.h"
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
// Input-scoped source fact, without a Ticket/Choice ancestor. The original
// accepted drawing body and the execution's platform prestate stay distinct.
struct CjguiOhosInputSourceLeaf {
    CjguiOhosCoverage coverage,acceptedBody;
    CjguiOhosProxyKey key;
    uint64_t focus=0,command=0,execution=0,publication=0,attach=0,install=0;
    int64_t ownerVersion=-1,selectionRevision=-1,anchor=-1,active=-1;
    int64_t firstObservation=-1,admittedAt=-1,notAfter=0;
    uint32_t start=0,end=0;
    bool installed=false;
    size_t retainedUnits()const{return (sizeof(*this)+1)/sizeof(char16_t);}
};
// A publication dependency contains original Will facts, never a Choice/Ticket ancestor.
struct CjguiOhosPublicationDependency {
    uint64_t id=0,predecessor=0,focusGeneration=0,node=0,acceptedBinding=0,ownerBinding=0;
    CjguiOhosProxyKey key;int64_t resource=-1;uint32_t kind=0,start=0,end=0,afterStart=0,afterEnd=0;
    std::string field;std::u16string before,after;
    int64_t frozenVersion=-1,frozenOrigin=-1;std::string frozenBasis;
    std::shared_ptr<const CjguiOhosInputSourceLeaf> sourceLeaf;
    size_t retainedUnits()const{return before.capacity()+after.capacity()+(field.capacity()+frozenBasis.capacity()+sizeof(*this)+1)/2;}
};
struct CjguiOhosChoiceOrigin {
    bool capturedCommand=false; // Dedicated physical producer; ordinary observations never set this.
    uint32_t sourceKind=1; uint64_t restoreRequest=0,refusedInputId=0;int64_t restoreDeadline=0;
    uint64_t id=0, focus=0, node=0, acceptedBinding=0, ownerBinding=0, predecessor=0;
    int64_t resource=-1; uint32_t kind=0,start=0,end=0; int64_t sourceAnchor=-1,sourceFocus=-1;
    CjguiOhosProxyKey key;
    std::u16string text; std::string bodyBasis;
    CjguiOhosCoverage coverage; uint64_t layoutSerial=0,humanAnchor=0; int64_t deadline=0;
    std::vector<uint64_t> prefix;
    std::vector<std::shared_ptr<const CjguiOhosPublicationDependency>> prefixOrigins;
    uint64_t coordinateAfter=0; // 0 is the published starting body; otherwise an actual platform-completed member.
};
struct CjguiOhosChoiceReceipt {
    std::shared_ptr<const CjguiOhosChoiceOrigin> origin;
    bool settled=false, accepted=false;
    bool platformInstalled=false; // Semantic selection command: owner and platform confirmations are independent.
    std::string basis,reason;
    int64_t ownerVersion=-1,postOrigin=-1,anchorByte=-1,focusByte=-1;
    CjguiOhosCoverage resolvedCoverage; bool requiresRebase=false;
    CjguiOhosCoverage commandCoverage; // Installed target proof retained by its original Q/input roots.
    // Original observation coordinates, independent from accepted display/layout coverage.
    int64_t coordinateVersion=-1,coordinateOrigin=-1,coordinateAnchor=-1,coordinateFocus=-1;
};
class CjguiOhosChoiceSources {
public:
    using Receipt=std::shared_ptr<CjguiOhosChoiceReceipt>;
    Receipt observe(CjguiOhosChoiceOrigin origin) {
        reap();
        if(live_.size()>=32 || retainedUnits(&origin)>1048576) return {};
        origin.id=++next_; auto r=std::make_shared<CjguiOhosChoiceReceipt>();
        r->origin=std::make_shared<const CjguiOhosChoiceOrigin>(std::move(origin));
        live_.push_back(r); awaiting_.push_back(r);latest_=r;return r;
    }
    bool settle(const Receipt &r,bool accepted,const std::string &basis,int64_t version=-1,int64_t origin=-1,int64_t anchor=-1,int64_t focus=-1) {
        if(!r)return false;
        if(r->settled)return r->accepted==accepted && r->basis==basis &&
            r->ownerVersion==version && r->postOrigin==origin && r->anchorByte==anchor && r->focusByte==focus;
        if(accepted) {
            CjguiOhosSourceBasis old(r->origin->bodyBasis), next(basis);
            if(version>=0) {
                const auto c=r->resolvedCoverage?r->resolvedCoverage:r->origin->coverage; int64_t a,b;
                if(!c || version!=c->ownerVersion || origin!=(r->origin->sourceKind==3?c->layoutOrigin:c->platformOrigin) || !CjguiOhosSourceBasis(c->bodyBasis).sameBody(next) ||
                   next.value[6]!=version || next.value[8]!=anchor || next.value[9]!=focus ||
                   (r->origin->sourceKind==4 ? (anchor!=0 || focus!=next.value[5] ||
                     r->origin->sourceAnchor!=0 || r->origin->sourceFocus!=next.value[5] ||
                     r->origin->start!=0 || r->origin->end!=r->origin->text.size() ||
                     next.value[10]!=r->origin->start || next.value[11]!=r->origin->end) :
                     r->origin->sourceKind==3 ? (anchor!=r->origin->sourceAnchor || focus!=r->origin->sourceFocus) :
                    r->requiresRebase ? (anchor<c->begin || focus<c->begin || anchor>c->end || focus>c->end) :
                    (!c->source(false,r->origin->start,a) ||
                     !c->source(false,r->origin->end,b) || a!=anchor || b!=focus)))return false;
            } else if(!old.sameBody(next) || next.value[10]!=r->origin->start || next.value[11]!=r->origin->end)return false;
        }
        return finish(r,accepted,basis,version,origin,anchor,focus);
    }
    // Semantic owner result may move its bounded mirror. Original platform
    // endpoints are source facts, not the new mirror's local endpoints.
    bool settleCapturedCommand(const Receipt &r,const std::string &basis,int64_t version,
        int64_t origin,int64_t anchor,int64_t focus) {
        if(!r || !r->origin->capturedCommand || r->origin->sourceKind!=4 || basis.size()>256)return false;
        if(r->settled)return r->accepted && r->basis==basis && r->ownerVersion==version &&
            r->postOrigin==origin && r->anchorByte==anchor && r->focusByte==focus;
        const auto &o=*r->origin;const auto c=o.coverage;
        const CjguiOhosSourceBasis old(o.bodyBasis),next(basis);
        int64_t begin,end;
        if(!c || !c->qualified || !old.valid || !next.valid || version!=c->ownerVersion ||
           origin!=c->platformOrigin || next.value[0]!=old.value[0] || next.value[2]!=old.value[2] ||
           next.value[3]!=old.value[3] || next.value[5]!=old.value[5] || next.value[6]!=version ||
           next.value[7]<old.value[7] || next.value[8]!=anchor || next.value[9]!=focus ||
           anchor!=0 || focus!=old.value[5] || o.sourceAnchor!=0 || o.sourceFocus!=focus ||
           o.start!=0 || o.end!=o.text.size() || *c->platform!=o.text ||
           !c->position(false,0,begin) || !c->position(false,o.end,end) ||
           begin!=origin || end>focus || next.value[4]>focus || next.value[11]>12288)return false;
        return finish(r,true,basis,version,origin,anchor,focus);
    }
    bool resolveCoverage(const Receipt&r,const CjguiOhosCoverage&c,bool rebase=false) {
        if(!r || r->settled || !c || retainedUnits(nullptr,r.get(),c)>1048576)return false;
        r->resolvedCoverage=c;r->requiresRebase=rebase;return true;
    }
    size_t retainedUnits(const CjguiOhosChoiceOrigin *extra=nullptr,const CjguiOhosChoiceReceipt *replacing=nullptr,
        const CjguiOhosCoverage &replacement={})const {
        size_t units=auxiliaryUnits_;std::vector<const CjguiOhosTextCoverage*> seen;
        std::vector<CjguiOhosCoverage> proofs;
        std::vector<const std::u16string*> texts;
        std::vector<const CjguiOhosPublicationDependency*> dependencies;
        std::vector<const CjguiOhosInputSourceLeaf*> leaves;
        const auto charge=[&](const CjguiOhosCoverage&c){if(c && std::find(seen.begin(),seen.end(),c.get())==seen.end()) {
            seen.push_back(c.get());proofs.push_back(c);}};
        const auto dependency=[&](const std::shared_ptr<const CjguiOhosPublicationDependency>&d) {
            if(d && std::find(dependencies.begin(),dependencies.end(),d.get())==dependencies.end()) {
                dependencies.push_back(d.get());units+=d->retainedUnits();
                const auto leaf=d->sourceLeaf;
                if(leaf && std::find(leaves.begin(),leaves.end(),leaf.get())==leaves.end()) {
                    leaves.push_back(leaf.get());units+=leaf->retainedUnits();charge(leaf->coverage);charge(leaf->acceptedBody);
                }
            }
        };
        charge(auxiliaryCoverage_.lock());
        charge(executionCoverage_.lock());
        for(const auto&w:live_)if(auto r=w.lock()) {
            units+=r->origin->text.capacity()+5*sizeof(int64_t)/sizeof(char16_t);charge(r->origin->coverage);
            charge(r.get()==replacing?replacement:r->resolvedCoverage);
            charge(r->commandCoverage);
            for(const auto &d:r->origin->prefixOrigins)dependency(d);
        }
        if(extra){units+=extra->text.capacity()+5*sizeof(int64_t)/sizeof(char16_t);charge(extra->coverage);for(const auto &d:extra->prefixOrigins)dependency(d);}
        const auto text=[&](const std::shared_ptr<const std::u16string>&value) {
            if(value && std::find(texts.begin(),texts.end(),value.get())==texts.end()) {
                texts.push_back(value.get());units+=value->capacity();
            }
        };
        // Qualified observations retain the same original body. Walk that
        // graph once, including each proof's own indexes and each shared text,
        // rather than recursively charging the body again from every choice.
        for(size_t i=0;i<proofs.size();++i) {
            const auto c=proofs[i];text(c->layout);text(c->platform);
            units+=(c->layoutBytes.capacity()+c->platformBytes.capacity())*sizeof(int32_t)/sizeof(char16_t)+
                (c->bodyBasis.capacity()+sizeof(CjguiOhosTextCoverage)+1)/sizeof(char16_t);
            charge(c->body);
        }
        return units;
    }
    // One Session-owned source/capture record, charged within the original cap.
    // Weak coverage adds no new owner; graph traversal still charges shared
    // texts and indexes only once, including a distinct newly painted body.
    bool holdAuxiliary(size_t units,const CjguiOhosCoverage &coverage={}) {
        const auto oldUnits=auxiliaryUnits_;const auto oldCoverage=auxiliaryCoverage_;
        auxiliaryUnits_=units;auxiliaryCoverage_=coverage;
        if(retainedUnits()>1048576){auxiliaryUnits_=oldUnits;auxiliaryCoverage_=oldCoverage;return false;}
        return true;
    }
    bool holdExecutionCoverage(const CjguiOhosCoverage &coverage) {
        const auto previous=executionCoverage_;executionCoverage_=coverage;
        if(retainedUnits()>1048576){executionCoverage_=previous;return false;}
        return true;
    }
    void clearAuxiliary(){auxiliaryUnits_=0;auxiliaryCoverage_.reset();executionCoverage_.reset();}
    Receipt find(uint64_t id)const {for(const auto&w:live_)if(auto r=w.lock())if(r->origin->id==id)return r;return {};}
    Receipt latest()const{return latest_;}
    Receipt published()const{return published_;}
    void expire(int64_t now) {
        const auto pending=awaiting_;
        for(const auto&r:pending)if(r->origin->deadline && now>=r->origin->deadline) {
            r->reason="choice_deadline";settle(r,false,"");
        }
    }
    void clear(){latest_.reset();published_.reset();awaiting_.clear();reap();}
    size_t liveCount(){reap();return live_.size();}
private:
    bool finish(const Receipt &r,bool accepted,const std::string &basis,int64_t version,
        int64_t origin,int64_t anchor,int64_t focus) {
        r->basis=basis;r->accepted=accepted;r->settled=true;
        r->ownerVersion=version;r->postOrigin=origin;r->anchorByte=anchor;r->focusByte=focus;
        awaiting_.erase(std::remove(awaiting_.begin(),awaiting_.end(),r),awaiting_.end());
        // Older FIFO receipts cannot replace a later published choice.
        if(accepted && (!published_ || r->origin->id>published_->origin->id))published_=r;
        return true;
    }
    void reap(){live_.erase(std::remove_if(live_.begin(),live_.end(),[](const auto&w){return w.expired();}),live_.end());}
    uint64_t next_=0;
    size_t auxiliaryUnits_=0;
    std::weak_ptr<const CjguiOhosTextCoverage> auxiliaryCoverage_;
    std::weak_ptr<const CjguiOhosTextCoverage> executionCoverage_;
    Receipt latest_,published_;
    std::vector<Receipt> awaiting_; // Original confirmation ownership, included in the unchanged live/payload cap.
    std::vector<std::weak_ptr<CjguiOhosChoiceReceipt>> live_;
};
#endif
