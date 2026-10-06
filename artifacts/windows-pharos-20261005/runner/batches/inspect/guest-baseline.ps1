$processes = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('worker_run.ps1','powershell.exe','WindowsTerminal.exe','conhost.exe') } | ForEach-Object {
    if ($_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'C:\\cjgui-windows-w1\\worker_run\.ps1') {
        [PSCustomObject]@{ Name=$_.Name; Pid=[int]$_.ProcessId; ParentPid=[int]$_.ParentProcessId; CommandLine=$_.CommandLine; SessionId=[int]$_.SessionId }
    } elseif ($_.Name -in @('WindowsTerminal.exe','conhost.exe')) {
        [PSCustomObject]@{ Name=$_.Name; Pid=[int]$_.ProcessId; ParentPid=[int]$_.ParentProcessId; CommandLine=$_.CommandLine; SessionId=[int]$_.SessionId }
    }
})
$windows = Get-Process -Name WindowsTerminal,conhost -ErrorAction SilentlyContinue | Group-Object ProcessName | ForEach-Object { [PSCustomObject]@{ Name=$_.Name; Count=$_.Count; Pids=@($_.Group.Id) } }
$os = Get-CimInstance Win32_OperatingSystem
[PSCustomObject]@{
    captured_utc=[DateTime]::UtcNow.ToString('o')
    computer=$env:COMPUTERNAME
    windows_caption=$os.Caption
    windows_version=$os.Version
    os_architecture=$os.OSArchitecture
    process_architecture=if ([IntPtr]::Size -eq 8) {'x64'} else {'x86'}
    processor_architecture=$env:PROCESSOR_ARCHITECTURE
    processor_architecture_wow64=$env:PROCESSOR_ARCHITEW6432
    worker_processes=@($processes | Where-Object { $_.CommandLine -match 'C:\\cjgui-windows-w1\\worker_run\.ps1' })
    console_process_counts=@($windows)
    temp=$env:TEMP
} | ConvertTo-Json -Depth 8
