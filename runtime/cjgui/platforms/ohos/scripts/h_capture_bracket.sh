#!/system/bin/sh
set -eu
pid="$1"
tag="$2"
root="$3"
case "$pid" in ''|*[!0-9]*) exit 2;; esac
case "$tag" in ''|*[!a-zA-Z0-9_-]*) exit 2;; esac
case "$root" in /data/local/tmp/h-owned-capture-*) ;; *) exit 2;; esac
base="${root}/${pid}-${tag}"
test ! -e "${base}.jpeg"
date +%s%N > "${base}.start"
hilog -x -P "$pid" -T CjguiRenderer | grep -a 'text feedback .*choiceOwner=' | tail -n 1 > "${base}.before"
date +%s%N > "${base}.capture-start"
date '+%m-%d %H:%M:%S.%N' > "${base}.capture-begin-clock"
snapshot_display -f "${base}.jpeg" > "${base}.tool" 2>&1
date +%s%N > "${base}.capture-end"
date '+%m-%d %H:%M:%S.%N' > "${base}.capture-end-clock"
hilog -x -P "$pid" -T CjguiRenderer | grep -a 'text feedback .*choiceOwner=' | tail -n 1 > "${base}.after"
date +%s%N > "${base}.end"
# Return the same device facts from this capture transaction. Host log delivery
# and image transfer happen later and cannot identify the captured frame.
for field in before after capture-start capture-end capture-begin-clock capture-end-clock; do
    printf 'H_CAPTURE_FIELD %s\n' "$field"
    cat "${base}.${field}"
    printf 'H_CAPTURE_END %s\n' "$field"
done
