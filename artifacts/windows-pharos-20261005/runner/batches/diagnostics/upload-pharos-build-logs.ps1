$ErrorActionPreference='Stop'
$root='C:\cjgui-windows-w1\Pharos Mark Windows Source'
$logRoot=Join-Path $root 'build-logs'
$names=@('shared_operation_core','cjgui','document_core','markdown_engine','app_services','editor_surface','pharos_mark_windows','pharos_mark')
$results=New-Object System.Collections.Generic.List[object]
foreach($name in $names){
  $path=Join-Path $logRoot ($name+'.log')
  if(!(Test-Path -LiteralPath $path)){continue}
  $bytes=[System.IO.File]::ReadAllBytes($path)
  $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  $uri="$($env:PHAROS_TRANSFER_BASE)/results/build-logs/$name.log"
  $response=Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes
  $results.Add([PSCustomObject]@{Name=$name;Bytes=$bytes.Length;Sha256=$sha;UploadStatus=[int]$response.StatusCode})
}
@($results.ToArray()) | ConvertTo-Json -Depth 4
