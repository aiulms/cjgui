#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROBE="${SCRIPT_DIR}/complex_scene_performance_probe.py"
OUTPUT=""
RAW_ROOT=""
ROUNDS=30
CONTRACT_ONLY=0

while (( $# > 0 )); do
    case "$1" in
        --output)
            (( $# >= 2 )) || { print -u2 -- "--output requires a path"; exit 2; }
            OUTPUT="$2"
            shift 2
            ;;
        --raw-root)
            (( $# >= 2 )) || { print -u2 -- "--raw-root requires a path"; exit 2; }
            RAW_ROOT="$2"
            shift 2
            ;;
        --rounds)
            (( $# >= 2 )) || { print -u2 -- "--rounds requires an integer"; exit 2; }
            ROUNDS="$2"
            shift 2
            ;;
        --contract-only)
            CONTRACT_ONLY=1
            shift
            ;;
        *)
            print -u2 -- "unknown option: $1"
            exit 2
            ;;
    esac
done

if (( CONTRACT_ONLY )); then
    OUTPUT="${OUTPUT:-/private/tmp/cjgui-complex-scene-performance-contract.json}"
    python3 "$PROBE" --contract-fixture --output "$OUTPUT"
    print -- "COMPLEX_SCENE_PERFORMANCE_CONTRACT $OUTPUT"
    exit 0
fi

[[ -n "$OUTPUT" ]] || { print -u2 -- "normal mode requires --output REPORT.json"; exit 2; }
[[ "$ROUNDS" == <-> ]] && (( ROUNDS >= 30 )) || { print -u2 -- "--rounds must be at least 30"; exit 2; }

TOOLCHAIN_ENV="/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
[[ -r "$TOOLCHAIN_ENV" ]] || { print -u2 -- "missing Cangjie 1.1.3 environment: $TOOLCHAIN_ENV"; exit 1; }
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH-}"
source "$TOOLCHAIN_ENV"
export CJ_GUI_SDKROOT="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
export SDKROOT="${SDKROOT:-$CJ_GUI_SDKROOT}"
[[ -d "$CJ_GUI_SDKROOT" ]] || { print -u2 -- "missing MacOSX15.4 SDK: $CJ_GUI_SDKROOT"; exit 1; }

if [[ -z "$RAW_ROOT" ]]; then
    RAW_ROOT="$(mktemp -d /private/tmp/cjgui-complex-scene-performance.XXXXXX)"
else
    mkdir -p "$RAW_ROOT"
fi

print -- "COMPLEX_SCENE_PERFORMANCE_ENV cjc_version=1.1.3 sdk=$CJ_GUI_SDKROOT"
print -- "COMPLEX_SCENE_PERFORMANCE_RAW_ROOT $RAW_ROOT"
python3 "$PROBE" --output "$OUTPUT" --raw-root "$RAW_ROOT" --rounds "$ROUNDS"
print -- "COMPLEX_SCENE_PERFORMANCE_REPORT $OUTPUT"
