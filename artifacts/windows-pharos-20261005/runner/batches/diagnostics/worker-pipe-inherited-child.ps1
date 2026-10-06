$ErrorActionPreference = 'Stop'
$source = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class PharosInheritedPipeChild
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct StartupInfo
    {
        public int cb;
        public string reserved;
        public string desktop;
        public string title;
        public int x;
        public int y;
        public int xSize;
        public int ySize;
        public int xCountChars;
        public int yCountChars;
        public int fillAttribute;
        public int flags;
        public short showWindow;
        public short reserved2Size;
        public IntPtr reserved2;
        public IntPtr stdin;
        public IntPtr stdout;
        public IntPtr stderr;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ProcessInformation
    {
        public IntPtr process;
        public IntPtr thread;
        public int processId;
        public int threadId;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int standardHandle);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CreateProcess(
        string applicationName, StringBuilder commandLine,
        IntPtr processAttributes, IntPtr threadAttributes,
        bool inheritHandles, uint creationFlags,
        IntPtr environment, string currentDirectory,
        ref StartupInfo startupInfo, out ProcessInformation processInformation);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    public static int Start()
    {
        string windows = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
        string powershell = System.IO.Path.Combine(windows, "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
        string command = "\"" + powershell + "\" -NoLogo -NoProfile -NonInteractive -Command \"Start-Sleep -Seconds 120\"";
        var startup = new StartupInfo();
        startup.cb = Marshal.SizeOf(typeof(StartupInfo));
        startup.flags = 0x00000100; // STARTF_USESTDHANDLES
        startup.stdin = GetStdHandle(-10);
        startup.stdout = GetStdHandle(-11);
        startup.stderr = GetStdHandle(-12);
        ProcessInformation process;
        if (!CreateProcess(powershell, new StringBuilder(command), IntPtr.Zero, IntPtr.Zero,
            true, 0x08000000, IntPtr.Zero, windows, ref startup, out process))
        {
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        }
        CloseHandle(process.thread);
        CloseHandle(process.process);
        return process.processId;
    }
}
'@
Add-Type -TypeDefinition $source -ErrorAction Stop
$pidPath = Join-Path $env:TEMP 'pharos-inherited-pipe-child.pid'
$childPid = [PharosInheritedPipeChild]::Start()
[System.IO.File]::WriteAllText($pidPath, [string]$childPid)
Write-Output "spawned_pid=$childPid"
exit 0
