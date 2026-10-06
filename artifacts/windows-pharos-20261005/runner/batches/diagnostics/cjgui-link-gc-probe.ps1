$ErrorActionPreference='Stop'
$sdk=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$root='C:\cjgui-windows-w1\CJGUI Windows Source'
$probe=Join-Path $root 'window-link-probe'
$toml=Join-Path $probe 'cjpm.toml'
$original=[System.IO.File]::ReadAllText($toml)
$patched=$original -replace '(?m)^output-type = "executable"$', "output-type = `"executable`"`nlink-option = `"--gc-sections`""
if($patched -eq $original){throw 'probe_manifest_patch_failed'}
[System.IO.File]::WriteAllText($toml,$patched,[System.Text.UTF8Encoding]::new($false))
$env:CANGJIE_HOME=$sdk
$dllDirs=@(Get-ChildItem -LiteralPath $sdk -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {Split-Path -Parent $_.FullName} | Sort-Object -Unique)
$env:PATH=(($dllDirs+@((Join-Path $sdk 'tools\bin'),(Join-Path $sdk 'bin'))+@($env:PATH))-join ';')
$logPath=Join-Path $env:TEMP 'cjgui-link-gc-build.log'
Push-Location $probe
try{
  $prior=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $PSNativeCommandUseErrorActionPreference=$false
  try{$output=& (Join-Path $sdk 'tools\bin\cjpm.exe') build 2>&1 | Out-String;$exit=$LASTEXITCODE}
  finally{$ErrorActionPreference=$prior}
}
finally{Pop-Location;[System.IO.File]::WriteAllText($toml,$original,[System.Text.UTF8Encoding]::new($false))}
[System.IO.File]::WriteAllText($logPath,$output,[System.Text.UTF8Encoding]::new($false))
$undefined=@([regex]::Matches($output,'ld\.lld: error: undefined symbol: ([^\r\n]+)') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Unique)
$uploads=@()
$body=[System.IO.File]::ReadAllBytes($logPath)
$uri="$($env:PHAROS_TRANSFER_BASE)/results/cjgui-abi/cjgui-link-gc-build.log"
$response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $body
$uploads += [PSCustomObject]@{Name='cjgui-link-gc-build.log';Status=[int]$response.StatusCode;Bytes=$body.Length;Sha256=(Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash.ToLowerInvariant()}
[PSCustomObject]@{Exit=$exit;UndefinedCount=$undefined.Count;UndefinedSymbols=$undefined;LogBytes=$body.Length;Uploads=$uploads;OutputTail=($output -split "`r?`n" | Select-Object -Last 18)} | ConvertTo-Json -Depth 4
exit $exit
