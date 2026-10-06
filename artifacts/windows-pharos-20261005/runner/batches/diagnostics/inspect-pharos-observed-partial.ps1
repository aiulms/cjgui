$ErrorActionPreference='Stop'
$root='C:\cjgui-windows-w1\Pharos Mark Windows Source'
$logRoot=Join-Path $root 'build-logs'
$prefix='pharos-incremental-observed-*'
$files=@(Get-ChildItem -LiteralPath $logRoot -Filter $prefix -File | Sort-Object LastWriteTime -Descending)
$trace=$files|Where-Object {$_.Name -like '*.jsonl'}|Select-Object -First 1
$stdout=$files|Where-Object {$_.Name -like '*.stdout.log'}|Select-Object -First 1
$stderr=$files|Where-Object {$_.Name -like '*.stderr.log'}|Select-Object -First 1
$traceLines=@();$records=@()
if($null -ne $trace){$traceLines=@(Get-Content -LiteralPath $trace.FullName);foreach($line in $traceLines){try{$records+=ConvertFrom-Json -InputObject $line}catch{}}}
$processes=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue|Where-Object {$_.Name -match '^(cjc|cjpm|ld|lld|clang|gcc|cc1|ar|mingw32-make|powershell|cmd)\.exe$'}|Select-Object ProcessId,ParentProcessId,Name,CreationDate,CommandLine)
$uploads=@()
foreach($f in @($trace,$stdout,$stderr)){
  if($null -eq $f){continue}
  try{$name=$f.Name;$body=[System.IO.File]::ReadAllBytes($f.FullName);$uri="$($env:PHAROS_TRANSFER_BASE)/results/pharos-build-observed-partial/$name";$r=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $body;$uploads += [PSCustomObject]@{Name=$name;Status=[int]$r.StatusCode;Bytes=$body.Length;Sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}}
  catch{$uploads += [PSCustomObject]@{Name=$f.Name;Status=0;Error=$_.Exception.Message}}
}
$recent=@($records|Select-Object -Last 10)
[PSCustomObject]@{Files=@($files|ForEach-Object {[PSCustomObject]@{Name=$_.Name;Bytes=$_.Length;LastWriteUtc=$_.LastWriteTimeUtc.ToString('o')}});TraceLineCount=$traceLines.Count;TraceRecords=$recent;Processes=$processes;Uploads=$uploads} | ConvertTo-Json -Depth 9
