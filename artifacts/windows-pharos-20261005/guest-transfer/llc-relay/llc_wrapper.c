/* llc relay wrapper v2 (hash-gated) for the Windows Pharos build.
 *
 * 背景（保留 v1 的动机说明）：Windows 目标下 CJStackPointerInserter 在单个巨大
 * `runPharosApplication` 机器函数上病态（原生 M1 约 29 分钟/模块，来宾 x64 模拟
 * 下数小时）。前端、opt 与最终链接仍在来宾执行；仅这一步代码生成走 relay：
 * 用**同一份 bitcode**（同 SDK llc 版本、同 target flags）在 Mac 产出的 obj 注入，
 * 并把这轮实际生成的 bitcode 抄存以便事后核验。
 *
 * v2 相对 v1 的强制门（复核要求）：
 *  1. 注入前必须同时核 **输入 .opt.bc 的内容哈希** 与 **待注入 obj 的内容哈希**
 *     与 relay-expect.txt 记录一致；任一不匹配 → 非零退出（94），不注入。
 *  2. 捕获（CopyFile inPath → build-bc-captured.bc）失败 → 非零退出（95）。
 *  3. 注入写盘失败 → 非零退出（91）。
 *  4. 非 pharos_mark.opt.bc 的模块原样转发 llc-real.exe，行为不变。
 * 任何失败都不会以 0 返回，避免“按文件名注入旧 obj”或“捕获失败仍算成功”。
 */
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <bcrypt.h>
#include <stdio.h>
#include <string.h>

#define RELAY_DIR "C:\\cjgui-windows-w1\\llc-relay"
#define RELAY_OBJ RELAY_DIR "\\pharos_mark.o"
#define RELAY_BC_CAPTURE RELAY_DIR "\\build-bc-captured.bc"
#define RELAY_EXPECT RELAY_DIR "\\relay-expect.txt"
#define RELAY_LOG RELAY_DIR "\\inject.log"

static void log_line(const char *text) {
    FILE *fp = fopen(RELAY_LOG, "a");
    if (fp) { fputs(text, fp); fputc('\n', fp); fclose(fp); }
}

static int sha256_file_hex(const char *path, char out_hex[65]) {
    BCRYPT_ALG_HANDLE alg = NULL;
    BCRYPT_HASH_HANDLE hash = NULL;
    HANDLE file = INVALID_HANDLE_VALUE;
    unsigned char digest[32];
    unsigned char buffer[65536];
    DWORD read = 0;
    int ok = 0;
    if (BCryptOpenAlgorithmProvider(&alg, BCRYPT_SHA256_ALGORITHM, NULL, 0) != 0) return 0;
    if (BCryptCreateHash(alg, &hash, NULL, 0, NULL, 0, 0) != 0) goto done;
    file = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) goto done;
    for (;;) {
        if (!ReadFile(file, buffer, (DWORD)sizeof(buffer), &read, NULL)) goto done;
        if (read == 0) break;
        if (BCryptHashData(hash, buffer, read, 0) != 0) goto done;
    }
    if (BCryptFinishHash(hash, digest, (ULONG)sizeof(digest), 0) != 0) goto done;
    for (int i = 0; i < 32; ++i) sprintf(out_hex + i * 2, "%02x", digest[i]);
    out_hex[64] = '\0';
    ok = 1;
done:
    if (file != INVALID_HANDLE_VALUE) CloseHandle(file);
    if (hash) BCryptDestroyHash(hash);
    if (alg) BCryptCloseAlgorithmProvider(alg, 0);
    return ok;
}

static void trim_line(char *line) {
    size_t n = strlen(line);
    while (n > 0 && (line[n - 1] == '\n' || line[n - 1] == '\r' || line[n - 1] == ' ' ||
        line[n - 1] == '\t')) {
        line[--n] = '\0';
    }
}

static int read_expect(char bc_hex[65], char obj_hex[65]) {
    FILE *fp = fopen(RELAY_EXPECT, "r");
    char line1[128];
    char line2[128];
    if (!fp) return 0;
    if (!fgets(line1, (int)sizeof(line1), fp)) { fclose(fp); return 0; }
    if (!fgets(line2, (int)sizeof(line2), fp)) { fclose(fp); return 0; }
    fclose(fp);
    trim_line(line1);
    trim_line(line2);
    if (strlen(line1) != 64 || strlen(line2) != 64) return 0;
    strcpy(bc_hex, line1);
    strcpy(obj_hex, line2);
    return 1;
}

int main(int argc, char **argv) {
    const char *outPath = NULL;
    const char *inPath = NULL;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "-o") && i + 1 < argc) outPath = argv[i + 1];
        if (strstr(argv[i], ".opt.bc") != NULL) inPath = argv[i];
    }
    if (inPath && outPath && strstr(inPath, "pharos_mark.opt.bc") != NULL) {
        char expect_bc[65];
        char expect_obj[65];
        char got_bc[65];
        char got_obj[65];
        char line[1024];
        if (!read_expect(expect_bc, expect_obj)) {
            log_line("REJECT expect_missing_or_invalid");
            return 94;
        }
        if (!sha256_file_hex(inPath, got_bc)) {
            log_line("REJECT input_bc_unreadable");
            return 94;
        }
        if (!sha256_file_hex(RELAY_OBJ, got_obj)) {
            log_line("REJECT relay_obj_unreadable");
            return 94;
        }
        if (strcmp(got_bc, expect_bc) != 0) {
            _snprintf(line, sizeof(line), "REJECT bc_mismatch got=%s want=%s", got_bc, expect_bc);
            log_line(line);
            return 94;
        }
        if (strcmp(got_obj, expect_obj) != 0) {
            _snprintf(line, sizeof(line), "REJECT obj_mismatch got=%s want=%s", got_obj, expect_obj);
            log_line(line);
            return 94;
        }
        if (!CopyFileA(inPath, RELAY_BC_CAPTURE, FALSE)) {
            _snprintf(line, sizeof(line), "CAPTURE_FAILED in=%s err=%lu", inPath, GetLastError());
            log_line(line);
            return 95;
        }
        if (!CopyFileA(RELAY_OBJ, outPath, FALSE)) {
            _snprintf(line, sizeof(line), "INJECT_FAILED out=%s err=%lu", outPath, GetLastError());
            log_line(line);
            return 91;
        }
        _snprintf(line, sizeof(line), "INJECTED bc=%s obj=%s out=%s", got_bc, got_obj, outPath);
        log_line(line);
        return 0;
    }
    char llcReal[MAX_PATH];
    char *name = NULL;
    DWORD n = GetModuleFileNameA(NULL, llcReal, MAX_PATH);
    if (n == 0 || n >= MAX_PATH) return 92;
    name = strrchr(llcReal, '\\');
    if (!name) return 92;
    name[1] = '\0';
    strncat(llcReal, "llc-real.exe", MAX_PATH - strlen(llcReal) - 1);
    char cmd[65536];
    int written = _snprintf(cmd, sizeof(cmd), "\"%s\"", llcReal);
    for (int i = 1; i < argc && written > 0 && written < (int)sizeof(cmd); ++i) {
        written += _snprintf(cmd + written, sizeof(cmd) - written, " \"%s\"", argv[i]);
    }
    if (written <= 0 || written >= (int)sizeof(cmd)) return 92;
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
