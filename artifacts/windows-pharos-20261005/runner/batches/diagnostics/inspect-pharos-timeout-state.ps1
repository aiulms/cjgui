$ErrorActionPreference='Stop'
$root='C:\cjgui-windows-w1\Pharos Mark Windows Source'
$targets=@(
  'runtime\cjgui\target\release',
  'runtime\cjgui\shared_operation_core\target\release',
  'packages\document_core\target\release',
  'packages\markdown_engine\target\release',
  'packages\app_services\target\release',
  'packages\editor_surface\target\release',
  'apps\pharos_mark\target\release'
)
$targetStates=New-Object System.Collections.Generic.List[object]
foreach($relative in $targets){
  $path=Join-Path $root $relative
  if(!(Test-Path -LiteralPath $path)){$targetStates.Add([PSCustomObject]@{Path=$relative;Exists=$false;Files=0;Bytes=0;Latest='';Recent=@()});continue}
  $files=@(Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue)
  $recent=@($files | Sort-Object LastWriteTime -Descending | Select-Object -First 8 | ForEach-Object {"$($_.LastWriteTime.ToUniversalTime().ToString('o')) $($_.Length) $($_.FullName.Substring($root.Length+1))"})
  $latest='';if($files.Count -gt 0){$latest=($files|Measure-Object LastWriteTime -Maximum).Maximum.ToUniversalTime().ToString('o')}
  $targetStates.Add([PSCustomObject]@{Path=$relative;Exists=$true;Files=$files.Count;Bytes=[long](($files|Measure-Object Length -Sum).Sum);Latest=$latest;Recent=$recent})
}
$processes=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(cjc|cjpm|ld|clang|gcc|cc1|ar|mingw32-make)$'} | Select-Object ProcessName,Id,StartTime,CPU)
$logRoot=Join-Path $root 'build-logs'
$logs=@();if(Test-Path -LiteralPath $logRoot){$logs=@(Get-ChildItem -LiteralPath $logRoot -File | Sort-Object LastWriteTime -Descending | Select-Object -First 12 | ForEach-Object {[PSCustomObject]@{Name=$_.Name;Bytes=$_.Length;LastWriteUtc=$_.LastWriteTime.ToUniversalTime().ToString('o');Sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}})}
$manifestPath=Join-Path $root 'source-manifest.json';$manifestSha='';$manifestCount=0;if(Test-Path -LiteralPath $manifestPath){$manifestSha=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant();$m=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json;$manifestCount=$m.files.Count}
$exe=Join-Path $root 'apps\pharos_mark\target\release\bin\main.exe'
[PSCustomObject]@{CangjieHome=$env:CANGJIE_HOME;RootExists=(Test-Path -LiteralPath $root);ManifestFiles=$manifestCount;ManifestSha256=$manifestSha;BuildProcesses=$processes;Targets=@($targetStates.ToArray());ExistingBuildLogs=$logs;AppExeExists=(Test-Path -LiteralPath $exe);IncomingSourceExists=(Test-Path -LiteralPath (Join-Path $root 'incoming-current-source'))} | ConvertTo-Json -Depth 6
