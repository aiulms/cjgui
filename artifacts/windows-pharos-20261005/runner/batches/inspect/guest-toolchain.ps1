$roots = @('C:\cjgui-windows-w0\sdk\cangjie','C:\cjgui-windows-w1','C:\cjgui-windows-w0')
$commands = @()
foreach ($name in @('cjc.exe','cjpm.exe','mingw32-make.exe','x86_64-w64-mingw32-gcc.exe','gcc.exe')) {
    $found = Get-Command $name -ErrorAction SilentlyContinue
    if ($found) { $commands += [PSCustomObject]@{ Name=$name; Path=$found.Source } }
}
$files = foreach ($root in $roots) {
    if (Test-Path -LiteralPath $root) { [PSCustomObject]@{ Path=$root; Exists=$true; Entries=@(Get-ChildItem -LiteralPath $root -Force | Select-Object -First 30 -ExpandProperty Name) } }
    else { [PSCustomObject]@{ Path=$root; Exists=$false; Entries=@() } }
}
$versions = @()
foreach ($item in $commands | Where-Object { $_.Name -in @('cjc.exe','cjpm.exe') }) {
    $exe = $item.Path
    $output = & $exe --version 2>&1 | Out-String
    $versions += [PSCustomObject]@{ Path=$exe; ExitCode=$LASTEXITCODE; Version=$output.Trim() }
}
[PSCustomObject]@{ CapturedUtc=[DateTime]::UtcNow.ToString('o'); Commands=$commands; Roots=$files; Versions=$versions } | ConvertTo-Json -Depth 7
