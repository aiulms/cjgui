$sdk = 'C:\cjgui-windows-w0\sdk\cangjie'
$cjpm = Join-Path $sdk 'tools\bin\cjpm.exe'
$objdump = (Get-Command objdump.exe -ErrorAction Stop).Source
$imports = @(& $objdump -p $cjpm 2>&1 | Select-String 'DLL Name:' | ForEach-Object { $_.Line.Trim() })
$dlls = @(Get-ChildItem -LiteralPath $sdk -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
$dirs = @($dlls | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique)
$before = $env:PATH
$env:PATH = (($dirs + @((Get-Command objdump.exe).Source | Split-Path -Parent) + @((Join-Path $sdk 'tools\bin'),(Join-Path $sdk 'bin')) + @('C:\Users\jiangxuanyang\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin') + @($before)) -join ';')
$missing = @()
foreach ($line in $imports) { $dll = ($line -replace '^DLL Name:\s*',''); if (-not (Get-Command $dll -ErrorAction SilentlyContinue)) { $missing += $dll } }
$help = & $cjpm --help 2>&1 | Out-String
$exit = $LASTEXITCODE
[PSCustomObject]@{ Cjpm=$cjpm; Imports=$imports; SdkDlls=$dlls; AddedPath=$dirs; MissingByCommandLookup=$missing; LaunchExit=$exit; Help=$help.Trim() } | ConvertTo-Json -Depth 8
