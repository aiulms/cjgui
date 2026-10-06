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

$sessionDir=Join-Path $env:TEMP ("pharos-renderer-targeted-"+[guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($sessionDir)
$exitCode=1
try {
  $expected='b66ee7fafc35d3d56917cb94f9dcb72f71e7c42df0fb72eff7be0e379dda2b5e'
  $archive=Join-Path $sessionDir 'cjgui-windows-source.zip'
  $url="$($env:PHAROS_TRANSFER_BASE)/files/$($env:PHAROS_TRANSFER_SESSION)/cjgui-windows-source.zip"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $archive|Out-Null
  $archiveHash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if($archiveHash -ne $expected){throw "source_zip_hash_mismatch:$archiveHash"}

  $root=Join-Path $sessionDir 'source'
  [void][System.IO.Directory]::CreateDirectory($root)
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

  $native=Join-Path $root 'runtime\cjgui\platforms\windows\native'
  $rendererObject=Join-Path $sessionDir 'cjgui_windows_renderer.o'
  $wicObject=Join-Path $sessionDir 'cjgui_windows_wic.o'
  $includeRuntime=Join-Path $root 'runtime\cjgui\native'
  $rendererCompile=Invoke-CapturedProcess $gcc @('-std=c11','-O0','-ffunction-sections','-fdata-sections',
    '-DCJGUI_WINDOWS_SCENE_CONTRACT_TEST','-D_WIN32_WINNT=0x0A00','-I',$includeRuntime,'-I',$native,
    '-c',(Join-Path $native 'cjgui_windows_renderer.c'),'-o',$rendererObject) $root
  $wicCompile=Invoke-CapturedProcess $gcc @('-std=c11','-O0','-ffunction-sections','-fdata-sections',
    '-D_WIN32_WINNT=0x0A00','-I',$includeRuntime,'-I',$native,
    '-c',(Join-Path $native 'cjgui_windows_wic.c'),'-o',$wicObject) $root

  $contractSpecs=@(
    [PSCustomObject]@{Name='scene';Source='renderer-contract\cjgui_windows_scene_contract.c';Expected='CJGUI_WINDOWS_SCENE_CONTRACT PASS accepted=42 stale_candidate_rejected=1 renderer_boundaries=styled_runs,labeled_input old_scene_preserved=1'},
    [PSCustomObject]@{Name='geometry-budget-flight';Source='renderer-contract\cjgui_windows_geometry_budget_contract.c';Expected='CJGUI_WINDOWS_GEOMETRY_BUDGET_CONTRACT PASS dpi=96,144 hit,caret,selection=same_accepted_layout multi_node_budget=reject_old_accepted=preserved candidate_cancel=zero_delta gpu_flights=held,reaped window_close=zero_live_textures'},
    [PSCustomObject]@{Name='input-coordinate-lifetime';Source='renderer-contract\cjgui_windows_input_contract.c';Expected='WINDOWS_INPUT_CONTRACT PASS events=2 inserts=A,B ranges=4:4,5:5 label_value_click=1 drag=1:3 body_shared_pointer=begin,update,end coordinate_lifetime=accepted,stale_refused utf16=true binding=9'}
  )
  $contractResults=@()
  $overallOk=$rendererCompile.Exit -eq 0 -and $wicCompile.Exit -eq 0
  foreach($spec in $contractSpecs){
    $exe=Join-Path $sessionDir ($spec.Name+'.exe')
    $link=if($overallOk){Invoke-CapturedProcess $gcc @('-std=c11','-O0','-ffunction-sections','-fdata-sections',
      '-D_WIN32_WINNT=0x0A00','-I',$includeRuntime,'-I',$native,
      (Join-Path $root $spec.Source),$rendererObject,$wicObject,'-Wl,--gc-sections',
      '-ld3d11','-ld3dcompiler','-ldxgi','-ldxguid','-ldwrite','-luuid','-luser32','-lgdi32',
      '-limm32','-ladvapi32','-lole32','-lwindowscodecs','-o',$exe) $root}
      else {[PSCustomObject]@{Exit=1;Stdout='renderer_or_wic_compile_failed';Stderr=''}}
    $run=if($link.Exit -eq 0){Invoke-CapturedProcess $exe @() $root}
      else {[PSCustomObject]@{Exit=1;Stdout='link_failed';Stderr=''}}
    $passed=$link.Exit -eq 0 -and $run.Exit -eq 0 -and $run.Stdout.Contains($spec.Expected)
    if(!$passed){$overallOk=$false}
    $contractResults+=([PSCustomObject]@{Name=$spec.Name;LinkExit=$link.Exit;RunExit=$run.Exit;
      Passed=$passed;Expected=$spec.Expected;Stdout=$run.Stdout;Stderr=$run.Stderr})
    foreach($kind in @('link','run')){
      $result=if($kind -eq 'link'){$link}else{$run}
      $logPath=Join-Path $sessionDir ($spec.Name+'-'+$kind+'.log')
      $log="KIND=$kind`nEXIT=$($result.Exit)`nSTDOUT:`n$($result.Stdout)`nSTDERR:`n$($result.Stderr)"
      [System.IO.File]::WriteAllText($logPath,$log,[System.Text.UTF8Encoding]::new($false))
      $bytes=[System.IO.File]::ReadAllBytes($logPath)
      $uri="$($env:PHAROS_TRANSFER_BASE)/results/renderer-targeted/$([uri]::EscapeDataString([System.IO.Path]::GetFileName($logPath)))"
      $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri `
        -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
      $contractResults[-1] | Add-Member -NotePropertyName ($kind+'UploadStatus') -NotePropertyValue ([int]$response.StatusCode) -Force
      $contractResults[-1] | Add-Member -NotePropertyName ($kind+'LogSha256') -NotePropertyValue ((Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash.ToLowerInvariant()) -Force
    }
  }

  $compileLogs=@()
  foreach($name in @('renderer','wic')){
    $result=if($name -eq 'renderer'){$rendererCompile}else{$wicCompile}
    $logPath=Join-Path $sessionDir ($name+'-compile.log')
    $log="KIND=compile-$name`nEXIT=$($result.Exit)`nNATIVE_TARGET=$(& $gcc -dumpmachine)`nSTDOUT:`n$($result.Stdout)`nSTDERR:`n$($result.Stderr)"
    [System.IO.File]::WriteAllText($logPath,$log,[System.Text.UTF8Encoding]::new($false))
    $bytes=[System.IO.File]::ReadAllBytes($logPath)
    $uri="$($env:PHAROS_TRANSFER_BASE)/results/renderer-targeted/$([uri]::EscapeDataString([System.IO.Path]::GetFileName($logPath)))"
    $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri `
      -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
    $compileLogs+=([PSCustomObject]@{Name=$name;Exit=$result.Exit;Sha256=(Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash.ToLowerInvariant();UploadStatus=[int]$response.StatusCode})
  }
  $exitCode=if($overallOk){0}else{1}
  [PSCustomObject]@{SourceZipSha256=$archiveHash;ManifestFiles=$manifest.files.Count;VerifiedFiles=$verified;
    NativeTarget=$(& $gcc -dumpmachine);RendererCompileExit=$rendererCompile.Exit;WicCompileExit=$wicCompile.Exit;
    ContractResults=$contractResults;CompileLogs=$compileLogs;OverallPass=$overallOk}|ConvertTo-Json -Depth 7
}
finally {
  if(Test-Path -LiteralPath $sessionDir){Remove-Item -LiteralPath $sessionDir -Recurse -Force}
}
exit $exitCode
