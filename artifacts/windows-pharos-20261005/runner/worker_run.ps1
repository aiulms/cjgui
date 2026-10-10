param(
    [Parameter(Mandatory = $true)][string]$HostIp,
    [Parameter(Mandatory = $true)][int]$Port,
    [Parameter(Mandatory = $true)][string]$SessionId,
    [Parameter(Mandatory = $true)][string]$TransferBase
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$env:PHAROS_WORKER_PID = [string]$PID
$env:PHAROS_TRANSFER_BASE = $TransferBase.TrimEnd('/')
$env:PHAROS_TRANSFER_SESSION = $SessionId
$script:MaxRequestBytes = 4 * 1024 * 1024
$script:MaxResponseBytes = 16 * 1024 * 1024
$script:MaxOutputBytes = 256 * 1024
$script:MaxJobs = 16
$script:controlBuffer = ''
$script:deferredLines = New-Object System.Collections.Generic.List[string]
$script:cancelRequested = $false

if (-not ('PharosBoundedPipeCapture' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Threading.Tasks;

public sealed class PharosCapturedStream {
    public byte[] Bytes { get; private set; }
    public bool Truncated { get; private set; }
    public PharosCapturedStream(byte[] bytes, bool truncated) {
        Bytes = bytes;
        Truncated = truncated;
    }
}

public static class PharosBoundedPipeCapture {
    public static Task<PharosCapturedStream> Drain(Stream stream, int maximumBytes) {
        return Task.Run(() => {
            using (var retained = new MemoryStream()) {
                var buffer = new byte[8192];
                var truncated = false;
                int count;
                while ((count = stream.Read(buffer, 0, buffer.Length)) > 0) {
                    var available = maximumBytes - (int)retained.Length;
                    var keep = Math.Min(count, Math.Max(available, 0));
                    if (keep > 0) retained.Write(buffer, 0, keep);
                    if (keep < count) truncated = true;
                }
                return new PharosCapturedStream(retained.ToArray(), truncated);
            }
        });
    }
}

public sealed class PharosKillJob : IDisposable {
    private IntPtr handle;
    private const int JobObjectExtendedLimitInformation = 9;
    private const uint JobObjectLimitKillOnJobClose = 0x00002000;
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct BasicLimitInformation {
        public long PerProcessUserTimeLimit; public long PerJobUserTimeLimit; public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize; public UIntPtr MaximumWorkingSetSize; public uint ActiveProcessLimit;
        public UIntPtr Affinity; public uint PriorityClass; public uint SchedulingClass;
    }
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct IoCounters {
        public ulong ReadOperationCount; public ulong WriteOperationCount; public ulong OtherOperationCount;
        public ulong ReadTransferCount; public ulong WriteTransferCount; public ulong OtherTransferCount;
    }
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct ExtendedLimitInformation {
        public BasicLimitInformation BasicLimitInformation; public IoCounters IoInfo;
        public UIntPtr ProcessMemoryLimit; public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed; public UIntPtr PeakJobMemoryUsed;
    }
    [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetInformationJobObject(IntPtr job, int infoClass, IntPtr info, uint length);
    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);
    private PharosKillJob(IntPtr value) { handle = value; }
    public static PharosKillJob Assign(System.Diagnostics.Process process) {
        var value = CreateJobObject(IntPtr.Zero, null);
        if (value == IntPtr.Zero) throw new System.ComponentModel.Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error(), "CreateJobObject");
        var job = new PharosKillJob(value);
        try {
            var info = new ExtendedLimitInformation();
            info.BasicLimitInformation.LimitFlags = JobObjectLimitKillOnJobClose;
            var length = System.Runtime.InteropServices.Marshal.SizeOf(typeof(ExtendedLimitInformation));
            var memory = System.Runtime.InteropServices.Marshal.AllocHGlobal(length);
            try {
                System.Runtime.InteropServices.Marshal.StructureToPtr(info, memory, false);
                if (!SetInformationJobObject(value, JobObjectExtendedLimitInformation, memory, (uint)length))
                    throw new System.ComponentModel.Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error(), "SetInformationJobObject");
            } finally { System.Runtime.InteropServices.Marshal.FreeHGlobal(memory); }
            if (!AssignProcessToJobObject(value, process.Handle))
                throw new System.ComponentModel.Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error(), "AssignProcessToJobObject");
            return job;
        } catch { job.Dispose(); throw; }
    }
    public void Dispose() {
        if (handle != IntPtr.Zero) { var value = handle; handle = IntPtr.Zero; CloseHandle(value); }
    }
}
'@
}

function Write-Line([System.IO.Stream]$Stream, [string]$Text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text + "`n")
    $Stream.Write($bytes, 0, $bytes.Length)
    $Stream.Flush()
}

