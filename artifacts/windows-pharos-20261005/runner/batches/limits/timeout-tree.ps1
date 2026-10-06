$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$child = Start-Process -FilePath $powerShell -ArgumentList '-NoLogo -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 30"' -WindowStyle Hidden -PassThru
$pidFile = 'C:\cjgui-windows-w1\timeout-child-pid.txt'
[System.IO.File]::WriteAllText($pidFile, [string]$child.Id)
Write-Output ("CHILD_PID=" + $child.Id)
Start-Sleep -Seconds 30
