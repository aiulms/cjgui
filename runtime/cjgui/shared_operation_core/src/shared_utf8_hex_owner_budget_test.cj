package cjgui_shared_operation_core

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func originalReadRangeHexCodecOwner16msCounter() {
        let body = String.fromUtf8(Array<UInt8>(65536, repeat: 88u8))
        var maximum: Int64 = 0
        var over: Int64 = 0
        for (index in 0..1000) {
            let start = MonoTime.now()
            let encoded = CjguiSharedOperationFrame.encodeUtf8Hex(body)
            let micros = (MonoTime.now() - start).toMicroseconds()
            @Assert(encoded.size == 131072)
            maximum = max(maximum, micros)
            if (micros > 16000) { over += 1 }
            println("READ_HEX_OWNER_COST index=${index} elapsed_us=${micros} bytes=65536 encoded=131072")
        }
        println("READ_HEX_OWNER_COST_SUMMARY samples=1000 over16=${over} max_us=${maximum}")
        @Assert(over == 0)
    }

@Test
func boundedReadHexWireBytesRemainExact() {
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex("") == "-")
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex("X") == "58")
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex("码") == "E7A081")
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex("😀") == "F09F9880")
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex("Hi中😀") == "4869E4B8ADF09F9880")
    let controlBytes = String.fromUtf8(Array<UInt8>(128, { i => UInt8(i) }))
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex(controlBytes) == "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F")
    let maximumBody = String.fromUtf8(Array<UInt8>(65536, repeat: 88u8))
    let independentWire = String.fromUtf8(Array<UInt8>(131072,
        { i => if (i % 2 == 0) { 53u8 } else { 56u8 } }))
    @Assert(CjguiSharedOperationFrame.encodeUtf8Hex(maximumBody) == independentWire)
}
