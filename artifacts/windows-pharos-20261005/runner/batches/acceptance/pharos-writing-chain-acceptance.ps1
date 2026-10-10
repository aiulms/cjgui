$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
# Windows Pharos 正常写作链验收（2026-10-06 工具门重写版）。
# 原则：
#  - 键鼠一律走系统队列 SendInput，并核发送数；CLICK_NODE 缝仅保留为渲染器局部诊断，
#    本脚本不使用它。NODE_RECT 只用于坐标测量；节点 missing 一律失败。
#  - 每笔编辑以动作前冻结的完整 owner 字节 + 会话选区跨度独立计算期望全文，
#    再做完整字节比对；不再用“包含 token / 旧 token 消失”之类弱判据。
#  - 打字按真实节奏（无逐字延迟），不靠 250ms 慢打规避机制缺口。
# 退出码：0 全绿；30+ 按门编号失败；40 产物缺失；50 超时/环境。
function Log([string]$m){ Write-Output ("[accept] " + $m) }
function Fail([int]$code,[string]$m){ Write-Output ("PHAROS_ACCEPT_FAIL code=" + $code + " " + $m); exit $code }
function Read-FileText([string]$p){ return [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function PeMachine([string]$exe){
  $fs=[System.IO.File]::OpenRead($exe); try{
    $br=New-Object System.IO.BinaryReader($fs)
    $fs.Seek(0x3C,[System.IO.SeekOrigin]::Begin)|Out-Null
    $pe=$br.ReadInt32(); $fs.Seek($pe,[System.IO.SeekOrigin]::Begin)|Out-Null
    if($br.ReadInt32() -ne 0x00004550){return 0}
    return $br.ReadUInt16()
  } finally{$fs.Close()}
}
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public sealed class PharosSendInput {
    [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct HARDWAREINPUT { public uint uMsg; public ushort wParamL; public ushort wParamH; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; [FieldOffset(0)] public HARDWAREINPUT hi; }
    [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public INPUTUNION u; }
    [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int w, int hh, bool repaint);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int left,top,right,bottom; }
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
    [DllImport("kernel32.dll",SetLastError=true)] public static extern IntPtr OpenProcess(uint access,bool inherit,uint pid);
    [DllImport("kernel32.dll",SetLastError=true)] public static extern bool GetExitCodeProcess(IntPtr process,out uint exit);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    public static uint ForegroundPid() { uint pid = 0; GetWindowThreadProcessId(GetForegroundWindow(), out pid); return pid; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int x; public int y; }
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT Point);
    public static uint HitPid(int x, int y) { uint pid = 0; POINT pt = new POINT(); pt.x = x; pt.y = y; GetWindowThreadProcessId(WindowFromPoint(pt), out pid); return pid; }
    public const uint INPUT_MOUSE = 0;
    public const uint INPUT_KEYBOARD = 1;
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const uint KEYEVENTF_UNICODE = 0x0004;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public static int MouseClickAt(int x, int y) {
        if (!SetCursorPos(x, y)) return -1;
        System.Threading.Thread.Sleep(150);
        INPUT[] d = new INPUT[1]; d[0].type = INPUT_MOUSE; d[0].u.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
        INPUT[] u = new INPUT[1]; u[0].type = INPUT_MOUSE; u[0].u.mi.dwFlags = MOUSEEVENTF_LEFTUP;
        uint r1 = SendInput(1, d, Marshal.SizeOf(typeof(INPUT)));
        System.Threading.Thread.Sleep(60);
        uint r2 = SendInput(1, u, Marshal.SizeOf(typeof(INPUT)));
        return (int)(r1 + r2);
    }
    public static int TypeUnicode(string text) {
        int sent = 0;
        foreach (char ch in text) {
            INPUT[] down = new INPUT[1];
            down[0].type = INPUT_KEYBOARD;
            down[0].u.ki.wVk = 0; down[0].u.ki.wScan = ch;
            down[0].u.ki.dwFlags = KEYEVENTF_UNICODE; down[0].u.ki.time = 0; down[0].u.ki.dwExtraInfo = IntPtr.Zero;
            sent += (int)SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
            INPUT[] up = new INPUT[1];
            up[0].type = INPUT_KEYBOARD;
            up[0].u.ki.wVk = 0; up[0].u.ki.wScan = ch;
            up[0].u.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP; up[0].u.ki.time = 0; up[0].u.ki.dwExtraInfo = IntPtr.Zero;
            sent += (int)SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
        }
        return sent;
    }
    [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mapType);
    static INPUT KeyInput(ushort vk, bool up) {
        INPUT input = new INPUT(); input.type = INPUT_KEYBOARD;
        input.u.ki.wVk = vk; input.u.ki.dwFlags = up ? KEYEVENTF_KEYUP : 0;
        input.u.ki.dwExtraInfo = new IntPtr(0x43595735);
        // Explicit standalone navigation keys; a generic VK mapping can name
        // the numeric keypad and synthesize a temporary Shift release.
        if (vk >= 0x21 && vk <= 0x28 || vk == 0x2D || vk == 0x2E) {
            uint scan = MapVirtualKey(vk, 4);
            if (scan == 0) throw new InvalidOperationException("navigation_scan_missing");
            input.u.ki.wVk = 0; input.u.ki.wScan = (ushort)(scan & 0xff);
            input.u.ki.dwFlags |= 0x0008 | 0x0001;
        }
        return input;
    }
    public static int KeyDown(ushort vk) {
        return (int)SendInput(1, new INPUT[] { KeyInput(vk, false) }, Marshal.SizeOf(typeof(INPUT)));
    }
    public static int KeyUp(ushort vk) {
        return (int)SendInput(1, new INPUT[] { KeyInput(vk, true) }, Marshal.SizeOf(typeof(INPUT)));
    }
    public static int KeyTap(ushort vk) { return KeyDown(vk) + KeyUp(vk); }
    public static int ShiftLeft(int count) {
        INPUT[] inputs = new INPUT[2 + 2 * count];
        inputs[0] = KeyInput(0x10, false);
        for (int i = 0; i < count; i++) {
            inputs[1 + 2 * i] = KeyInput(0x25, false);
            inputs[2 + 2 * i] = KeyInput(0x25, true);
        }
        inputs[inputs.Length - 1] = KeyInput(0x10, true);
        return (int)SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
    }
}
'@
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Collections.Generic;
public static class PharosInputJournalOracle {
    static readonly UTF8Encoding Utf8 = new UTF8Encoding(false, true);
    public static ulong Sum(string text) {
        ulong hash = 0xCBF29CE484222325UL;
        foreach (byte b in Utf8.GetBytes(text)) hash = unchecked((hash ^ b) * 0x100000001B3UL);
        return hash;
    }
    static void Require(bool yes, string why) { if (!yes) throw new Exception("input_journal:" + why); }
    static byte[] Hex(string text) {
        Require(text.Length % 2 == 0, "odd_hex");
        byte[] bytes = new byte[text.Length / 2];
        for (int i = 0; i < bytes.Length; ++i) bytes[i] = Convert.ToByte(text.Substring(i * 2, 2), 16);
        Utf8.GetString(bytes); return bytes;
    }
    static bool Equal(byte[] a, byte[] b) {
        if (a.Length != b.Length) return false;
        for (int i = 0; i < a.Length; ++i) if (a[i] != b[i]) return false;
        return true;
    }
    static byte[] Expected(byte[] before, int at, byte[] token, int prefix) {
        byte[] result = new byte[before.Length + prefix];
        Buffer.BlockCopy(before, 0, result, 0, at);
        Buffer.BlockCopy(token, 0, result, at, prefix);
        Buffer.BlockCopy(before, at, result, at + prefix, before.Length - at);
        return result;
    }
    // Each record is checked against immutable pre-action bytes. Replay is not
    // itself the oracle: every intermediate full body must equal the expected
    // legal scalar prefix, at the exact frozen range and monotone version.
    public static int Validate(string prior, string journal, byte[] before, long version,
        int caret16, string text, byte[] after, long afterVersion) {
        string body = Utf8.GetString(before);
        Require(caret16 >= 0 && caret16 <= body.Length, "caret_range");
        int at = Utf8.GetByteCount(body.Substring(0, caret16));
        byte[] token = Utf8.GetBytes(text);
        Require(journal.StartsWith(prior, StringComparison.Ordinal), "prior_rewritten");
        Require(prior.Length == 0 || prior.EndsWith("\n", StringComparison.Ordinal), "prior_partial");
        string delta = journal.Substring(prior.Length);
        Require(delta.Length > 0 && delta.EndsWith("\n", StringComparison.Ordinal), "missing_or_partial");
        int prefix = 0, records = 0; long previousSeq = -1;
        byte[] replay = (byte[])before.Clone();
        foreach (string raw in delta.Split('\n')) {
            if (raw.Length == 0) continue;
            string line = raw.TrimEnd('\r');
            int sumAt = line.LastIndexOf(" SUM=", StringComparison.Ordinal);
            Require(sumAt > 0 && Sum(line.Substring(0, sumAt)) == UInt64.Parse(line.Substring(sumAt + 5)), "checksum");
            Dictionary<string,string> f = new Dictionary<string,string>(StringComparer.Ordinal);
            foreach (string field in line.Substring(0, sumAt).Split(' ')) {
                int eq = field.IndexOf('='); Require(eq > 0, "field");
                f.Add(field.Substring(0, eq), field.Substring(eq + 1));
            }
            long seq = Int64.Parse(f["SEQ"]);
            Require(seq > 0 && (previousSeq < 0 || seq == previousSeq + 1), "sequence"); previousSeq = seq;
            Require(Int64.Parse(f["VER"]) == version + records, "version");
            Require(f["ORIGIN"] == "human" && f["KIND"] == "human" && f["N"] == "1", "operation");
            string[] spl = f["SPL"].Split(','); Require(spl.Length == 3, "splice_count");
            int start = Int32.Parse(spl[0]), end = Int32.Parse(spl[1]); byte[] inserted = Hex(spl[2]);
            Require(start == at + prefix && end == start && inserted.Length > 0, "frozen_range");
            Require(prefix + inserted.Length <= token.Length, "extra_input");
            for (int i = 0; i < inserted.Length; ++i) Require(inserted[i] == token[prefix + i], "prefix_order");
            int next = prefix + inserted.Length;
            Require(next == token.Length || (token[next] & 0xC0) != 0x80, "split_scalar");
            byte[] changed = new byte[replay.Length + inserted.Length];
            Buffer.BlockCopy(replay, 0, changed, 0, start);
            Buffer.BlockCopy(inserted, 0, changed, start, inserted.Length);
            Buffer.BlockCopy(replay, end, changed, start + inserted.Length, replay.Length - end);
            Require(Equal(changed, Expected(before, at, token, next)), "intermediate_full_body");
            replay = changed; prefix = next; ++records;
        }
        Require(prefix == token.Length && afterVersion == version + records, "terminal_version_or_prefix");
        Require(Equal(replay, after) && Equal(after, Expected(before, at, token, token.Length)), "final_full_body");
        return records;
    }
}
'@
function Shot([string]$name){
  Add-Type -AssemblyName System.Drawing
  Add-Type -AssemblyName System.Windows.Forms
  $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp=New-Object System.Drawing.Bitmap($bounds.Width,$bounds.Height)
  $gfx=[System.Drawing.Graphics]::FromImage($bmp)
  $gfx.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size)
  $gfx.Dispose()
  $path=Join-Path $shotDir ($name + ".png")
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  $bytes=[System.IO.File]::ReadAllBytes($path)
  $uri="$($env:PHAROS_TRANSFER_BASE)/results/$env:PHAROS_TRANSFER_SESSION/$(Split-Path -Leaf $work)/$name.png"
  try{
    $r=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
    Log ("shot " + $name + " bytes=" + $bytes.Length + " upload=" + [int]$r.StatusCode)
  }catch{ throw ('required_screenshot_upload:'+ $_.Exception.Message) }
  return $path
}
function Hex-ToBytes([string]$hex){
  $hex=$hex.Trim()
  if(($hex.Length % 2) -ne 0){ throw "odd hex length" }
  $out=New-Object byte[] ($hex.Length/2)
  for($i=0;$i -lt $out.Length;$i++){ $out[$i]=[System.Convert]::ToByte($hex.Substring($i*2,2),16) }
  return $out
}
function Agent-Text([string]$agentHost,[int]$port,[int]$id,[int]$offset,[int]$count){
  $reply=Agent-Raw $agentHost $port ('{"id":' + $id + ',"op":"read","offset":' + $offset + ',"count":' + $count + '}')
  $hex=([regex]::Match($reply,'"bytes":"([0-9a-f]*)"')).Groups[1].Value
  if($hex -eq '' -and $reply -notmatch '"count":0'){ throw ("no bytes in reply:" + $reply.Substring(0,[Math]::Min(200,$reply.Length))) }
  return [System.Text.Encoding]::UTF8.GetString((Hex-ToBytes $hex))
}
function Json-Escape([string]$s){ return ($s -replace '\\','\\' -replace '"','\"' -replace "`n",'\n' -replace "`r",'\r' -replace "`t",'\t') }
function Agent-Raw([string]$agentHost,[int]$port,[string]$line){
  $c=New-Object System.Net.Sockets.TcpClient
  $c.ReceiveTimeout=15000; $c.SendTimeout=15000
  $c.Connect($agentHost,$port)
  try{
    $s=$c.GetStream()
    $w=New-Object System.IO.StreamWriter($s,[System.Text.Encoding]::UTF8)
    $w.NewLine="`n"; $w.AutoFlush=$true
    $r=New-Object System.IO.StreamReader($s,[System.Text.Encoding]::UTF8)
    $w.WriteLine($line)
    return $r.ReadLine()
  }finally{$c.Close()}
}
function SharedOp([string]$endpoint,[string]$payload){
  $m=[regex]::Match($endpoint,'tcp://([^:]+):(\d+)')
  if(!$m.Success){throw "bad_endpoint:$endpoint"}
  $body=[System.Text.Encoding]::UTF8.GetBytes($payload)
  $head=[System.Text.Encoding]::ASCII.GetBytes($body.Length.ToString() + "`n")
  $c=New-Object System.Net.Sockets.TcpClient
  $c.ReceiveTimeout=15000; $c.SendTimeout=15000
  $c.Connect($m.Groups[1].Value,[int]$m.Groups[2].Value)
  try{
    $s=$c.GetStream()
    $s.Write($head,0,$head.Length); $s.Write($body,0,$body.Length)
    $hdr=New-Object System.Collections.Generic.List[byte]
    $one=New-Object byte[] 1
    while($true){ if($s.Read($one,0,1) -le 0){throw "eof_header"}; if($one[0] -eq 10){break}; $hdr.Add($one[0]) }
    $n=[int][System.Text.Encoding]::ASCII.GetString($hdr.ToArray())
    if($n -le 0 -or $n -gt 1048576){throw "bad_frame:$n"}
    $buf=New-Object byte[] $n; $off=0
    while($off -lt $n){ $k=$s.Read($buf,$off,$n-$off); if($k -le 0){throw "eof_body"}; $off+=$k }
    return [System.Text.Encoding]::UTF8.GetString($buf)
  }finally{$c.Close()}
}
function Read-Shared([string]$path){
  try{
    $fs=New-Object System.IO.FileStream($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
    $sr=New-Object System.IO.StreamReader($fs)
    $s=$sr.ReadToEnd(); $sr.Close(); $fs.Close(); return $s
  }catch{ return "" }
}
function Wait-Pattern([string]$file,[string]$pattern,[int]$seconds,[string]$label){
  $dead=[DateTime]::UtcNow.AddSeconds($seconds)
  $lastLen=0
  while([DateTime]::UtcNow -lt $dead){
    if(Test-Path -LiteralPath $file){
      $t=Read-Shared $file
      if($t.Length -gt 0){
        $lastLen=$t.Length
        $m=[regex]::Match($t,$pattern)
        if($m.Success){return $m}
      }
    }
    Start-Sleep -Milliseconds 500
  }
  Log ("wait_timeout " + $label + " bytes=" + $lastLen)
  Fail 50 ("wait_timeout:" + $label)
  return $null
}
function Probe-Rect([int]$nodeId,[int]$timeoutSec){
  # 坐标测量（只读）。missing 一律失败：节点不存在不是可接受的“点击结果”。
  Remove-Item -LiteralPath ($probeFile+'.out') -ErrorAction SilentlyContinue
  [System.IO.File]::WriteAllText($probeFile, ("NODE_RECT " + $nodeId))
  $dead=[DateTime]::UtcNow.AddSeconds($timeoutSec); $t=''
  while([DateTime]::UtcNow -lt $dead -and $t -eq ''){ Start-Sleep -Milliseconds 200; $t=(Read-Shared ($probeFile+'.out')).Trim() }
  if($t -eq ''){ return $null }
  if($t -match ('NODE_RECT_RESULT ' + $nodeId + ' missing')){ return $null }
  $m=[regex]::Match($t,('NODE_RECT_RESULT ' + $nodeId + ' screen=(\d+),(\d+) click=(-?\d+),(-?\d+) client_click=(\d+),(\d+)'))
  if(!$m.Success){ return $null }
  return @{ screenX=[int]$m.Groups[1].Value; screenY=[int]$m.Groups[2].Value; clickX=[int]$m.Groups[3].Value; clickY=[int]$m.Groups[4].Value }
}
function Send-Click([int]$x,[int]$y,[int]$gate,[string]$label){
  if($x -le 0 -or $y -le 0){ Fail $gate ("bad_click_coords:" + $label + ":" + $x + "," + $y) }
  if([PharosSendInput]::HitPid($x,$y) -ne $proc.Id){ Fail $gate ("click_point_covered:"+$label) }
  # 单次投递：部分成功（sent=1）不得整次重发。模式切换是翻转语义，重发会把刚切好的模式再翻回去。
  $sent=[PharosSendInput]::MouseClickAt($x,$y)
  if($sent -ne 2){ Fail $gate ("click_not_delivered:" + $label + ":sent=" + $sent) }
}
function Parse-ModeTail([string]$tail){
  # 模式判据解析（只看本次点击围栏之后的新增日志）：
  #   'source' = 最后一个 PHAROS_MODE 为 visual=false，本次切到源码；
  #   'visual' = 围栏内只有 visual=true，仍是预览；
  #   'none'   = 围栏内无模式记录。
  # 历史行不可救绿：调用方只传入围栏后子串。
  $mm=[regex]::Matches($tail,'PHAROS_MODE visual=(true|false)')
  if($mm.Count -eq 0){ return 'none' }
  if($mm[$mm.Count-1].Groups[1].Value -eq 'false'){ return 'source' }
  return 'visual'
}
if($env:PHAROS_ACCEPT_SELFTEST -eq '1'){
  $cases=@(
    @('PHAROS_MODE visual=false', 'source'),
    @('PHAROS_MODE visual=true', 'visual'),
    @('', 'none'),
    @("noise`nPHAROS_MODE visual=true`nPHAROS_MODE visual=false", 'source'),
    @("PHAROS_MODE visual=false`nPHAROS_MODE visual=true", 'visual')
  )
  $fail=0
  foreach($c in $cases){
    $got=Parse-ModeTail $c[0]
    if($got -ne $c[1]){ Write-Output ("SELFTEST_FAIL want=" + $c[1] + " got=" + $got); $fail+=1 }
    else{ Write-Output ("SELFTEST_OK " + $c[1]) }
  }
  exit $fail
}
function Last-Selection([string]$logText){
  $ms=[regex]::Matches($logText,'PHAROS_TEXT_SESSION_SELECTION start16=(\d+) end16=(\d+) version=(\d+) node=107')
  if($ms.Count -eq 0){ return $null }
  $m=$ms[$ms.Count-1]
  return @{ start16=[int]$m.Groups[1].Value; end16=[int]$m.Groups[2].Value; version=[int]$m.Groups[3].Value; index=$m.Index }
}
function Bytes-Equal([byte[]]$a,[byte[]]$b){
  if($a.Length -ne $b.Length){ return $false }
  for($i=0;$i -lt $a.Length;$i++){ if($a[$i] -ne $b[$i]){ return $false } }
  return $true
}
function Text-Bytes([string]$s){ return [System.Text.Encoding]::UTF8.GetBytes($s) }
function Expect-Insert([string]$text,[int]$index,[string]$insert){
  if($index -lt 0 -or $index -gt $text.Length){ return $null }
  return $text.Substring(0,$index) + $insert + $text.Substring($index)
}
function Expect-Replace([string]$text,[int]$start,[int]$len,[string]$insert){
  if($start -lt 0 -or $len -lt 0 -or ($start+$len) -gt $text.Length){ return $null }
  return $text.Substring(0,$start) + $insert + $text.Substring($start+$len)
}
function Read-Owner([string]$agentHost,[int]$port,[int]$id){
  return (Read-OwnerFrozen $agentHost $port $id).Text
}
function Read-OwnerFrozen([string]$agentHost,[int]$port,[int]$id){
  $before=Agent-Raw $agentHost $port ('{"id":'+$id+',"op":"snapshot"}')|ConvertFrom-Json
  if(-not $before.ok -or $before.byteLength -gt 262144){throw 'owner_snapshot_scope'}
  $bytes=New-Object System.Collections.Generic.List[byte]
  while($bytes.Count -lt $before.byteLength){
    $reply=Agent-Raw $agentHost $port ('{"id":'+$id+',"op":"read","offset":'+$bytes.Count+',"count":32768}')|ConvertFrom-Json
    if(-not $reply.ok -or $reply.version -ne $before.version -or $reply.offset -ne $bytes.Count -or $reply.count -le 0){throw 'owner_chunk_identity'}
    $chunk=Hex-ToBytes $reply.bytes
    if($chunk.Length -ne $reply.count -or $bytes.Count+$chunk.Length -gt $before.byteLength){throw 'owner_chunk_length'}
    $bytes.AddRange([byte[]]$chunk)
  }
  $end=Agent-Raw $agentHost $port ('{"id":'+$id+',"op":"snapshot"}')|ConvertFrom-Json
  if(-not $end.ok -or $end.version -ne $before.version -or $end.byteLength -ne $before.byteLength -or $end.documentId -ne $before.documentId){throw 'owner_read_changed'}
  $raw=$bytes.ToArray();$utf8=New-Object System.Text.UTF8Encoding($false,$true)
  return [PSCustomObject]@{Bytes=$raw;Text=$utf8.GetString($raw);Version=[long]$before.version;DocumentId=$before.documentId}
}
$ownedApplications=New-Object System.Collections.Generic.List[System.Diagnostics.Process]
$ownedProcessHandles=New-Object System.Collections.Generic.List[IntPtr]
function Hold-ProcessExit([int]$pidValue){
  $handle=[PharosSendInput]::OpenProcess(0x101000,$false,[uint32]$pidValue)
  if($handle -eq [IntPtr]::Zero){Fail 40 'owned_process_exit_handle'}
  $ownedProcessHandles.Add($handle)|Out-Null
  return $handle
}
function Assert-ProcessExit([IntPtr]$handle,[int]$pidValue){
  $exitCode=[uint32]259
  if(-not [PharosSendInput]::GetExitCodeProcess($handle,[ref]$exitCode)){Fail 38 'kernel_exit_read'}
  if($exitCode -ne 0){Fail 38 ('normal_exit_code:'+ $exitCode)}
  Log ('kernel_exit pid='+$pidValue+' code='+$exitCode)
}
try {
# ---- setup ----
$runRoot=if($env:PHAROS_RUN_ROOT){$env:PHAROS_RUN_ROOT}else{'C:\cjgui-windows-w1'}
$root=Join-Path $runRoot 'Pharos Mark Windows Source'
$exe=Join-Path $root 'apps\pharos_mark\target\release\bin\main.exe'
if(!(Test-Path -LiteralPath $exe)){ Fail 40 ("missing_exe:" + $exe) }
$machine=PeMachine $exe
Log ("exe_machine=" + ("0x{0:X}" -f $machine))
if($machine -ne 0x8664){ Fail 40 ("not_x64:" + $machine) }
[void][PharosSendInput]::SetProcessDPIAware()
$work=Join-Path $runRoot ('accept-run-'+[Guid]::NewGuid().ToString('N'))
$env:PHAROS_DATA_HOME=$work
$sdkRoot=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$env:PATH=((Join-Path $sdkRoot 'runtime\lib\windows_x86_64_cjnative'),(Join-Path $sdkRoot 'third_party\llvm\bin'),(Join-Path $sdkRoot 'bin'),$env:PATH) -join ';'
$docDir=Join-Path $work '带空格 文档'
New-Item -ItemType Directory -Path $docDir -Force|Out-Null
$shotDir=Join-Path $work 'shots'
New-Item -ItemType Directory -Path $shotDir -Force|Out-Null
$channelDir=Join-Path $work 'channel'
New-Item -ItemType Directory -Path $channelDir -Force|Out-Null
$fixture=Join-Path $docDir '写作链.md'
$fixtureText=@'
# 写作验收

首段正文，包含中文与 *强调*。

- 条目一
- 条目二

```cj
code()
```

尾段。
'@
$fixtureText+="`n"
[System.IO.File]::WriteAllText($fixture,$fixtureText,[System.Text.Encoding]::UTF8)
$fixtureBytes=[System.IO.File]::ReadAllBytes($fixture)
$fixtureSha=(Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash.ToLowerInvariant()
Log ("fixture sha=" + $fixtureSha + " bytes=" + (Get-Item -LiteralPath $fixture).Length)
$outLog=Join-Path $work 'editor-stdout.log'
$errLog=Join-Path $work 'editor-stderr.log'
# ---- launch ----
$launchMark=[DateTime]::UtcNow
# 探针缝：仅坐标测量（NODE_RECT）；点击一律 SendInput。
$probeFile=Join-Path $work 'click-probe.txt'
Remove-Item -LiteralPath $probeFile -ErrorAction SilentlyContinue
Remove-Item -LiteralPath ($probeFile+'.out') -ErrorAction SilentlyContinue
$env:PHAROS_WINDOWS_TEST_PROBE_FILE=$probeFile
$proc=Start-Process -FilePath $exe -ArgumentList @('--open', ('"'+$fixture+'"'), '--agent-channel', ('"'+$channelDir+'"')) -WorkingDirectory $docDir -PassThru -RedirectStandardOutput $outLog -RedirectStandardError $errLog
Log ("launcher pid=" + $proc.Id)
$ownedApplications.Add($proc)|Out-Null
$procKernel=Hold-ProcessExit $proc.Id
$hwnd=[IntPtr]::Zero
$dead=[DateTime]::UtcNow.AddSeconds(60)
while([DateTime]::UtcNow -lt $dead -and $hwnd -eq [IntPtr]::Zero){
  try{ $proc.Refresh(); $hwnd=$proc.MainWindowHandle }catch{}
  Start-Sleep -Milliseconds 500
}
if($hwnd -eq [IntPtr]::Zero){ Fail 50 "no_hwnd" }
Log ("hwnd=" + $hwnd)
$client=New-Object PharosSendInput+RECT
if(-not [PharosSendInput]::GetClientRect($hwnd,[ref]$client)){Fail 30 'client_geometry'}
$dpi=[PharosSendInput]::GetDpiForWindow($hwnd)
Log ("geometry client="+($client.right-$client.left)+'x'+($client.bottom-$client.top)+' dpi='+$dpi+' exe_sha='+((Get-FileHash -LiteralPath $exe).Hash.ToLowerInvariant()))
if([Math]::Abs(($client.right-$client.left)*96.0/$dpi-1100) -gt 1 -or [Math]::Abs(($client.bottom-$client.top)*96.0/$dpi-780) -gt 1){Fail 30 'not_default_1100x780'}
# Use the default product size. Record its real client geometry; do not enlarge
# the window to make clipped controls reachable.
# 等场景稳定（连续两次 PROGRESS 的 scene 相同），避免测量/点击跨重发布。
$settleDead=[DateTime]::UtcNow.AddSeconds(20); $lastScene=-1; $stable=0
while([DateTime]::UtcNow -lt $settleDead -and $stable -lt 2){
  Start-Sleep -Milliseconds 400
  $ms=[regex]::Matches((Read-Shared $outLog),'PHAROS_PROGRESS turn=\d+ scene=(\d+) accepted=(\d+)')
  if($ms.Count -gt 0){
    $s=[int]$ms[$ms.Count-1].Groups[2].Value
    if($s -eq $lastScene){ $stable += 1 } else { $stable=0; $lastScene=$s }
  }
}
Log ("scene_stable=" + $lastScene + " stable_ticks=" + $stable)
Shot '01-opened'
# ---- agent channel discovery ----
$m=Wait-Pattern $outLog 'PHAROS_AGENT_CHANNEL listen=(\S+) socket=(\S+) manifest_written=(\S+).*descriptor=(\S+) descriptor_written=(\S+)' 90 'agent_channel'
$listenStatus=$m.Groups[1].Value; $socketPath=$m.Groups[2].Value; $descriptorPath=$m.Groups[4].Value; $descWritten=$m.Groups[5].Value
Log ("agent listen=" + $listenStatus + " socket=" + $socketPath + " descriptor_written=" + $descWritten)
if($listenStatus -ne '0'){ Fail 31 ("agent_listen refused:" + $listenStatus) }
$rv=[System.IO.File]::ReadAllText($socketPath).Trim()
Log ("rendezvous=" + $rv)
$rm=[regex]::Match($rv,'^([^:]+):(\d+)$')
if(!$rm.Success){ Fail 31 ("bad_rendezvous:" + $rv) }
$agentHost=$rm.Groups[1].Value; $agentPort=[int]$rm.Groups[2].Value
$manifest=Get-Content -LiteralPath (Join-Path $channelDir 'manifest.json') -Raw|ConvertFrom-Json
$token=$manifest.token
Log ("manifest token_len=" + $token.Length)
$reply=Agent-Raw $agentHost $agentPort '{"id":1,"op":"discover"}'
Log ("discover=" + $reply.Substring(0,[Math]::Min(200,$reply.Length)))
$snap=Agent-Raw $agentHost $agentPort '{"id":2,"op":"snapshot"}'
Log ("snapshot=" + $snap)
$baseVersion=([regex]::Match($snap,'"version":(\d+)')).Groups[1].Value
$read=Agent-Raw $agentHost $agentPort '{"id":3,"op":"read","offset":0,"count":4096}'
Log ("read0=" + $read.Substring(0,[Math]::Min(160,$read.Length)))
# ---- foreground（失败即失败，不再只记录）----
[PharosSendInput]::SetForegroundWindow($hwnd)|Out-Null
Start-Sleep -Milliseconds 300
$fg=[PharosSendInput]::ForegroundPid()
$fgOk=($fg -eq $proc.Id)
Log ("foreground_ok=" + $fgOk + " fg_pid=" + $fg)
if(-not $fgOk){ Fail 30 "foreground_not_acquired" }
Start-Sleep -Milliseconds 500
# ---- 模式切换：NODE_RECT 测量 + SendInput 系统鼠标（单次投递，有界观察）----
# 模式切换只允许一次系统点击：每次点击都会翻转 visual/source，多发即把刚切好的模式再翻回去。
# 只看本次点击之后新增日志里的 PHAROS_MODE，并以最后一个为准；历史行不可救绿。
$modeMark=(Read-Shared $outLog).Length
$r114=$null
$dead114=[DateTime]::UtcNow.AddSeconds(20)
while([DateTime]::UtcNow -lt $dead114 -and $r114 -eq $null){ $r114=Probe-Rect 114 10; if($r114 -eq $null){ Start-Sleep -Milliseconds 500 } }
if($r114 -eq $null){ Fail 30 "node114_missing_or_unmeasured" }
Log ("rect114 click=" + $r114.clickX + "," + $r114.clickY)
Send-Click $r114.clickX $r114.clickY 30 "mode_switch"
$modeDead=[DateTime]::UtcNow.AddSeconds(10)
while([DateTime]::UtcNow -lt $modeDead){
  $observed=Read-Shared $outLog
  if($observed.Length -gt $modeMark -and (Parse-ModeTail $observed.Substring($modeMark)) -ne 'none'){break}
  Start-Sleep -Milliseconds 100
}
$tailNow=Read-Shared $outLog
$newTail=if($tailNow.Length -gt $modeMark){ $tailNow.Substring($modeMark) } else { '' }
$modeResult=Parse-ModeTail $newTail
Log ("mode_result=" + $modeResult)
if($modeResult -eq 'none'){ Fail 30 "mode_switch_no_record_after_click" }
if($modeResult -ne 'source'){ Fail 30 "mode_switch_stayed_visual" }
Start-Sleep -Milliseconds 1000
# ---- 编辑器聚焦：NODE_RECT 107（源模式场景）+ SendInput 点击（单次投递，有界观察）----
$selBefore=(Last-Selection (Read-Shared $outLog))
$r107=$null
$dead107=[DateTime]::UtcNow.AddSeconds(15)
while([DateTime]::UtcNow -lt $dead107 -and $r107 -eq $null){ $r107=Probe-Rect 107 10; if($r107 -eq $null){ Start-Sleep -Milliseconds 700 } }
if($r107 -eq $null){ Fail 30 "editor107_missing_or_unmeasured" }
Log ("rect107 click=" + $r107.clickX + "," + $r107.clickY)
Send-Click $r107.clickX $r107.clickY 30 "editor_focus"
$selNow=$null
$selDead=[DateTime]::UtcNow.AddSeconds(10)
while([DateTime]::UtcNow -lt $selDead){
  Start-Sleep -Milliseconds 300
  $s=Last-Selection (Read-Shared $outLog)
  if($s -ne $null -and ($selBefore -eq $null -or $s.index -ne $selBefore.index)){ $selNow=$s; break }
}
if($selNow -eq $null){ Fail 30 "editor_focus_no_selection_update" }
$caret0=$selNow.start16
if($selNow.end16 -ne $caret0){ Fail 30 ("editor_focus_noncollapsed:" + $selNow.start16 + ":" + $selNow.end16) }
Log ("caret0=" + $caret0 + " selver=" + $selNow.version)
Start-Sleep -Milliseconds 500
$middleOwner=Read-Owner $agentHost $agentPort 29
$middleAt=$middleOwner.IndexOf('正文')+2
if($middleAt -lt 2 -or $middleAt -ge $middleOwner.Length-2){Fail 32 'middle_fixture_position'}
$homeSent=[PharosSendInput]::KeyDown(0x11)+[PharosSendInput]::KeyTap(0x24)+[PharosSendInput]::KeyUp(0x11)
$moveSent=0
for($i=0;$i -lt $middleAt;$i++){ $moveSent += [PharosSendInput]::KeyTap(0x27) }
if($homeSent -ne 4 -or $moveSent -ne 2*$middleAt){Fail 32 'middle_navigation_delivery'}
Start-Sleep -Milliseconds 600
$middleSelection=Last-Selection (Read-Shared $outLog)
if($middleSelection -eq $null -or $middleSelection.start16 -ne $middleAt -or $middleSelection.end16 -ne $middleAt){Fail 32 'middle_selection_exact'}
$caret0=$middleAt
# ---- 连续系统输入（真实节奏；核发送数）----
$typeToken='WINCHAIN-01中'+[char]::ConvertFromUtf32(0x1F600)
$inputBefore=Read-OwnerFrozen $agentHost $agentPort 30
$t0=$inputBefore.Text
if(-not (Bytes-Equal $fixtureBytes (Text-Bytes $t0))){Fail 30 'initial_owner_not_frozen_fixture'}
$inputJournal=$fixture+'.pharos-journal'
$journalBefore=if(Test-Path -LiteralPath $inputJournal){Read-Shared $inputJournal}else{''}
[IO.File]::WriteAllText((Join-Path $work 'typing-journal-before.txt'),$journalBefore)
[IO.File]::WriteAllBytes((Join-Path $work 'typing-owner-before.bin'),[byte[]]$inputBefore.Bytes)
Log ("t0 len=" + $t0.Length)
$sent=[PharosSendInput]::TypeUnicode($typeToken)
Log ("typing sent=" + $sent + " expect=" + (2*$typeToken.Length))
if($sent -ne (2*$typeToken.Length)){ Fail 32 ("sendinput_count:" + $sent) }
Start-Sleep -Milliseconds 2500
$inputAfter=Read-OwnerFrozen $agentHost $agentPort 31
$t1=$inputAfter.Text
$ver2=$inputAfter.Version
$journalAfter=Read-Shared $inputJournal
[IO.File]::WriteAllText((Join-Path $work 'typing-journal-before.txt'),$journalBefore)
[IO.File]::WriteAllText((Join-Path $work 'typing-journal-after.txt'),$journalAfter)
[IO.File]::WriteAllBytes((Join-Path $work 'typing-owner-before.bin'),[byte[]]$inputBefore.Bytes)
[IO.File]::WriteAllBytes((Join-Path $work 'typing-owner-after.bin'),[byte[]]$inputAfter.Bytes)
[PSCustomObject]@{Pid=$proc.Id;DocumentId=$inputBefore.DocumentId;AfterDocumentId=$inputAfter.DocumentId;BeforeVersion=$inputBefore.Version;AfterVersion=$inputAfter.Version;Caret16=$caret0;Token=$typeToken;BeforeBytes=$inputBefore.Bytes.Length;AfterBytes=$inputAfter.Bytes.Length;Journal=$inputJournal}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $work 'typing-owner.json') -Encoding UTF8
$expect1=Expect-Insert $t0 $caret0 $typeToken
if($expect1 -eq $null){ Fail 32 "oracle_span_invalid" }
if(!(Bytes-Equal (Text-Bytes $t1) (Text-Bytes $expect1))){ Fail 32 ("typed_fulltext_mismatch got=" + $t1.Length + " want=" + $expect1.Length) }
if($inputAfter.DocumentId -ne $inputBefore.DocumentId){Fail 32 'typing_document_changed'}
try{$inputRecords=[PharosInputJournalOracle]::Validate($journalBefore,$journalAfter,[byte[]]$inputBefore.Bytes,$inputBefore.Version,$caret0,$typeToken,[byte[]]$inputAfter.Bytes,$inputAfter.Version)}catch{Fail 32 ('typing_transaction_prefix:'+$_.Exception.Message)}
Log ('typing_journal_exact records='+$inputRecords+' version='+$inputBefore.Version+'->'+$inputAfter.Version+' bytes='+$inputBefore.Bytes.Length+'->'+$inputAfter.Bytes.Length)
Log ("typed ok version=" + $ver2)
Shot '02-typed'
# ---- 非空选区免点击替换 ----
$selAfterType=Last-Selection (Read-Shared $outLog)
if($selAfterType -ne $null){ Log ("sel_after_type=" + $selAfterType.start16 + ":" + $selAfterType.end16) }
$selectionSteps=3
$selectionLength16=4
$selectionStart16=$caret0+$typeToken.Length-$selectionLength16
$sentShift=[PharosSendInput]::ShiftLeft($selectionSteps)
Log ("shiftleft sent=" + $sentShift + " expect=" + (2 + 2*$selectionSteps))
if($sentShift -ne (2 + 2*$selectionSteps)){ Fail 33 ("shiftleft_count:" + $sentShift) }
Start-Sleep -Milliseconds 600
$selectedBeforePreview=Last-Selection (Read-Shared $outLog)
if($selectedBeforePreview -eq $null -or $selectedBeforePreview.start16 -ne $selectionStart16 -or
  $selectedBeforePreview.end16 -ne ($selectionStart16+$selectionLength16)) {Fail 33 'frozen_selection_span_mismatch'}
$beforePreview=Read-Owner $agentHost $agentPort 310
if(-not (Bytes-Equal (Text-Bytes $beforePreview) (Text-Bytes $t1))){Fail 33 'before_preview_owner_changed'}
# Real mode-button clicks enter Markdown preview, then return to source with
# no intervening edit. There is no editor click after this boundary.
foreach($want in @('visual','source')){
  $boundary=(Read-Shared $outLog).Length
  $modeRect=Probe-Rect 114 10
  if($modeRect -eq $null){Fail 33 'preview_mode_control_missing'}
  Send-Click $modeRect.clickX $modeRect.clickY 33 ('preview_'+$want)
  $modeDeadline=[DateTime]::UtcNow.AddSeconds(10);$observed='none'
  while([DateTime]::UtcNow -lt $modeDeadline){
    $logNow=Read-Shared $outLog
    if($logNow.Length -gt $boundary){$observed=Parse-ModeTail $logNow.Substring($boundary)}
    if($observed -eq $want){break};Start-Sleep -Milliseconds 100
  }
  if($observed -ne $want){Fail 33 ('preview_mode_failed:'+ $want)}
  Start-Sleep -Milliseconds 500
  $ownerDuringPreview=Read-Owner $agentHost $agentPort 311
  if(-not (Bytes-Equal (Text-Bytes $ownerDuringPreview) (Text-Bytes $t1))){Fail 33 'preview_mutated_owner'}
  if($want -eq 'visual'){Shot '02a-markdown-preview'}
}
$restored=Last-Selection (Read-Shared $outLog)
if($restored -eq $null -or $restored.start16 -ne $selectionStart16 -or
  $restored.end16 -ne ($selectionStart16+$selectionLength16)){Fail 33 'preview_source_selection_not_restored'}
$sentX=[PharosSendInput]::TypeUnicode('X')
if($sentX -ne 2){ Fail 33 ("replace_sendinput_count:" + $sentX) }
Start-Sleep -Milliseconds 2500
$t2=Read-Owner $agentHost $agentPort 32
$expect2=Expect-Replace $t1 $selectionStart16 $selectionLength16 'X'
if($expect2 -eq $null){ Fail 33 "replace_oracle_span_invalid" }
if(!(Bytes-Equal (Text-Bytes $t2) (Text-Bytes $expect2))){ Fail 33 ("replace_fulltext_mismatch got=" + $t2.Length + " want=" + $expect2.Length) }
Log ("selection_replace ok")
Shot '03-replaced'
# Human undo/redo runs before the public Agent write.
$undoSent=[PharosSendInput]::KeyDown(0x11)+[PharosSendInput]::KeyTap(0x5A)+[PharosSendInput]::KeyUp(0x11)
if($undoSent -ne 4){Fail 36 'human_undo_delivery'}
Start-Sleep -Milliseconds 800
$humanUndo=Read-Owner $agentHost $agentPort 312
if(-not (Bytes-Equal (Text-Bytes $humanUndo) (Text-Bytes $t1))){Fail 36 'human_undo_exact_bytes'}
$redoSent=[PharosSendInput]::KeyDown(0x11)+[PharosSendInput]::KeyTap(0x59)+[PharosSendInput]::KeyUp(0x11)
if($redoSent -ne 4){Fail 36 'human_redo_delivery'}
Start-Sleep -Milliseconds 800
$humanRedo=Read-Owner $agentHost $agentPort 313
if(-not (Bytes-Equal (Text-Bytes $humanRedo) (Text-Bytes $t2))){Fail 36 'human_redo_exact_bytes'}
# ---- agent edit then human continues ----
$snap3=Agent-Raw $agentHost $agentPort '{"id":4,"op":"snapshot"}'
$baseV=([regex]::Match($snap3,'"version":(\d+)')).Groups[1].Value
$apply=Agent-Raw $agentHost $agentPort ('{"id":5,"op":"apply","baseVersion":' + $baseV + ',"token":"' + (Json-Escape $token) + '","requestId":"accept:1","splices":[{"start":0,"end":0,"text":"[AG]"}]}')
Log ("apply=" + $apply.Substring(0,[Math]::Min(240,$apply.Length)))
if($apply -notmatch '"ok":true'){ Fail 34 ("agent apply refused:" + $apply) }
Start-Sleep -Milliseconds 2000
$t3=Read-Owner $agentHost $agentPort 33
$expect3='[AG]' + $t2
if(!(Bytes-Equal (Text-Bytes $t3) (Text-Bytes $expect3))){ Fail 34 ("agent_fulltext_mismatch got=" + $t3.Length + " want=" + $expect3.Length) }
$selAfterAgent=Last-Selection (Read-Shared $outLog)
$caretAfterAgent=$selectionStart16 + 1 + 4
if($selAfterAgent -ne $null -and $selAfterAgent.index -gt $selNow.index){ $caretAfterAgent=$selAfterAgent.start16 }
Log ("caret_after_agent=" + $caretAfterAgent)
$sentH=[PharosSendInput]::TypeUnicode('H')
if($sentH -ne 2){ Fail 34 ("human_sendinput_count:" + $sentH) }
Start-Sleep -Milliseconds 2500
$t4=Read-Owner $agentHost $agentPort 34
$expect4=Expect-Insert $t3 $caretAfterAgent 'H'
if($expect4 -eq $null){ Fail 34 "human_oracle_span_invalid" }
if(!(Bytes-Equal (Text-Bytes $t4) (Text-Bytes $expect4))){ Fail 34 ("human_fulltext_mismatch got=" + $t4.Length + " want=" + $expect4.Length) }
Log ("human_after_agent ok")
Shot '04-agent-human'
# ---- undo/redo/save via shared-operation framed TCP ----
if($descWritten -ne 'True' -or !(Test-Path -LiteralPath $descriptorPath)){ Fail 35 ("no shared descriptor") }
$descLines=Get-Content -LiteralPath $descriptorPath
if($descLines[0] -ne 'PROTOCOL CJGUI_SHARED_OPERATION/2' -or $descLines[-1] -ne 'END'){ Fail 35 "bad descriptor framing" }
function Desc-Field([string]$label){
  foreach($l in $descLines){ $p=$l.Split(' '); if($p[0] -eq $label -and $p.Count -eq 3){
    return [System.Text.Encoding]::UTF8.GetString((Hex-ToBytes $p[2])) } }
  throw ("missing field:" + $label)
}
$soSocket=Desc-Field 'SOCKET_PATH_UTF8_HEX'
$soCap=Desc-Field 'CAPABILITY_UTF8_HEX'
$PROTO='PROTOCOL CJGUI_SHARED_OPERATION/2'
function So-Invoke([string]$action,[string]$ver){
  $payload=$PROTO + "`nAUTH " + $soCap + "`nINVOKE " + $ver + " " + $action + " 1 0`nID " + $soDocumentId
  return SharedOp $soSocket $payload
}
function So-Context{
  $payload=$PROTO + "`nAUTH " + $soCap + "`nGET_CONTEXT 0"
  return SharedOp $soSocket $payload
}
Log ("shared endpoint=" + $soSocket)
$ctx0=So-Context
Log ("context0=" + $ctx0.Substring(0,[Math]::Min(200,$ctx0.Length)))
# Bind the declared public target to the same document as the owner channel.
$identity=Agent-Raw $agentHost $agentPort '{"id":60,"op":"snapshot"}'|ConvertFrom-Json
$soDocumentId=''
foreach($row in ($ctx0 -split "`n")){
  $fm=[regex]::Match($row.Trim(),'^FIELD (\d+) sessionDocumentId STRING (\d+) ([0-9a-fA-F]+)$')
  if($fm.Success -and [Text.Encoding]::UTF8.GetString((Hex-ToBytes $fm.Groups[3].Value)) -eq $identity.documentId){
    if($soDocumentId -ne ''){throw 'ambiguous_shared_document'}
    $soDocumentId=$fm.Groups[1].Value
  }
}
if($soDocumentId -eq ''){throw 'missing_shared_document_target'}
$undoV=([regex]::Match((Agent-Raw $agentHost $agentPort '{"id":6,"op":"snapshot"}'),'"version":(\d+)')).Groups[1].Value
$undo=So-Invoke 'UNDO' $undoV
Log ("undo=" + $undo.Substring(0,[Math]::Min(240,$undo.Length)))
if($undo -notmatch '(?m)^APPLIED true\r?$'){ Fail 36 'undo_public_refused' }
Start-Sleep -Milliseconds 2000
$readU=Read-Owner $agentHost $agentPort 35
# 撤销最后一笔（人的 'H'）后应回到 agent 修改后的全文 t3
if(!(Bytes-Equal (Text-Bytes $readU) (Text-Bytes $t3))){ Fail 36 ("undo_fulltext_mismatch got=" + $readU.Length + " want=" + $t3.Length) }
Log ("undo ok")
$redoV=([regex]::Match((Agent-Raw $agentHost $agentPort '{"id":7,"op":"snapshot"}'),'"version":(\d+)')).Groups[1].Value
$redo=So-Invoke 'REDO' $redoV
Log ("redo=" + $redo.Substring(0,[Math]::Min(240,$redo.Length)))
if($redo -notmatch '(?m)^APPLIED true\r?$'){ Fail 36 'redo_public_refused' }
Start-Sleep -Milliseconds 2000
$readR=Read-Owner $agentHost $agentPort 36
if(!(Bytes-Equal (Text-Bytes $readR) (Text-Bytes $t4))){ Fail 36 ("redo_fulltext_mismatch got=" + $readR.Length + " want=" + $t4.Length) }
Log ("redo ok")
Shot '05-undoredo'
# ---- save, verify file bytes, close, reopen in a new instance ----
$saveV=([regex]::Match((Agent-Raw $agentHost $agentPort '{"id":9,"op":"snapshot"}'),'"version":(\d+)')).Groups[1].Value
$save=So-Invoke 'SAVE' $saveV
Log ("save=" + $save.Substring(0,[Math]::Min(240,$save.Length)))
if($save -notmatch '(?m)^APPLIED true\r?$'){ Fail 37 'save_public_refused' }
Start-Sleep -Milliseconds 2500
$savedBytes=[System.IO.File]::ReadAllBytes($fixture)
$ownerText=Read-Owner $agentHost $agentPort 37
$ownerRaw=[System.Text.Encoding]::UTF8.GetBytes($ownerText)
if(!(Bytes-Equal $savedBytes $ownerRaw)){ Fail 37 ("saved file bytes differ from owner v" + $saveV) }
$savedSha=(Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash.ToLowerInvariant()
Log ("save ok sha=" + $savedSha)
Shot '06-saved'
if([PharosSendInput]::ForegroundPid() -ne $proc.Id){Fail 38 'close_foreground_identity'}
$closeSent=[PharosSendInput]::KeyDown(0x12)+[PharosSendInput]::KeyTap(0x73)+[PharosSendInput]::KeyUp(0x12)
if($closeSent -ne 4){Fail 38 'close_system_input_count'}
$dead=[DateTime]::UtcNow.AddSeconds(20)
while([DateTime]::UtcNow -lt $dead -and !$proc.HasExited){ Start-Sleep -Milliseconds 500; try{$proc.Refresh()}catch{} }
if(!$proc.HasExited){ Fail 38 "editor did not close" }
Assert-ProcessExit $procKernel $proc.Id
Log ("closed cleanly")
# ---- new instance reopens the same file ----
$launchMark2=[DateTime]::UtcNow
New-Item -ItemType Directory -Path ($channelDir + '-2') -Force|Out-Null
$proc2=Start-Process -FilePath $exe -ArgumentList @('--open', ('"'+$fixture+'"'), '--agent-channel', ('"'+$channelDir+'-2"')) -WorkingDirectory $docDir -PassThru -RedirectStandardOutput (Join-Path $work 'editor2-stdout.log') -RedirectStandardError (Join-Path $work 'editor2-stderr.log')
Log ("editor2 pid=" + $proc2.Id)
$ownedApplications.Add($proc2)|Out-Null
$proc2Kernel=Hold-ProcessExit $proc2.Id
if($proc2.Id -eq $proc.Id){Fail 39 "fresh_pid_required"}
$rv2=''
$dead=[DateTime]::UtcNow.AddSeconds(90)
while([DateTime]::UtcNow -lt $dead -and $rv2 -eq ''){
  Start-Sleep -Milliseconds 1000
  foreach($f in (Get-ChildItem -LiteralPath ($channelDir + '-2') -File -ErrorAction SilentlyContinue)){ if($f.Name -ne 'manifest.json' -and $f.Name -ne 'endpoint.descriptor'){ $rv2=[System.IO.File]::ReadAllText($f.FullName).Trim() } }
}
if($rv2 -eq ''){ Fail 39 "second instance channel missing" }
$rm2=[regex]::Match($rv2,'^([^:]+):(\d+)$')
$read20=Read-Owner $rm2.Groups[1].Value ([int]$rm2.Groups[2].Value) 38
$raw20=[System.Text.Encoding]::UTF8.GetBytes($read20)
if(!(Bytes-Equal $savedBytes $raw20)){ Fail 39 "reopened bytes differ" }
Log ("reopen ok bytes=" + $raw20.Length)
$oldProc=$proc;$oldLog=$outLog
$proc=$proc2;$outLog=Join-Path $work 'editor2-stdout.log'
$proc.Refresh();$hwnd=$proc.MainWindowHandle
[PharosSendInput]::SetForegroundWindow($hwnd)|Out-Null
Start-Sleep -Milliseconds 300
if([PharosSendInput]::ForegroundPid() -ne $proc.Id){Fail 39 'reopen_foreground'}
$reopenMode=Parse-ModeTail (Read-Shared $outLog)
if($reopenMode -ne 'source'){
  $r=Probe-Rect 114 10;if($r -eq $null){Fail 39 'reopen_mode_missing'}
  Send-Click $r.clickX $r.clickY 39 'reopen_source'
  Start-Sleep -Milliseconds 500
}
$selectionFence=(Read-Shared $outLog).Length
$r=Probe-Rect 107 10;if($r -eq $null){Fail 39 'reopen_editor_missing'}
Send-Click $r.clickX $r.clickY 39 'reopen_focus'
$reopenSel=Wait-Pattern $outLog ('(?s)^.{'+$selectionFence+'}.*PHAROS_TEXT_SESSION_SELECTION start16=(\d+) end16=(\d+) version=(\d+) node=107') 10 'reopen_selection'
$reopenAt=[int]$reopenSel.Groups[1].Value
if([int]$reopenSel.Groups[2].Value -ne $reopenAt){Fail 39 'reopen_selection_not_caret'}
if([PharosSendInput]::TypeUnicode('R') -ne 2){Fail 39 'reopen_input_count'}
Start-Sleep -Milliseconds 800
$reopenAfter=Read-Owner $rm2.Groups[1].Value ([int]$rm2.Groups[2].Value) 39
$reopenExpected=Expect-Insert $read20 $reopenAt 'R'
if(-not (Bytes-Equal (Text-Bytes $reopenAfter) (Text-Bytes $reopenExpected))){Fail 39 'reopened_editor_cannot_input_exact'}
$close2Sent=[PharosSendInput]::KeyDown(0x12)+[PharosSendInput]::KeyTap(0x73)+[PharosSendInput]::KeyUp(0x12)
if($close2Sent -ne 4){Fail 38 'reopen_close_system_count'}

$dead=[DateTime]::UtcNow.AddSeconds(20)
while([DateTime]::UtcNow -lt $dead -and !$proc2.HasExited){ Start-Sleep -Milliseconds 500; try{$proc2.Refresh()}catch{} }
if(!$proc2.HasExited){ try{Stop-Process -Id $proc2.Id -Force}catch{}; Fail 38 "editor2 did not close" }
Assert-ProcessExit $proc2Kernel $proc2.Id
$final=[PSCustomObject]@{FixtureSha256=$fixtureSha;SavedSha256=$savedSha;TypedLen=$t1.Length;ReplacedLen=$t2.Length;AfterHumanLen=$t4.Length;SavedBytes=$savedBytes.Length;ReopenedBytes=$raw20.Length;Endpoint=$soSocket}
$final|ConvertTo-Json -Depth 4
exit 0

} finally {
  foreach($owned in $ownedApplications){
    try{ $owned.Refresh(); if(-not $owned.HasExited){
      $actual=Get-CimInstance Win32_Process -Filter ("ProcessId="+$owned.Id)
      if($actual.ExecutablePath -eq $exe){ Stop-Process -Id $owned.Id -Force;[void]$owned.WaitForExit(5000) }
    }}catch{}
  }
  $uploadFailed=$false
  if($work -and (Test-Path $work)){
    foreach($file in (Get-ChildItem -LiteralPath $work -File | Where-Object {$_.Name -like '*.log' -or $_.Name -like '*probe*' -or $_.Name -like 'typing-*'})){
      try{ Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$env:PHAROS_TRANSFER_BASE/results/$env:PHAROS_TRANSFER_SESSION/$(Split-Path -Leaf $work)/$($file.Name)" -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -InFile $file.FullName | Out-Null }catch{$uploadFailed=$true;Write-Output ('EVIDENCE_UPLOAD_FAILED '+$file.FullName+' '+$_.Exception.Message)}
    }
  }
  foreach($handle in $ownedProcessHandles){[void][PharosSendInput]::CloseHandle($handle)}
  if($uploadFailed){throw 'required_evidence_upload_failed'}
}