function Read-Line([System.IO.Stream]$Stream, [int]$MaximumBytes = 8192) {
    $data = New-Object System.Collections.Generic.List[byte]
    $one = New-Object byte[] 1
    while ($data.Count -le $MaximumBytes) {
        $read = $Stream.Read($one, 0, 1)
        if ($read -eq 0) {
            if ($data.Count -eq 0) { return $null }
            throw 'protocol_line_truncated'
        }
        if ($one[0] -eq 10) {
            return [System.Text.Encoding]::UTF8.GetString($data.ToArray())
        }
        $data.Add($one[0])
    }
    throw 'protocol_line_too_large'
}

function Read-Exact([System.IO.Stream]$Stream, [int]$Length) {
    if ($Length -lt 0 -or $Length -gt $script:MaxRequestBytes) {
        throw "request_length_out_of_bounds:$Length"
    }
    $data = New-Object byte[] $Length
    $offset = 0
    while ($offset -lt $Length) {
        $read = $Stream.Read($data, $offset, [Math]::Min(65536, $Length - $offset))
        if ($read -eq 0) { throw 'request_frame_truncated' }
        $offset += $read
    }
    return ,$data
}

function ConvertTo-Base64([byte[]]$Bytes) {
    return [System.Convert]::ToBase64String($Bytes)
}

function Pump-Control([System.IO.Stream]$Stream, [string]$Nonce) {
    if (-not $Stream.DataAvailable) { return }
    $chunk = New-Object byte[] 4096
    $count = $Stream.Read($chunk, 0, $chunk.Length)
    if ($count -le 0) { return }
    $script:controlBuffer += [System.Text.Encoding]::UTF8.GetString($chunk, 0, $count)
    while ($true) {
        $index = $script:controlBuffer.IndexOf("`n")
        if ($index -lt 0) { break }
        $line = $script:controlBuffer.Substring(0, $index)
        $script:controlBuffer = $script:controlBuffer.Substring($index + 1)
        if ($line -eq '') { continue }
        if ($line -match '^CANCEL ([0-9a-f]{32})$') {
            if ($Matches[1] -eq $Nonce) { $script:cancelRequested = $true }
        } else {
            $script:deferredLines.Add($line)
        }
    }
}

function Read-Control-Line([System.IO.Stream]$Stream) {
    if ($script:deferredLines.Count -gt 0) {
        $line = $script:deferredLines[0]
        $script:deferredLines.RemoveAt(0)
        return $line
    }
    return (Read-Line $Stream)
}

function New-CancelledRecord([string]$Name) {
    return [PSCustomObject][ordered]@{
        name = $Name
        exit_code = 125
        timed_out = $false
        cancelled = $true
        stdout_truncated = $false
        stderr_truncated = $false
        stdout_b64 = ''
        stderr_b64 = ''
        elapsed_ms = 0
        error = ''
    }
}

