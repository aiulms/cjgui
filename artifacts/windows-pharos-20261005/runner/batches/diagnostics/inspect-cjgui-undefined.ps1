$ErrorActionPreference='Stop'
$sdk=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$package='C:\cjgui-windows-w1\CJGUI Windows Source\runtime\cjgui'
$archive=Join-Path $package 'target\release\cjgui\libcjgui.a'
if(!(Test-Path -LiteralPath $archive)){throw "cjgui_archive_missing:$archive"}
$llvm=Join-Path $sdk 'third_party\llvm\bin\llvm-nm.exe'
if(!(Test-Path -LiteralPath $llvm)){
  $cmd=Get-Command nm.exe -ErrorAction SilentlyContinue
  if($cmd){$llvm=$cmd.Source}
}
if(!(Test-Path -LiteralPath $llvm)){
  $candidates=@(Get-ChildItem -LiteralPath (Join-Path $sdk 'third_party\llvm\bin') -File -ErrorAction SilentlyContinue | Where-Object {$_.Name -match 'nm|objdump|readobj|ar'} | Select-Object -ExpandProperty Name)
  throw "symbol_tool_missing: candidates=$($candidates -join ',') PATH=$env:PATH"
}
$raw=& $llvm --undefined-only --extern-only $archive 2>&1 | Out-String
$nmExit=$LASTEXITCODE
$matches=[regex]::Matches($raw,'\bcjgui_internal_renderer_[A-Za-z0-9_]+\b')
$symbols=@($matches | ForEach-Object {$_.Value} | Sort-Object -Unique)
$rawPath=Join-Path $env:TEMP 'cjgui-windows-undefined-nm.txt'
$jsonPath=Join-Path $env:TEMP 'cjgui-windows-undefined.json'
[System.IO.File]::WriteAllText($rawPath,$raw,[System.Text.UTF8Encoding]::new($false))
$report=[PSCustomObject]@{
  Archive=$archive
  ArchiveBytes=(Get-Item -LiteralPath $archive).Length
  ArchiveSha256=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
  NmPath=$llvm
  NmExit=$nmExit
  UndefinedRendererSymbolCount=$symbols.Count
  UndefinedRendererSymbols=$symbols
  RawPath=$rawPath
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPath -Encoding utf8
$uploads=@()
foreach($file in @($rawPath,$jsonPath)){
  $name=Split-Path -Leaf $file
  $body=[System.IO.File]::ReadAllBytes($file)
  $uri="$($env:PHAROS_TRANSFER_BASE)/results/cjgui-abi/$name"
  $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $body
  $uploads += [PSCustomObject]@{Name=$name;Status=[int]$response.StatusCode;Bytes=$body.Length;Sha256=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()}
}
[PSCustomObject]@{ArchiveSha256=$report.ArchiveSha256;NmExit=$nmExit;UndefinedRendererSymbolCount=$symbols.Count;UndefinedRendererSymbols=$symbols;Uploads=$uploads} | ConvertTo-Json -Depth 5
if($nmExit -ne 0){exit $nmExit}
