#ifndef CJGUI_OHOS_FOCUS_AUTHORITY_H
#define CJGUI_OHOS_FOCUS_AUTHORITY_H
#include <cstdint>
#include <string>
#include <memory>
#include <vector>
#include <algorithm>
struct CjguiOhosEditOwnerReceipt;

// Private, Session-lock confined. Owner versions and component echoes never issue a token.
struct CjguiOhosProxyKey {
    uint64_t app = 0, session = 0, edit = 0, mount = 0;
    int64_t context = 0;
    bool operator==(const CjguiOhosProxyKey &b) const {
        return app == b.app && session == b.session && context == b.context && edit == b.edit && mount == b.mount;
    }
    bool valid() const { return app && session && context > 0 && edit && mount; }
};
struct CjguiOhosFocusAuthority {
    uint64_t generation = 0, operationSeq = 0;
    bool active = false, foreground = true;
    uint64_t node = 0, binding = 0;
    int64_t resource = -1;
    uint32_t kind = 0;
    std::string field;
    CjguiOhosProxyKey mounted;
    struct Transfer {
        uint64_t operation = 0, generation = 0, restoreRequest = 0;
        int64_t targetContext = 0, deadline = 0;
        uint64_t targetEdit = 0;
        CjguiOhosProxyKey old;
        bool registered = false;
        std::shared_ptr<const CjguiOhosEditOwnerReceipt> inputOwner;
        std::vector<uint64_t> inputPrefix;
        uint64_t ownerBinding=0;
    } transfer;
    uint64_t issue(uint64_t n, int64_t r, uint32_t k, uint64_t b, const std::string &f) {
        if (!foreground) return 0;
        const bool sameLiveTarget = active && node == n && resource == r && kind == k && binding == b && field == f;
        const auto previousMount = mounted;
        ++generation; active = true; node = n; resource = r; kind = k; binding = b; field = f;
        mounted = sameLiveTarget ? previousMount : CjguiOhosProxyKey{}; transfer = {}; return generation;
    }
    bool eligible(uint64_t expected) const { return foreground && active && expected && expected == generation; }
    bool target(uint64_t n, int64_t r, uint32_t k, uint64_t b, const std::string &f) const {
        return eligible(generation) && n == node && r == resource && k == kind && b == binding && f == field;
    }
    bool continueOwnedTarget(uint64_t n, int64_t r, uint32_t k, uint64_t b, const std::string &f) {
        if (!eligible(generation) || r != resource || f != field) return false;
        // This is called only after the accepted owned declaration and geometry checks.
        node = n; kind = k; binding = b; return true;
    }
    bool bind(const CjguiOhosProxyKey &key) {
        if (!eligible(generation) || !key.valid()) return false;
        if (mounted.valid()) return mounted == key;
        mounted = key; return true;
    }
    bool permits(const CjguiOhosProxyKey &key, uint64_t expected) const {
        return eligible(expected) && mounted.valid() && mounted == key;
    }
    void prepareTransfer(int64_t context, uint64_t edit, uint64_t request, int64_t deadline) {
        if (!eligible(generation)) return;
        // Keep the first mounted predecessor while native advances before the UI can unmount.
        if (!mounted.valid() && !transfer.old.valid()) return;
        if (mounted.valid()) {
            transfer = {++operationSeq, generation, request, context, deadline, edit, mounted, false};
        } else { transfer.targetContext = context; transfer.targetEdit = edit; }
        mounted = {};
    }
    // Freeze once at the structural handoff. Later Will arrivals cannot extend
    // this prefix or its deadline. Retired-terminal permission stays separate.
    void freezeInputPrefix(std::shared_ptr<const CjguiOhosEditOwnerReceipt> owner,
        const std::vector<uint64_t> &prefix,uint64_t binding,int64_t deadline) {
        if(!eligible(transfer.generation) || !transfer.operation || transfer.inputOwner ||
           !owner || prefix.empty() || prefix.size()>32 || !binding || deadline<=0)return;
        transfer.inputOwner=std::move(owner);transfer.inputPrefix=prefix;transfer.ownerBinding=binding;
        if(!transfer.deadline || deadline<transfer.deadline)transfer.deadline=deadline;
    }
    bool permitsTransferredInput(const CjguiOhosProxyKey &key,uint64_t expected,
        uint64_t ticket,uint64_t binding,int64_t now) const {
        return eligible(expected) && transfer.generation==expected && transfer.inputOwner &&
            transfer.old==key && transfer.ownerBinding==binding && now<transfer.deadline &&
            std::find(transfer.inputPrefix.begin(),transfer.inputPrefix.end(),ticket)!=transfer.inputPrefix.end();
    }
    uint64_t registerTransfer(const CjguiOhosProxyKey &old, uint64_t expected, int64_t targetContext, uint64_t targetEdit) {
        if (!eligible(expected) || !transfer.operation || transfer.generation != expected ||
            !(transfer.old == old) || transfer.targetContext != targetContext || transfer.targetEdit != targetEdit) return 0;
        transfer.registered = true; return transfer.operation;
    }
    bool retiredTerminal(const CjguiOhosProxyKey &key, uint64_t expected) const {
        return transfer.registered && transfer.generation == expected && transfer.old == key;
    }
    bool revoke(uint64_t expected) {
        if (!active || expected != generation) return false;
        active = false; mounted = {}; transfer={}; return true;
    }
    void setForeground(bool value) { foreground = value; if (!value) revoke(generation); }
};
#endif
