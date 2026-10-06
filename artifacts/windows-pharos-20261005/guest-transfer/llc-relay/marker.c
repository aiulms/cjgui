#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    FILE *fp = fopen("C:\\cjgui-windows-w1\\relay-toolchain\\marker.log", "a");
    if (fp) { fprintf(fp, "MARKER argc=%d\n", argc); fclose(fp); }
    char exe[MAX_PATH];
    DWORD n = GetModuleFileNameA(NULL, exe, MAX_PATH);
    if (n == 0 || n >= MAX_PATH) return 92;
    char *slash = strrchr(exe, '\\');
    if (!slash) return 92;
    slash[1] = '\0';
    strncat(exe, "llc-real.exe", MAX_PATH - strlen(exe) - 1);
    char cmd[65536];
    int w = _snprintf(cmd, sizeof(cmd), "\"%s\"", exe);
    for (int i = 1; i < argc && w > 0 && w < (int)sizeof(cmd); ++i)
        w += _snprintf(cmd + w, sizeof(cmd) - w, " \"%s\"", argv[i]);
    if (w <= 0 || w >= (int)sizeof(cmd)) return 92;
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    memset(&pi, 0, sizeof(pi));
    if (!CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) return 93;
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 1;
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return (int)code;
}