function Invoke-TaskJob([object]$Job, [string]$SessionRoot, [System.IO.Stream]$Control, [string]$Nonce) {
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $record = [ordered]@{
        name = [string]$Job.name
        exit_code = 1
        timed_out = $false
        cancelled = $false
        stdout_truncated = $false
        stderr_truncated = $false
        stdout_b64 = ''
        stderr_b64 = ''
        elapsed_ms = 0
        error = ''
    }
    $process = $null
    $childJob = $null
    $stdoutTask = $null
    $stderrTask = $null
    $startGate = $null
    $jobDirectory = Join-Path $SessionRoot ([Guid]::NewGuid().ToString('N'))
    try {
        if ([string]::IsNullOrWhiteSpace([string]$Job.name) -or
            [string]$Job.name -match '[\r\n]' -or
            -not ($Job.script -is [string]) -or
            -not ($Job.timeout_ms -is [ValueType]) -or $Job.timeout_ms -is [bool] -or
            [int]$Job.timeout_ms -lt 1 -or [int]$Job.timeout_ms -gt 7200000 -or
            [string]::IsNullOrWhiteSpace([string]$Job.working_directory)) {
            throw 'job_fields_invalid'
        }
        $workingDirectory = [string]$Job.working_directory
        if (-not (Test-Path -LiteralPath $workingDirectory -PathType Container)) {
            throw "working_directory_missing:$workingDirectory"
        }
        [void][System.IO.Directory]::CreateDirectory($jobDirectory)
        $taskPath = Join-Path $jobDirectory 'task.ps1'
        $wrapperPath = Join-Path $jobDirectory 'run.ps1'
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($taskPath, [string]$Job.script, $utf8Bom)
        $wrapper = @'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$startGate = $null
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $startGate = [System.Threading.EventWaitHandle]::OpenExisting($env:PHAROS_TASK_START_GATE)
    if (-not $startGate.WaitOne(10000)) { throw 'child_start_gate_timeout' }
    $global:LASTEXITCODE = $null
    & $env:PHAROS_TASK_SCRIPT
    if ($null -ne $global:LASTEXITCODE) { exit [int]$global:LASTEXITCODE }
    exit 0
} catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
} finally {
    if ($null -ne $startGate) { $startGate.Dispose() }
}
'@
        [System.IO.File]::WriteAllText($wrapperPath, $wrapper, $utf8Bom)

        $powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $powershellPath
        $psi.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $wrapperPath + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $workingDirectory
        $psi.EnvironmentVariables['PHAROS_TASK_SCRIPT'] = $taskPath
        $psi.EnvironmentVariables['PHAROS_WORKER_PID'] = [string]$PID
        $psi.EnvironmentVariables['PHAROS_TRANSFER_BASE'] = $env:PHAROS_TRANSFER_BASE
        $psi.EnvironmentVariables['PHAROS_TRANSFER_SESSION'] = $SessionId
        $startGateName = 'Local\pharos-task-start-' + [Guid]::NewGuid().ToString('N')
        $psi.EnvironmentVariables['PHAROS_TASK_START_GATE'] = $startGateName
        $startGate = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::ManualReset, $startGateName)
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        if (-not $process.Start()) { throw 'child_process_start_failed' }
        $childJob = [PharosKillJob]::Assign($process)
        $stdoutTask = [PharosBoundedPipeCapture]::Drain($process.StandardOutput.BaseStream, $script:MaxOutputBytes)
        $stderrTask = [PharosBoundedPipeCapture]::Drain($process.StandardError.BaseStream, $script:MaxOutputBytes)
        [void]$startGate.Set()
        $waitRemaining = [int]$Job.timeout_ms
        $completed = $false
        while ($waitRemaining -gt 0) {
            $slice = [Math]::Min(500, $waitRemaining)
            if ($process.WaitForExit($slice)) { $completed = $true; break }
            $waitRemaining -= $slice
            Pump-Control $Control $Nonce
            if ($script:cancelRequested) { break }
        }
        if ($script:cancelRequested) {
            # A CANCEL whose nonce matches this batch stops the task's process
            # tree and is reported as `cancelled`; it must never look like a
            # normal exit or like a timeout. Exit code 125 is the named
            # "cancelled by request" code for both killed and skipped jobs.
            $record.cancelled = $true
            $record.exit_code = 125
            if ($null -ne $childJob) { $childJob.Dispose(); $childJob = $null }
            $process.Refresh()
            if (-not $process.HasExited) { $process.Kill() }
            if (-not $process.WaitForExit(10000)) {
                throw "cancelled_child_not_reaped:pid=$($process.Id)"
            }
        }
        if (-not $completed -and -not $script:cancelRequested) {
            $record.timed_out = $true
            $childJob.Dispose()
            $childJob = $null
            $process.Refresh()
            if (-not $process.HasExited) { $process.Kill() }
            if (-not $process.WaitForExit(10000)) {
                throw "timed_out_child_not_reaped:pid=$($process.Id)"
            }
        }
        if (-not $record.cancelled) { $record.exit_code = [int]$process.ExitCode }
        # A task can exit while one of its descendants still holds the
        # wrapper's inherited stdout/stderr pipe handles. Retire this task's
        # kill-on-close job before waiting for pipe EOF so those handles cannot
        # turn a completed task into child_output_pipe_drain_timeout.
        if ($null -ne $childJob) { $childJob.Dispose(); $childJob = $null }
        if (-not [System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]@($stdoutTask, $stderrTask), 15000)) {
            throw 'child_output_pipe_drain_timeout'
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $record.stdout_truncated = [bool]$stdout.Truncated
        $record.stderr_truncated = [bool]$stderr.Truncated
        $record.stdout_b64 = ConvertTo-Base64 $stdout.Bytes
        $record.stderr_b64 = ConvertTo-Base64 $stderr.Bytes
    } catch {
        $record.error = $_.Exception.Message
        if ($null -ne $process) {
            try {
                if (-not $process.HasExited) {
                    if ($null -ne $childJob) { $childJob.Dispose(); $childJob = $null }
                    $process.Refresh()
                    if (-not $process.HasExited) { $process.Kill() }
                    $null = $process.WaitForExit(10000)
                }
            } catch { }
        }
        if ($null -ne $stdoutTask -and $null -ne $stderrTask) {
            try { [void][System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]@($stdoutTask, $stderrTask), 5000) } catch { }
        }
    } finally {
        $watch.Stop()
        $record.elapsed_ms = [int][Math]::Min([int]::MaxValue, $watch.ElapsedMilliseconds)
        if ($null -ne $childJob) { $childJob.Dispose() }
        if ($null -ne $process) { $process.Dispose() }
        if ($null -ne $startGate) { $startGate.Dispose() }
        try { Remove-Item -LiteralPath $jobDirectory -Recurse -Force -ErrorAction SilentlyContinue } catch { }
    }
    return [PSCustomObject]$record
}

