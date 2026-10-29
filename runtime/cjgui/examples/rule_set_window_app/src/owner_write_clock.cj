// macOS consumer-only scalar clock. Same mach_absolute_time/timebase
// as the frozen renderer's clock; no native library extension or test mode.
package cjgui_rule_set_window_app
@C
struct RuleSetOwnerClockTimebase {
    var numer: UInt32 = 0
    var denom: UInt32 = 0
}
foreign {
    func mach_absolute_time(): UInt64
    func mach_timebase_info(info: CPointer<RuleSetOwnerClockTimebase>): Int32
}
class RuleSetOwnerWriteClock {
    private let numer: UInt64
    private let denom: UInt64
    init(enabled: Bool) {
        var n = 0u64; var d = 0u64
        if (enabled) {
            var info = RuleSetOwnerClockTimebase()
            let status = unsafe { mach_timebase_info(inout info) }
            if (status == 0 && info.numer > 0 && info.denom > 0) {
                n = UInt64(info.numer); d = UInt64(info.denom)
            }
        }
        numer = n; denom = d
    }
    func micros(): Int64 {
        if (numer == 0 || denom == 0) { return -1 }
        let ticks = unsafe { mach_absolute_time() }
        // Preserve conversion-before-microsecond-division precision. Overflow
        // is explicit unknown, never a wrapped time or a quantized shortcut.
        if (ticks > 18446744073709551615u64 / numer) { return -1 }
        let value = ticks * numer / (denom * 1000u64)
        if (value > 9223372036854775807u64) { return -1 }
        return Int64(value)
    }
}
