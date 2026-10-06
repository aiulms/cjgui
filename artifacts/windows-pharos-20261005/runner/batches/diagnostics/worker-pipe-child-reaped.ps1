$ErrorActionPreference = 'Stop'
$pidPath = Join-Path $env:TEMP 'pharos-inherited-pipe-child.pid'
if (!(Test-Path -LiteralPath $pidPath)) { throw 'child_pid_marker_missing' }
$childPid = [int][System.IO.File]::ReadAllText($pidPath)
if (Get-Process -Id $childPid -ErrorAction SilentlyContinue) {
    throw "inherited_pipe_child_survived:$childPid"
}
Write-Output "child_reaped=$childPid"
exit 0
