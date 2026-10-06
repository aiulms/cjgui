$pidFile = 'C:\cjgui-windows-w1\timeout-child-pid.txt'
$childPid = [int][System.IO.File]::ReadAllText($pidFile)
$child = Get-Process -Id $childPid -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $pidFile -Force
if ($child) { throw "timed_out_descendant_still_alive:$childPid" }
Write-Output ("DESCENDANT_REAPED pid=" + $childPid)
