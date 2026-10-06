$ErrorActionPreference='Stop'
$root='C:\cjgui-windows-w1\Pharos Mark Windows Source'
$appTarget=Join-Path $root 'apps\pharos_mark\target\release'
$errDir=Join-Path $appTarget '.build-logs\pharos_mark'
$logs=@()
if(Test-Path -LiteralPath $errDir){
  foreach($f in (Get-ChildItem -LiteralPath $errDir -File | Sort-Object LastWriteTime -Descending | Select-Object -First 4)){
    $logs += [PSCustomObject]@{Name=$f.Name;Bytes=$f.Length;Sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant();Tail=(Get-Content -LiteralPath $f.FullName -Tail 80 | Out-String)}
  }
}
$files=@(Get-ChildItem -LiteralPath $appTarget -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 20 | ForEach-Object {"$($_.LastWriteTime.ToUniversalTime().ToString('o')) $($_.Length) $($_.FullName.Substring($root.Length+1))"})
$processes=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(cjc|cjpm|ld|clang|gcc|cc1|ar|mingw32-make)$'} | Select-Object ProcessName,Id,CPU)
[PSCustomObject]@{ErrorLogs=$logs;LatestAppFiles=$files;Processes=$processes} | ConvertTo-Json -Depth 5
