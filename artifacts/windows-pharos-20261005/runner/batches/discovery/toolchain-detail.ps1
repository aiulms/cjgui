$sdk = 'C:\cjgui-windows-w0\sdk\cangjie'
$roots = @($sdk, 'C:\cjgui-windows-w0', 'C:\Users\jiangxuanyang\.cangjie', 'C:\Users\jiangxuanyang\AppData\Local\Programs\Cangjie')
$bins = @(Get-ChildItem -LiteralPath (Join-Path $sdk 'bin') -Force | Select-Object Name,FullName,Length)
$matches = @()
foreach ($root in $roots) {
    if (Test-Path -LiteralPath $root) {
        $matches += Get-ChildItem -LiteralPath $root -Filter 'cjpm.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10 FullName,Length
    }
}
[PSCustomObject]@{ Bins=$bins; CjpmMatches=$matches; SdkTools=@(Get-ChildItem -LiteralPath (Join-Path $sdk 'tools') -Force | Select-Object -First 50 -ExpandProperty Name) } | ConvertTo-Json -Depth 6
