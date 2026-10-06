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
  $path=Join-Path $sessionRoot $name
  [System.IO.File]::WriteAllText($path,$text,[System.Text.UTF8Encoding]::new($false))
  $bytes=[System.IO.File]::ReadAllBytes($path)
  $uri="$($env:PHAROS_TRANSFER_BASE)/results/input-contract/$name"
  $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri `
    -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
  return [PSCustomObject]@{Name=$name;Bytes=$bytes.Length;Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant();UploadStatus=[int]$response.StatusCode}
}
$sessionRoot=Join-Path $env:TEMP ("cjgui-windows-input-contract-"+[guid]::NewGuid().ToString('N'))
$root=Join-Path $sessionRoot 'source'
$archive=Join-Path $sessionRoot 'cjgui-windows-source.zip'
$expected='3842705a40ad655d6bce9644fe1c05c4d8230b09fbf70408cf6a60961bd0aa53'
New-Item -ItemType Directory -Path $root -Force|Out-Null
$url="$($env:PHAROS_TRANSFER_BASE)/files/$($env:PHAROS_TRANSFER_SESSION)/cjgui-windows-source.zip"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $archive|Out-Null
$archiveHash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if($archiveHash -ne $expected){throw "source_zip_hash_mismatch:$archiveHash"}
Expand-Archive -LiteralPath $archive -DestinationPath $root -Force
$manifest=Get-Content -LiteralPath (Join-Path $root 'source-manifest.json') -Raw|ConvertFrom-Json
$verified=0
foreach($entry in $manifest.files){
  $path=Join-Path $root $entry.destination
  if(!(Test-Path -LiteralPath $path)){throw "source_missing:$($entry.destination)"}
  $actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if($actual -ne $entry.sha256){throw "source_hash_mismatch:$($entry.destination):$actual"}
  $verified++
}
$mingwBin='C:\Users\jiangxuanyang\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin'
$env:PATH=(($mingwBin,$env:PATH)-join ';')
$gcc=Join-Path $mingwBin 'gcc.exe'
if(!(Test-Path -LiteralPath $gcc)){$gcc=(Get-Command 'x86_64-w64-mingw32-gcc.exe' -ErrorAction SilentlyContinue).Source}
if(!$gcc){$gcc=(Get-Command 'gcc.exe' -ErrorAction SilentlyContinue).Source}
if(!$gcc){throw 'windows_x64_gcc_not_found'}
$sourceRoot=Join-Path $root 'runtime\cjgui\platforms\windows\native'
$probe=Join-Path $root 'renderer-contract\cjgui_windows_input_contract.c'
$exe=Join-Path $root 'renderer-contract\cjgui_windows_input_contract.exe'
$compile=Invoke-CapturedProcess $gcc @('-std=c11','-O0','-ffunction-sections','-fdata-sections',
  '-DCJGUI_WINDOWS_SCENE_CONTRACT_TEST','-D_WIN32_WINNT=0x0A00','-I',(Join-Path $root 'runtime\cjgui\native'),'-I',$sourceRoot,
  $probe,(Join-Path $sourceRoot 'cjgui_windows_renderer.c'),(Join-Path $sourceRoot 'cjgui_windows_wic.c'),
  '-Wl,--gc-sections','-ld3d11','-ld3dcompiler','-ldxgi','-ldxguid','-ldwrite','-luuid',
  '-luser32','-lgdi32','-limm32','-ladvapi32','-lole32','-lwindowscodecs','-o',$exe) $root
$compileLog="SOURCE_ZIP_SHA256=$archiveHash`nMANIFEST_VERIFIED=$verified/$($manifest.files.Count)`nNATIVE_TARGET=$(& $gcc -dumpmachine)`nCOMPILE_EXIT=$($compile.Exit)`nSTDOUT:`n$($compile.Stdout)`nSTDERR:`n$($compile.Stderr)"
$logs=@(Publish 'windows-input-contract-link.log' $compileLog)
if($compile.Exit -ne 0){[PSCustomObject]@{CompileExit=$compile.Exit;Logs=$logs}|ConvertTo-Json -Depth 5;exit 1}
$run=Invoke-CapturedProcess $exe @() $root
$runLog="RUN_EXIT=$($run.Exit)`nSTDOUT:`n$($run.Stdout)`nSTDERR:`n$($run.Stderr)"
$logs+=Publish 'windows-input-contract-run.log' $runLog
[PSCustomObject]@{SourceZipSha256=$archiveHash;ManifestFiles=$manifest.files.Count;VerifiedFiles=$verified;
  NativeTarget=$(& $gcc -dumpmachine);CompileExit=$compile.Exit;RunExit=$run.Exit;
  Stdout=$run.Stdout.Trim();Stderr=$run.Stderr.Trim();Logs=$logs}|ConvertTo-Json -Depth 5
exit $run.Exit
