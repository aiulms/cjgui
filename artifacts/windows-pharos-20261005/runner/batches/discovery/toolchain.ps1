$sdk = 'C:\cjgui-windows-w0\sdk\cangjie'
$bin = Join-Path $sdk 'bin'
$cjc = Join-Path $bin 'cjc.exe'
$cjpm = Join-Path $sdk 'tools\bin\cjpm.exe'
$rows = @()
foreach ($exe in @($cjc, $cjpm)) {
    if (-not (Test-Path -LiteralPath $exe)) { $rows += [PSCustomObject]@{ Path=$exe; Exists=$false; Version=''; ExitCode=-1 }; continue }
    $version = & $exe -v 2>&1 | Out-String
    $versionCode = $LASTEXITCODE
    $rows += [PSCustomObject]@{ Path=$exe; Exists=$true; Version=$version.Trim(); ExitCode=$versionCode }
}
$targetDirs = @('x86_64-w64-mingw32','mingw64','lib','modules','third_party') | ForEach-Object { $p=Join-Path $sdk $_; [PSCustomObject]@{ Path=$p; Exists=(Test-Path -LiteralPath $p); Names=if (Test-Path -LiteralPath $p) {@(Get-ChildItem -LiteralPath $p -Force | Select-Object -First 25 -ExpandProperty Name)} else {@()} } }
[PSCustomObject]@{ Sdk=$sdk; Versions=$rows; Dirs=$targetDirs; Path=$env:PATH; ProcessArchitecture=if ([IntPtr]::Size -eq 8) {'x64'} else {'x86'}; OSArchitecture=(Get-CimInstance Win32_OperatingSystem).OSArchitecture } | ConvertTo-Json -Depth 8
