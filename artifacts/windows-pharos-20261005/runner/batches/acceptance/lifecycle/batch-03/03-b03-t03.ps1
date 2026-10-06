$ErrorActionPreference = 'Stop'
$workerPid = [int]$env:PHAROS_WORKER_PID
$self = Get-CimInstance Win32_Process -Filter "ProcessId = $PID"
$main = Get-Process -Id $PID
$root = Join-Path $env:TEMP ('pharos-worker-' + $env:PHAROS_TRANSFER_SESSION)
$jobDirs = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction Stop)
$row = [ordered]@{
    task = 'b03-t03'
    worker_pid = $workerPid
    child_pid = [int]$PID
    parent_pid = [int]$self.ParentProcessId
    main_window_handle = $main.MainWindowHandle.ToInt64()
    active_job_directories = $jobDirs.Count
}
Write-Output (ConvertTo-Json -InputObject $row -Compress)
if ($workerPid -le 0 -or [int]$self.ParentProcessId -ne $workerPid -or
    $main.MainWindowHandle -ne [IntPtr]::Zero -or $jobDirs.Count -ne 1) {
    throw 'worker_child_or_temp_lifecycle_mismatch'
}
Start-Sleep -Milliseconds 12
