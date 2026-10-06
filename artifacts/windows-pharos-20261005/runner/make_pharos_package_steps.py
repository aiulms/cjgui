#!/usr/bin/env python3
"""Generate isolated, serializable package build jobs for the Windows guest."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "batches" / "build"
PACKAGES = {
    "shared-operation-core": ("shared_operation_core", "runtime\\cjgui\\shared_operation_core"),
    "cjgui": ("cjgui", "runtime\\cjgui"),
    "document-core": ("document_core", "packages\\document_core"),
    "markdown-engine": ("markdown_engine", "packages\\markdown_engine"),
    "app-services": ("app_services", "packages\\app_services"),
    "editor-surface": ("editor_surface", "packages\\editor_surface"),
    "pharos-mark": ("pharos_mark", "apps\\pharos_mark"),
}
TEMPLATE = r'''$ErrorActionPreference='Continue'
$sdk=Join-Path $env:LOCALAPPDATA 'Programs\Cangjie'
$root='C:\cjgui-windows-w1\Pharos Mark Windows Source'
$name='__NAME__'
$path='__PATH__'
$dllDirs=@(Get-ChildItem -LiteralPath $sdk -Filter '*.dll' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {Split-Path -Parent $_.FullName} | Sort-Object -Unique)
$env:PATH=(($dllDirs+@((Join-Path $sdk 'tools\bin'),(Join-Path $sdk 'bin'))+@($env:PATH))-join ';')
$env:CANGJIE_HOME=$sdk
$cjpm=Join-Path $sdk 'tools\bin\cjpm.exe'
$pkg=Join-Path $root $path
$logPath=Join-Path $root ('build-logs\'+$name+'.log')
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $logPath))
Push-Location $pkg
try{$output=& $cjpm build 2>&1|Out-String;$exitCode=$LASTEXITCODE}
catch{$output=$_.ToString();$exitCode=1}
finally{Pop-Location}
$outputText=$output.Trim()
[System.IO.File]::WriteAllText($logPath,$outputText,[System.Text.UTF8Encoding]::new($false))
$bytes=[System.IO.File]::ReadAllBytes($logPath)
$sha=(Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash.ToLowerInvariant()
$uploadStatus=0;$uploadError=''
try{$upload=Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$($env:PHAROS_TRANSFER_BASE)/results/pharos-build-logs/$name.log" -Headers @{'X-Pharos-Session'=$env:PHAROS_TRANSFER_SESSION} -ContentType 'application/octet-stream' -Body $bytes;$uploadStatus=[int]$upload.StatusCode}
catch{$uploadError=$_.Exception.Message}
$exe=Join-Path $root 'apps\pharos_mark\target\release\bin\main.exe'
$app=$null
if($name -eq 'pharos_mark' -and (Test-Path -LiteralPath $exe)){$app=[PSCustomObject]@{Path=$exe;Bytes=(Get-Item -LiteralPath $exe).Length;Sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()}}
$diagnostics=@($outputText -split "`r?`n" | Where-Object {$_ -match 'error:|undefined symbol:|failed to compile|cjpm build failed|cjpm build success'})
$result=[PSCustomObject]@{Name=$name;Path=$path;Exit=$exitCode;OutputBytes=[System.Text.Encoding]::UTF8.GetByteCount($outputText);LogSha256=$sha;LogBytes=$bytes.Length;UploadStatus=$uploadStatus;UploadError=$uploadError;Diagnostics=$diagnostics;ApplicationExecutable=$app;Tail=@($outputText -split "`r?`n" | Select-Object -Last 20)}
$result|ConvertTo-Json -Depth 6
if($exitCode -ne 0){exit $exitCode}
'''

for slug, (name, path) in PACKAGES.items():
    source = TEMPLATE.replace("__NAME__", name).replace("__PATH__", path)
    (ROOT / f"pharos-package-{slug}.ps1").write_text(source, encoding="utf-8")
