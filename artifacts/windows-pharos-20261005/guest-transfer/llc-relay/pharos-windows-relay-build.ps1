# Pharos Windows relay 构建正式入口（构建期交换 llc + 校验恢复 + 注入核验）
#
# 背景：Windows 目标下 CJStackPointerInserter 在 pharos_mark 单个巨大函数上病态；
# relay 用同一 bitcode 在 Mac 产出的 obj 注入。本脚本是该机制的唯一正式入口：
#   1) 前置核 SDK llc.exe 为原版（哈希）；
#   2) 读 relay-manifest.json（Mac 侧生成的冻结关系：BC/obj/wrapper 哈希与 flags）；
#   3) 把 hash 门控 wrapper 交换进 SDK（llc-real.exe 保留原版）；
#   4) 运行构建；无论成败，finally 恢复原版 llc.exe 并核哈希；
#   5) 核验本轮捕获 BC == manifest.expect_bc、注入日志与 obj、EXE 产出；
# 任一失败非零退出，绝不按文件名注入旧 obj，绝不留长期全局替换。
$ErrorActionPreference='Continue'
$sdk=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$llvmBin=Join-Path $sdk 'third_party\llvm\bin'
$work='C:\cjgui-windows-w1\llc-relay'
$root='C:\cjgui-windows-w1\Pharos Mark Windows Source'
$ORIG_LLC_SHA='1ea683623104335fe503b5c603e70faaaf14517c31672fa35a6b3b7f8580c770'

function Fail([int]$code,[string]$msg){ Write-Output ("RELAY_FAIL code=" + $code + " " + $msg); exit $code }

function Get-Sha([string]$path){
  # 防御瞬时锁（新构建的 exe 可能正被扫描）：重试 5 次，仍失败返回空串。
  for($i=0;$i -lt 5;$i++){
    try{
      $h=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
      if($h){ return $h.ToLowerInvariant() }
    }catch{ }
    Start-Sleep -Milliseconds 400
  }
  return ""
}

# ---- 1. 前置：SDK llc 必须是原版 ----
if(!(Test-Path "$llvmBin\llc.exe")){ Fail 41 "llc_missing" }
if(!(Test-Path "$llvmBin\llc-real.exe")){ Fail 41 "llc_real_missing" }
$llcNow=Get-Sha "$llvmBin\llc.exe"
if($llcNow -eq ""){ Fail 41 "llc_hash_unreadable" }
if($llcNow -ne $ORIG_LLC_SHA){ Fail 41 ("llc_not_original:" + $llcNow) }

# ---- 2. manifest ----
$manifestPath=Join-Path $work 'relay-manifest.json'
if(!(Test-Path $manifestPath)){ Fail 43 "manifest_missing" }
$mf=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if($mf.schema -ne 'pharos-windows-relay/1'){ Fail 43 ("manifest_schema:" + $mf.schema) }
Write-Output ("MANIFEST bc=" + $mf.expect_bc_sha256 + " obj=" + $mf.expect_obj_sha256 + " wrapper=" + $mf.wrapper_sha256)

# wrapper 二进制核验
$wrapper="$work\llc-wrapper-v2.exe"
if(!(Test-Path $wrapper)){ Fail 43 "wrapper_missing" }
$wrapperSha=Get-Sha $wrapper
if($wrapperSha -eq ""){ Fail 43 "wrapper_hash_unreadable" }
if($wrapperSha -ne $mf.wrapper_sha256){ Fail 43 ("wrapper_sha_mismatch:" + $wrapperSha) }
# 待注入 obj 核验
$relayObj="$work\pharos_mark.o"
if(!(Test-Path $relayObj)){ Fail 43 "relay_obj_missing" }
$objSha=Get-Sha $relayObj
if($objSha -eq ""){ Fail 43 "relay_obj_hash_unreadable" }
if($objSha -ne $mf.expect_obj_sha256){ Fail 43 ("relay_obj_sha_mismatch:" + $objSha) }
# expect 文件由 manifest 生成（wrapper 注入前还会自行复核一次）
[System.IO.File]::WriteAllText("$work\relay-expect.txt", ($mf.expect_bc_sha256 + "`n" + $mf.expect_obj_sha256 + "`n"))
Remove-Item "$work\inject.log" -ErrorAction SilentlyContinue

# ---- 3. 交换 ----
$logMark=Get-Date
Copy-Item $wrapper "$llvmBin\llc.exe" -Force
$swapped=Get-Sha "$llvmBin\llc.exe"
if($swapped -eq ""){ Fail 44 "swap_hash_unreadable" }
if($swapped -ne $wrapperSha){ Fail 44 ("swap_verify_failed:" + $swapped) }

# ---- 4. 构建（finally 恢复）----
$buildExit=999
try {
  Set-Location "$root\apps\pharos_mark"
  & (Join-Path $sdk 'tools\bin\cjpm.exe') build > (Join-Path $work 'relay-build.log') 2>&1
  $buildExit=$LASTEXITCODE
} finally {
  Copy-Item "$llvmBin\llc-real.exe" "$llvmBin\llc.exe" -Force
  $restored=Get-Sha "$llvmBin\llc.exe"
  Set-Location $env:TEMP
  if($restored -eq ""){ Write-Output "RELAY_FAIL code=42 restore_hash_unreadable"; exit 42 }
  if($restored -ne $ORIG_LLC_SHA){ Write-Output ("RELAY_FAIL code=42 restore_failed:" + $restored); exit 42 }
  Write-Output ("LLC_RESTORED sha=" + $restored)
}
Write-Output ("BUILD_EXIT=" + $buildExit)

# ---- 5. 核验本轮捕获与注入 ----
$cap="$work\build-bc-captured.bc"
if(!(Test-Path $cap)){ Fail 45 "bc_capture_missing" }
$capSha=Get-Sha $cap
Write-Output ("CAPTURED_BC=" + $capSha)
if($capSha -eq ""){ Fail 45 "captured_bc_hash_unreadable" }
if($capSha -ne $mf.expect_bc_sha256){ Fail 45 ("captured_bc_mismatch:" + $capSha) }
$injLines=@()
if(Test-Path "$work\inject.log"){ $injLines=Get-Content "$work\inject.log" }
$injected=$false
foreach($l in $injLines){
  if($l -match ("INJECTED bc=" + $mf.expect_bc_sha256 + " obj=" + $mf.expect_obj_sha256)){ $injected=$true }
}
if(!$injected){ Fail 45 "inject_log_no_matching_line" }
$exe="$root\apps\pharos_mark\target\release\bin\main.exe"
if(!(Test-Path $exe)){ Fail 45 "main_exe_missing" }
$exeSha=Get-Sha $exe
if($exeSha -eq ""){ Fail 45 "exe_hash_unreadable" }
Write-Output ("RELAY_OK bc=" + $capSha + " obj=" + $objSha + " exe=" + $exeSha + " exe_len=" + (Get-Item $exe).Length)
if($buildExit -ne 0){ Fail 46 ("build_exit:" + $buildExit) }
exit 0
