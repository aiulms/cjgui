$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$sdk=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$root='C:\cjgui-windows-w1\CJGUI Windows Source'
$probe=Join-Path $root 'window-link-probe'
$cjpm=Join-Path $sdk 'tools\bin\cjpm.exe'
$dllDirs=@(Get-ChildItem -LiteralPath $sdk -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {Split-Path -Parent $_.FullName} | Sort-Object -Unique)
$env:PATH=(($dllDirs+@((Join-Path $sdk 'tools\bin'),(Join-Path $sdk 'bin'))+@($env:PATH))-join ';')
$env:CANGJIE_HOME=$sdk
$prior=$ErrorActionPreference;$ErrorActionPreference='Continue'
Push-Location $probe
try{$output=& $cjpm build 2>&1|Out-String;$exit=$LASTEXITCODE}
finally{Pop-Location;$ErrorActionPreference=$prior}
$logPath=Join-Path $env:TEMP 'cjgui-windows-link-probe.log'
[System.IO.File]::WriteAllText($logPath,$output,[System.Text.UTF8Encoding]::new($false))
$body=[System.IO.File]::ReadAllBytes($logPath)
$uri="$($env:PHAROS_TRANSFER_BASE)/results/cjgui-abi/cjgui-windows-link-probe.log"
$response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $body
$errors=@($output -split "`r?`n" | Where-Object {$_ -match 'undefined symbol|undefined reference|unresolved external|ld\.lld: error|linking failed|build success'})
[PSCustomObject]@{Exit=$exit;LogBytes=$body.Length;LogSha256=(Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash.ToLowerInvariant();UploadStatus=[int]$response.StatusCode;DiagnosticLines=$errors}|ConvertTo-Json -Depth 4
exit $exit