$client = New-Object System.Net.Sockets.TcpClient
$client.NoDelay = $true
$client.Connect($HostIp, $Port)
$stream = $client.GetStream()
$stream.ReadTimeout = 7500000
$stream.WriteTimeout = 30000
$workerPath = $MyInvocation.MyCommand.Path
$workerHash = (Get-FileHash -LiteralPath $workerPath -Algorithm SHA256).Hash.ToLowerInvariant()
$processArchitecture = if ([IntPtr]::Size -eq 8) { 'x64' } else { 'x86' }
try {
    $osArchitecture = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).OSArchitecture
} catch {
    $osArchitecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITEW6432')
    if ([string]::IsNullOrEmpty($osArchitecture)) { $osArchitecture = $env:PROCESSOR_ARCHITECTURE }
}
$hello = [ordered]@{
    session_id = $SessionId
    worker_path = $workerPath
    worker_sha256 = $workerHash
    pid = [int]$PID
    process_architecture = $processArchitecture
    os_architecture = [string]$osArchitecture
    powershell_version = $PSVersionTable.PSVersion.ToString()
    transfer_base = $env:PHAROS_TRANSFER_BASE
    started_at_utc = [DateTime]::UtcNow.ToString('o')
}
Write-Line $stream ('HELLO ' + (ConvertTo-Json -InputObject $hello -Compress -Depth 4))
$ack = Read-Line $stream
if ($ack -ne ('ACK ' + $SessionId)) { throw "worker_ack_mismatch:$ack" }
$sessionRoot = Join-Path $env:TEMP ('pharos-worker-' + $SessionId)
[void][System.IO.Directory]::CreateDirectory($sessionRoot)

try {
    while ($true) {
        $line = Read-Control-Line $stream
        if ($null -eq $line) { break }
        if ($line -match '^CANCEL ([0-9a-f]{32})$') { continue }
        if ($line -match '^STOP ([0-9a-fA-F]{32})$') {
            if ($Matches[1] -ne $SessionId) { throw 'stop_session_mismatch' }
            Write-Line $stream ('BYE ' + $PID + ' ' + $SessionId)
            break
        }
        if ($line -notmatch '^BATCH ([1-9][0-9]{0,7}) ([0-9a-f]{32})$') {
            throw "unexpected_control_frame:$line"
        }
        $requestLength = [int]$Matches[1]
        $nonce = $Matches[2]
        if ($requestLength -gt $script:MaxRequestBytes) { throw 'request_frame_too_large' }
        $requestBytes = Read-Exact $stream $requestLength
        $terminator = Read-Line $stream 1
        if ($terminator -ne '') { throw 'request_frame_terminator_missing' }
        $request = ConvertFrom-Json -InputObject ([System.Text.Encoding]::UTF8.GetString($requestBytes)) -ErrorAction Stop
        if ($request.nonce -ne $nonce) { throw 'request_nonce_mismatch' }
        $jobs = @($request.jobs)
        if ($jobs.Count -lt 1 -or $jobs.Count -gt $script:MaxJobs) { throw 'batch_job_count_out_of_range' }
        $names = @{}
        $results = New-Object System.Collections.Generic.List[object]
        $script:cancelRequested = $false
        for ($jobIndex = 0; $jobIndex -lt $jobs.Count; $jobIndex++) {
            $job = $jobs[$jobIndex]
            $name = [string]$job.name
            if ($names.ContainsKey($name)) { throw "duplicate_job_name:$name" }
            $names[$name] = $true
            if ($script:cancelRequested) {
                $results.Add((New-CancelledRecord $name))
                continue
            }
            $results.Add((Invoke-TaskJob $job $sessionRoot $stream $nonce))
        }
        $response = [ordered]@{ nonce = $nonce; state = 'complete'; results = @($results.ToArray()) }
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $response -Depth 8 -Compress))
        if ($responseBytes.Length -gt $script:MaxResponseBytes) { throw 'response_frame_too_large' }
        Write-Line $stream ('RESULTS ' + $responseBytes.Length + ' ' + $nonce)
        $stream.Write($responseBytes, 0, $responseBytes.Length)
        $stream.WriteByte(10)
        $stream.Flush()
        $ack = Read-Line $stream
        if ($ack -ne ('ACK ' + $nonce)) { throw "batch_ack_mismatch:$ack" }
        Write-Line $stream ('DONE ' + $nonce)
    }
} finally {
    $stream.Dispose()
    $client.Close()
    try { Remove-Item -LiteralPath $sessionRoot -Recurse -Force -ErrorAction SilentlyContinue } catch { }
}
