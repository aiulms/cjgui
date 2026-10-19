#!/usr/bin/env python3
"""Compile the actual snapshot heap-observation caller with counted runtime APIs."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from test_presentation_typography_reuse import block

SOURCE=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mutation',action='store_true')
    args=parser.parse_args();source=SOURCE.read_text()
    method=block(source,'    private func observeOhosManagedHeap(').replace('private func','func',1)
    if args.mutation:
        guard=block(method,'        if (!CJGUI_OHOS_DEEP_DIAGNOSTICS_ENABLED)')
        method=method.replace(guard,'',1)
    marker='private let CJGUI_OHOS_DEEP_DIAGNOSTICS_ENABLED: Bool ='
    policy=block(source,marker) if marker in source else 'private let CJGUI_OHOS_DEEP_DIAGNOSTICS_ENABLED: Bool = true'
    code='''package h_diagnostics
import std.env.*
'''+policy+'''
var sampled: Int64 = 0
var recorded: Int64 = 0
func getAllocatedHeapSize(): Int64 { sampled++; return 10 }
func getUsedHeapSize(): Int64 { sampled++; return 20 }
func getGCCount(): Int64 { sampled++; return 30 }
func getGCFreedSize(): Int64 { sampled++; return 40 }
func getGCTime(): Int64 { sampled++; return 50 }
func internalRendererObserveManagedTextBoundary(s: UInt64, i: Int64, r: UInt64,
    v: Int64, p: String, b: String, a: Int64, h: Int64, c: Int64, f: Int64, t: Int64): Unit {
    if (s != 42u64 || i != 7 || r != 3u64 || v != 2 || p != "original" || b != "basis" ||
        a != 10 || h != 20 || c != 30 || f != 40 || t != 50) { throw Exception("original observation changed") }
    recorded++
}
class OriginalCaller { let sessionToken: UInt64 = 42u64
'''+method+'''
}
main(): Int64 {
    OriginalCaller().observeOhosManagedHeap("original",7,3u64,2,"basis")
    let on = getVariable("H_EXPECT_DEEP") == Some("1")
    println("SAMPLES ${sampled} OBSERVATIONS ${recorded}")
    if ((!on && (sampled != 0 || recorded != 0)) || (on && (sampled != 5 || recorded != 1))) {
        println("FAIL default-off computed managed runtime samples before native guard")
        return 17
    }
    println("PASS actual snapshot caller gates before heap/GC sampling")
    return 0
}
'''
    out=Path(os.environ['CJGUI_H_NATIVE_TEST_ARTIFACTS']);out.mkdir(parents=True,exist_ok=True)
    (out/'actual-caller.cj').write_text(code)
    with tempfile.TemporaryDirectory(prefix='h-managed-diagnostics-') as directory:
        root=Path(directory);src=root/'main.cj';src.write_text(code);exe=root/'test'
        command=['/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/bin/cjc',str(src),'-o',str(exe)]
        built=subprocess.run(command,capture_output=True,text=True)
        (out/'compile.json').write_text(json.dumps(dict(exit=built.returncode,stdout=built.stdout,stderr=built.stderr,source_sha256=hashlib.sha256(source.encode()).hexdigest()),indent=2)+'\n')
        if built.returncode:print(built.stdout,built.stderr);raise RuntimeError('compile error is not a behavioral RED')
        rows=[]
        for name,value in [('off',None),('on','1'),('invalid','true')]:
            env=os.environ.copy();env.pop('CJGUI_OHOS_DEEP_DIAGNOSTICS',None)
            if value is not None:env['CJGUI_OHOS_DEEP_DIAGNOSTICS']=value
            env['H_EXPECT_DEEP']='1' if name=='on' else '0'
            p=subprocess.run([str(exe)],env=env,capture_output=True,text=True);row=dict(mode=name,exit=p.returncode,stdout=p.stdout,stderr=p.stderr);rows.append(row);print(name,p.returncode,p.stdout,p.stderr)
            if p.returncode:break
        (out/'modes.json').write_text(json.dumps(rows,indent=2)+'\n')
        if any(x['exit']for x in rows):raise SystemExit(1)


if __name__=='__main__':main()
