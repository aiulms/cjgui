$workerPath = 'C:\cjgui-windows-w1\worker_run.ps1'
$currentWorkerPid = [int]$env:PHAROS_WORKER_PID
$pattern = '(?i)-File\s+"?C:\\cjgui-windows-w1\\worker_run\.ps1(?:\s|"|$)'
$consoleBefore = @(Get-Process -Name WindowsTerminal,conhost -ErrorAction SilentlyContinue | Group-Object ProcessName | ForEach-Object { [PSCustomObject]@{ Name=$_.Name; Count=$_.Count; Pids=@($_.Group.Id) } })
$targets = @(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $currentWorkerPid -and $_.Name -eq 'powershell.exe' -and $_.CommandLine -match $pattern } | ForEach-Object { [PSCustomObject]@{ Pid=[int]$_.ProcessId; ParentPid=[int]$_.ParentProcessId; SessionId=[int]$_.SessionId; CreationDate=[string]$_.CreationDate; CommandLine=$_.CommandLine } })
$stopped = @()
$errors = @()
foreach ($target in $targets) {
    $current = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $target.Pid) -ErrorAction SilentlyContinue
    if ($current -and $current.ProcessId -ne $currentWorkerPid -and $current.Name -eq 'powershell.exe' -and $current.CommandLine -match $pattern) {
        try { Stop-Process -Id $target.Pid -Force -ErrorAction Stop; $stopped += $target.Pid }
        catch { $errors += ('pid=' + $target.Pid + ':' + $_.Exception.Message) }
    }
}
Start-Sleep -Milliseconds 500
$remaining = @(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $currentWorkerPid -and $_.Name -eq 'powershell.exe' -and $_.CommandLine -match $pattern } | ForEach-Object { [PSCustomObject]@{ Pid=[int]$_.ProcessId; ParentPid=[int]$_.ParentProcessId; SessionId=[int]$_.SessionId; CommandLine=$_.CommandLine } })
$consoleAfter = @(Get-Process -Name WindowsTerminal,conhost -ErrorAction SilentlyContinue | Group-Object ProcessName | ForEach-Object { [PSCustomObject]@{ Name=$_.Name; Count=$_.Count; Pids=@($_.Group.Id) } })
[PSCustomObject]@{ WorkerPath=$workerPath; CurrentWorkerPid=$currentWorkerPid; CapturedUtc=[DateTime]::UtcNow.ToString('o'); ExactTargets=$targets; StoppedPids=$stopped; Errors=$errors; RemainingExactWorkers=$remaining; ConsoleBefore=$consoleBefore; ConsoleAfter=$consoleAfter } | ConvertTo-Json -Depth 8
