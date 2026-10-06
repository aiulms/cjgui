$base = $env:PHAROS_TRANSFER_BASE
$sid = $env:PHAROS_TRANSFER_SESSION
$source = "$base/files/$sid/transfer-probe.txt"
$destination = 'C:\cjgui-windows-w1\transfer-probe.txt'
Invoke-WebRequest -UseBasicParsing -Uri $source -OutFile $destination | Out-Null
$sha = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
$expected = '861168894e3c1d8da0918227f35a67640a49e9398e732197712d6ab79b039b82'
if ($sha -ne $expected) { throw ("download_hash_mismatch:" + $sha) }
$upload = Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$base/results/$sid/transfer/transfer-probe.txt" -Headers @{ 'X-Pharos-Session'=$sid } -InFile $destination
Write-Output ("TRANSFER_OK sha256=" + $sha + " result=" + $upload.Content)
