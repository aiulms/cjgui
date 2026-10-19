#ifndef CJGUI_OHOS_TEXT_WORK_TRACE_H
#define CJGUI_OHOS_TEXT_WORK_TRACE_H
#include "cjgui_ohos_edit_ticket.h"

// Diagnostic-only immutable values. Never a source/selection/permission ticket.
// Weak owner receipt and scalar extents do not retain input bodies or history.
struct CjguiOhosTextWorkTrace {
    uint64_t sequence=0,projection=0,input=0,node=0,binding=0;
    int64_t resource=-1,ownerBefore=-1,ownerAfter=-1;
    uint32_t kind=0,start16=0,units16=0;
    bool exactOwner=false;
    std::string beforeBasis,afterBasis;
    std::weak_ptr<const CjguiOhosEditOwnerReceipt> owner;
    static std::shared_ptr<const CjguiOhosTextWorkTrace> freeze(uint64_t sequence,uint64_t projection,
        uint64_t input,uint64_t node,int64_t resource,uint32_t kind,uint64_t binding,
        int64_t version,const std::string &basis,const std::u16string &mirror,
        const CjguiOhosEditTickets::OwnerReceipt &receipt) {
        CjguiOhosTextWorkTrace t;t.sequence=sequence;t.projection=projection;t.node=node;t.resource=resource;
        t.kind=kind;t.binding=binding;t.ownerAfter=version;
        if(!input || !receipt || !receipt->accepted || !receipt->origin || basis.size()>512 ||
           receipt->origin->sourceBasis.size()>512 || mirror.size()>12288)return std::make_shared<const CjguiOhosTextWorkTrace>(std::move(t));
        const auto &o=*receipt->origin;const CjguiOhosSourceBasis b(basis),before(o.sourceBasis);
        std::vector<int32_t> index;uint32_t start=0;
        if(o.id!=input || o.node!=node || o.resource!=resource || o.kind!=kind || o.ownerBinding!=binding ||
           receipt->ownerVersion!=version || !b.valid || b.value[2]!=version || b.value[3]!=version || b.value[6]!=version ||
           !CjguiOhosSourceBasis(receipt->resultBasis).sameBody(b) || receipt->postOrigin<0 ||
           b.value[4]<receipt->postOrigin || !CjguiOhosTextCoverage::index(o.after,index) ||
           !CjguiOhosTextCoverage::local(index,b.value[4]-receipt->postOrigin,start) ||
           start>o.after.size() || mirror.size()>o.after.size()-start || o.after.compare(start,mirror.size(),mirror)!=0)
            return std::make_shared<const CjguiOhosTextWorkTrace>(std::move(t));
        t.input=input;t.ownerBefore=before.valid?before.value[2]:-1;t.exactOwner=true;
        t.beforeBasis=o.sourceBasis;t.afterBasis=basis;t.owner=receipt;t.start16=start;t.units16=mirror.size();
        return std::make_shared<const CjguiOhosTextWorkTrace>(std::move(t));
    }
    bool matches(const std::u16string &value) const {
        const auto r=owner.lock();return exactOwner && r && r->accepted && r->origin && r->origin->id==input &&
            r->ownerVersion==ownerAfter && value.size()==units16 && start16<=r->origin->after.size() &&
            units16<=r->origin->after.size()-start16 &&
            r->origin->after.compare(start16,units16,value)==0;
    }
};
using CjguiOhosTextWorkTraceRef=std::shared_ptr<const CjguiOhosTextWorkTrace>;
#endif
