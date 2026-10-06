$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
function Invoke-CapturedProcess([string]$file,[string[]]$arguments,[string]$workingDirectory){
  $info=[System.Diagnostics.ProcessStartInfo]::new()
  $info.FileName=$file;$info.WorkingDirectory=$workingDirectory
  $info.UseShellExecute=$false;$info.CreateNoWindow=$true
  $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
  $info.Arguments=($arguments|ForEach-Object {'"'+($_ -replace '"','\"')+'"'}) -join ' '
  $process=[System.Diagnostics.Process]::new();$process.StartInfo=$info
  if(!$process.Start()){throw "process_start_failed:$file"}
  $stdoutTask=$process.StandardOutput.ReadToEndAsync();$stderrTask=$process.StandardError.ReadToEndAsync()
  if(!$process.WaitForExit(60000)){$process.Kill();$process.WaitForExit();throw "process_timeout:$file"}
  return [PSCustomObject]@{Exit=$process.ExitCode;Stdout=$stdoutTask.GetAwaiter().GetResult();Stderr=$stderrTask.GetAwaiter().GetResult()}
}
function Publish([string]$name,[string]$text){
  $path=Join-Path $env:TEMP $name
  [System.IO.File]::WriteAllText($path,$text,[System.Text.UTF8Encoding]::new($false))
  $bytes=[System.IO.File]::ReadAllBytes($path)
  $uri="$($env:PHAROS_TRANSFER_BASE)/results/scene-contract/$name"
  $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri `
    -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
  return [PSCustomObject]@{Name=$name;Bytes=$bytes.Length;Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant();UploadStatus=[int]$response.StatusCode}
}
$root='C:\cjgui-windows-w1\CJGUI Windows Scene Contract'
$archive=Join-Path $env:TEMP 'cjgui-windows-scene-contract.zip'
$expected='bb31c899c9e9e0e32956c4e30d1377d6d1d45ac5af0cb009941eeeaa187d4a40'
$url="$($env:PHAROS_TRANSFER_BASE)/files/$($env:PHAROS_TRANSFER_SESSION)/cjgui-windows-source.zip"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $archive|Out-Null
$archiveHash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if($archiveHash -ne $expected){throw "source_zip_hash_mismatch:$archiveHash"}
if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
[void][System.IO.Directory]::CreateDirectory($root)
Expand-Archive -LiteralPath $archive -DestinationPath $root -Force
$manifest=Get-Content -LiteralPath (Join-Path $root 'source-manifest.json') -Raw|ConvertFrom-Json
$verified=0
foreach($entry in $manifest.files){
  $path=Join-Path $root $entry.destination
  if(!(Test-Path -LiteralPath $path)){throw "source_missing:$($entry.destination)"}
  $actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if($actual -ne $entry.sha256){throw "source_hash_mismatch:$($entry.destination)"}
  $verified++
}
$mingwBin='C:\Users\jiangxuanyang\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin'
$env:PATH=(($mingwBin,$env:PATH)-join ';')
$gcc=Join-Path $mingwBin 'gcc.exe'
if(!(Test-Path -LiteralPath $gcc)){$gcc=(Get-Command 'x86_64-w64-mingw32-gcc.exe' -ErrorAction SilentlyContinue).Source}
if(!$gcc){$gcc=(Get-Command 'gcc.exe' -ErrorAction SilentlyContinue).Source}
if(!$gcc){throw 'windows_x64_gcc_not_found'}
$sourceRoot=Join-Path $root 'runtime\cjgui\platforms\windows\native'
$probe=Join-Path $root 'renderer-contract\cjgui_windows_scene_contract.c'
$exe=Join-Path $root 'renderer-contract\cjgui_windows_scene_contract.exe'
$compile=Invoke-CapturedProcess $gcc @('-std=c11','-O0','-DCJGUI_WINDOWS_SCENE_CONTRACT_TEST','-ffunction-sections','-fdata-sections',
  '-D_WIN32_WINNT=0x0A00','-I',(Join-Path $root 'runtime\cjgui\native'),'-I',$sourceRoot,
  $probe,(Join-Path $sourceRoot 'cjgui_windows_renderer.c'),(Join-Path $sourceRoot 'cjgui_windows_wic.c'),
  '-Wl,--gc-sections','-ld3d11','-ld3dcompiler','-ldxgi','-ldxguid','-ldwrite','-luuid',
  '-luser32','-lgdi32','-limm32','-ladvapi32','-lole32','-lwindowscodecs','-o',$exe) $root
$log="SOURCE_ZIP_SHA256=$archiveHash`nMANIFEST_VERIFIED=$verified/$($manifest.files.Count)`nNATIVE_TARGET=$(& $gcc -dumpmachine)`nCOMPILE_EXIT=$($compile.Exit)`nSTDOUT:`n$($compile.Stdout)`nSTDERR:`n$($compile.Stderr)"
$undefined=@($compile.Stderr -split "`r?`n"|Where-Object {$_ -match 'undefined reference|undefined symbol|unresolved external'})
$logs=@(Publish 'scene-contract-link.log' $log)
if($compile.Exit -eq 0){
  $run=Invoke-CapturedProcess $exe @() $root
  $runLog="RUN_EXIT=$($run.Exit)`nSTDOUT:`n$($run.Stdout)`nSTDERR:`n$($run.Stderr)"
  $logs+=Publish 'scene-contract-check-run.log' $runLog
}
$contractPass=($compile.Exit -eq 0 -and $run.Exit -eq 0 -and
  $run.Stdout -match 'CJGUI_WINDOWS_SCENE_CONTRACT PASS accepted=41 stale_candidate_rejected=1 old_scene_preserved=1')
[PSCustomObject]@{SourceZipSha256=$archiveHash;ManifestFiles=$manifest.files.Count;VerifiedFiles=$verified;
  NativeTarget=$(& $gcc -dumpmachine);CompileExit=$compile.Exit;UndefinedSymbols=$undefined;
  ContractPass=$contractPass;Logs=$logs}|ConvertTo-Json -Depth 5
if($contractPass){exit 0}
exit 1
