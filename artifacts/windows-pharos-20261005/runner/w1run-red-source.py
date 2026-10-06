#!/usr/bin/env python3
"""W1 无泄漏执行器：一次 exec 启动 worker，worker 一次性执行全部任务后回传。

为什么这样设计
--------------
实测：每次 `prlctl exec` 会在客户机内新建约 2-3 个进程，并让
`prl_tools_service` 的 Terminal 窗口 +1，且不回收。
执行 495 条命令 → 495 个 Terminal 窗口、482 个可见窗口。

因此本脚本：
  1. 只调用 1 次 prlctl exec 来启动 worker；
  2. worker 通过 TCP 把**整批任务**拉走，在客户机内依次执行；
  3. 全部结果一次性回传，连接关闭。

用法：
    python3 w1run.py <任务目录>      # 执行目录内所有 *.ps1（按名排序）
    python3 w1run.py <单个.ps1>
"""
import base64
import glob
import json
import os
import socket
import subprocess
import sys
import threading
import time

VM_UUID = "{9e5dedb2-90f8-4d21-80f0-41e194407fab}"
MAC_IP = "10.211.55.2"
PORT = int(os.environ.get("W1_PORT", "8801"))


def start_worker():
    """用一次 exec 启动客户机 worker，返回本次 exec 的 stdout。"""
    cmd = ("Start-Process powershell.exe -ArgumentList "
           "'-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden',"
           "'-File','C:\\cjgui-windows-w1\\worker_run.ps1' -WindowStyle Hidden; 'LAUNCHED'")
    for _ in range(4):
        p = subprocess.run(["prlctl", "exec", VM_UUID, "--current-user",
                            "powershell.exe", "-NoLogo", "-NoProfile",
                            "-ExecutionPolicy", "Bypass", "-Command", cmd],
                           capture_output=True, timeout=300)
        out = p.stdout.decode("utf-8", "replace").strip()
        err = p.stderr.decode("utf-8", "replace")
        if "LAUNCHED" in out:
            return out
        if "Unable to open new session" in err or "PrlJob" in err:
            time.sleep(2)
            continue
        return out or err
    return "LAUNCH_FAILED"


def run_batch(scripts, timeout=1800):
    """监听一个连接，把任务批次交给客户机 worker，收集结果。"""
    results = {}

    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", PORT))
    srv.listen(1)
    srv.settimeout(timeout)

    # 启动 worker（本次唯一一次 exec）
    t = threading.Thread(target=start_worker, daemon=True)
    t.start()

    try:
        conn, addr = srv.accept()
    except socket.timeout:
        srv.close()
        return None, "等待 worker 连接超时"

    buf = b""

    def read_line():
        nonlocal buf
        while b"\n" not in buf:
            c = conn.recv(4096)
            if not c:
                return None
            buf += c
        line, _, buf = buf.partition(b"\n")
        return line.decode("utf-8", "replace")

    def read_exact(n):
        nonlocal buf
        while len(buf) < n:
            c = conn.recv(65536)
            if not c:
                return None
            buf += c
        data, buf = buf[:n], buf[n:]
        return data

    try:
        hello = read_line()
        payload = json.dumps(scripts).encode("utf-8")
        conn.sendall(b"BATCH %d\n" % len(payload))
        conn.sendall(payload + b"\n")

        while True:
            line = read_line()
            if line is None:
                break
            if line.startswith("DONE"):
                break
            if line.startswith("RES "):
                parts = line.split(None, 2)
                name = parts[1]
                blen = int(parts[2])
                body = read_exact(blen)
                results[name] = (body or b"").decode("utf-8", "replace")
                conn.sendall(b"ACK\n")
                continue
            conn.sendall(b"ACK\n")
    except Exception as exc:  # noqa: BLE001
        return results, "传输异常: %s" % exc
    finally:
        try:
            conn.close()
        except Exception:
            pass
        srv.close()

    return results, "OK  握手: %s" % (hello or "")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    arg = sys.argv[1]
    if os.path.isdir(arg):
        paths = sorted(glob.glob(os.path.join(arg, "*.ps1")))
    else:
        paths = [arg]

    scripts = {}
    for p in paths:
        with open(p, "r", encoding="utf-8") as fh:
            scripts[os.path.basename(p)] = fh.read()
    print("准备执行 %d 个任务: %s" % (len(scripts), ", ".join(scripts)))

    results, status = run_batch(scripts)
    print("状态: %s" % status)
    if results is None:
        return 1

    rc = 0
    for name in scripts:
        print("\n########## %s ##########" % name)
        body = results.get(name)
        if body is None:
            print("(无结果)")
            rc = 1
            continue
        sys.stdout.write(body)
        if "[exit=" not in body:
            rc = 1
        else:
            try:
                code = int(body.rsplit("[exit=", 1)[1].split("]")[0])
                if code != 0:
                    rc = code
            except Exception:
                pass
    return rc


if __name__ == "__main__":
    sys.exit(main())
