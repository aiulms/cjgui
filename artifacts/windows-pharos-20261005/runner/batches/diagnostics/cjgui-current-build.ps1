$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
function Invoke-Captured([string]$file,[string[]]$arguments,[string]$cwd){
  $info=[System.Diagnostics.ProcessStartInfo]::new()
  $info.FileName=$file;$info.WorkingDirectory=$cwd
  $info.UseShellExecute=$false;$info.CreateNoWindow=$true
  $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
  $info.Arguments=($arguments|ForEach-Object {'"'+($_ -replace '"','\"')+'"'}) -join ' '
  $process=[System.Diagnostics.Process]::new();$process.StartInfo=$info
  if(!$process.Start()){throw "process_start_failed:$file"}
  $stdoutTask=$process.StandardOutput.ReadToEndAsync();$stderrTask=$process.StandardError.ReadToEndAsync()
  if(!$process.WaitForExit(900000)){$process.Kill();$process.WaitForExit();throw "process_timeout:$file"}
  $stdout=$stdoutTask.GetAwaiter().GetResult();$stderr=$stderrTask.GetAwaiter().GetResult()
  return [PSCustomObject]@{File=$file;Arguments=$arguments;Exit=$process.ExitCode;Output=("STDOUT:`n$stdout`nSTDERR:`n$stderr")}
}
function Publish([string]$name,[string]$text){
  $path=Join-Path $env:TEMP $name
  [System.IO.File]::WriteAllText($path,$text,[System.Text.UTF8Encoding]::new($false))
  $bytes=[System.IO.File]::ReadAllBytes($path)
  $uri="$($env:PHAROS_TRANSFER_BASE)/results/cjgui-current-build/$name"
  $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri `
    -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
  return [PSCustomObject]@{Name=$name;Bytes=$bytes.Length;Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant();UploadStatus=[int]$response.StatusCode}
}
$root='C:\cjgui-windows-w1\CJGUI Windows Source'
$archive=Join-Path $env:TEMP 'cjgui-windows-current-source.zip'
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
$sdk=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$env:CANGJIE_HOME=$sdk
$dllDirs=@(Get-ChildItem -LiteralPath $sdk -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {Split-Path -Parent $_.FullName} | Sort-Object -Unique)
$mingwBin='C:\Users\jiangxuanyang\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin'
$env:PATH=(($dllDirs+@($mingwBin,(Join-Path $sdk 'tools\bin'),(Join-Path $sdk 'bin'))+@($env:PATH))-join ';')
$gcc=Join-Path $mingwBin 'gcc.exe'
if(!(Test-Path -LiteralPath $gcc)){$gcc=(Get-Command 'x86_64-w64-mingw32-gcc.exe' -ErrorAction SilentlyContinue).Source}
if(!$gcc){$gcc=(Get-Command 'gcc.exe' -ErrorAction SilentlyContinue).Source}
$ar=Join-Path $mingwBin 'ar.exe'
if(!(Test-Path -LiteralPath $ar)){$ar=(Get-Command 'x86_64-w64-mingw32-ar.exe' -ErrorAction SilentlyContinue).Source}
if(!$ar){$ar=(Get-Command 'ar.exe' -ErrorAction SilentlyContinue).Source}
if(!$gcc -or !$ar){throw 'windows_x64_gcc_or_ar_not_found'}
$runtime=Join-Path $root 'runtime\cjgui'
$native=Join-Path $runtime 'platforms\windows\native'
$lib=Join-Path $runtime 'native\lib'
[void][System.IO.Directory]::CreateDirectory($lib)
$rendererObject=Join-Path $lib 'cjgui_windows_renderer.o'
$wicObject=Join-Path $lib 'cjgui_windows_wic.o'
$archiveLib=Join-Path $lib 'libcjgui_internal_renderer.a'
foreach($path in @($rendererObject,$wicObject,$archiveLib)){if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Force}}
$logs=@()
$logs+=Invoke-Captured $gcc @('-std=c11','-O0','-D_WIN32_WINNT=0x0A00','-I',(Join-Path $runtime 'native'),'-I',$native,'-c',(Join-Path $native 'cjgui_windows_renderer.c'),'-o',$rendererObject) $root
$rendererCompile=$logs[-1]
$logs+=Invoke-Captured $gcc @('-std=c11','-O0','-D_WIN32_WINNT=0x0A00','-I',(Join-Path $runtime 'native'),'-I',$native,'-c',(Join-Path $native 'cjgui_windows_wic.c'),'-o',$wicObject) $root
$wicCompile=$logs[-1]
$archiveExit=-1
if($rendererCompile.Exit -eq 0 -and $wicCompile.Exit -eq 0){
  $logs+=Invoke-Captured $ar @('rcs',$archiveLib,$rendererObject,$wicObject) $root
  $archiveExit=$logs[-1].Exit
}else{
  $logs+=([PSCustomObject]@{File='ar.exe';Arguments=@('rcs',$archiveLib,$rendererObject,$wicObject);Exit=-1;Output='SKIPPED: native object compilation failed'})
}
$buildManifest=Get-Content -LiteralPath (Join-Path $runtime 'cjpm.toml') -Raw
$logs+=Invoke-Captured (Join-Path $sdk 'tools\bin\cjpm.exe') @('build','--skip-script') $runtime
$frameworkBuild=$logs[-1]
$linkRoot=Join-Path $root 'window-link-probe'
$logs+=Invoke-Captured (Join-Path $sdk 'tools\bin\cjpm.exe') @('build','--skip-script') $linkRoot
$linkBuild=$logs[-1]
$allOutput=($logs|ForEach-Object {"COMMAND=$($_.File) $($($_.Arguments)-join ' ')`nEXIT=$($_.Exit)`n$($_.Output)"}) -join "`n--- COMMAND ---`n"
$uploads=@(Publish 'cjgui-current-build.log' $allOutput)
$symbols=@([regex]::Matches($linkBuild.Output,'ld\.lld: error: undefined symbol: ([^\r\n]+)')|ForEach-Object {$_.Groups[1].Value}|Sort-Object -Unique)
$ok=($rendererCompile.Exit -eq 0 -and $wicCompile.Exit -eq 0 -and $archiveExit -eq 0 -and
  $frameworkBuild.Exit -eq 0 -and $linkBuild.Exit -eq 0)
[PSCustomObject]@{SourceZipSha256=$archiveHash;ManifestFiles=$manifest.files.Count;VerifiedFiles=$verified;
  NativeTarget=$(& $gcc -dumpmachine);RendererCompileExit=$rendererCompile.Exit;WicCompileExit=$wicCompile.Exit;NativeArchiveExit=$archiveExit;
  NativeArchiveBytes=if(Test-Path -LiteralPath $archiveLib){(Get-Item $archiveLib).Length}else{0};NativeArchiveSha256=if(Test-Path -LiteralPath $archiveLib){(Get-FileHash $archiveLib -Algorithm SHA256).Hash.ToLowerInvariant()}else{''};
  FrameworkBuildExit=$frameworkBuild.Exit;LinkProbeExit=$linkBuild.Exit;UndefinedSymbols=$symbols;
  BuildPass=$ok;Logs=$uploads}|ConvertTo-Json -Depth 5
if($ok){exit 0}
exit 1
