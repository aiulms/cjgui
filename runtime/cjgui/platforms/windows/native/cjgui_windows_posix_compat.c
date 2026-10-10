// Windows 上的 POSIX 兼容垫片：为链接期仍引用以下符号的已编译对象提供
// 最小、语义等价的实现。它们只做平台转换（CRT/MoveFileEx），不携带业务。
// - open/renameat -> strict UTF-8 paths through wide Windows/CRT APIs
// - fsync -> FlushFileBuffers on the SAME opened object with write access
// - pread  -> _lseeki64 + _read + 位置恢复（保持 POSIX“读后位置不变”语义；
//              不依赖调用方是否只用绝对偏移，共享句柄上的位置读不会被污染）
// - renameat -> MoveFileExW（调用方使用绝对路径；不先删除目标）
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <io.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdarg.h>

static void windows_file_errno(DWORD error) {
    switch (error) {
        case ERROR_FILE_NOT_FOUND: case ERROR_PATH_NOT_FOUND: errno = ENOENT; break;
        case ERROR_INVALID_HANDLE: errno = EBADF; break;
        case ERROR_NOT_ENOUGH_MEMORY: case ERROR_OUTOFMEMORY: errno = ENOMEM; break;
        case ERROR_NO_UNICODE_TRANSLATION: errno = EILSEQ; break;
        case ERROR_INVALID_PARAMETER: case ERROR_INVALID_NAME: errno = EINVAL; break;
        default: errno = EACCES; break;
    }
    SetLastError(error);
}

static WCHAR *windows_file_path_utf8(const char *path) {
    if (!path) { errno = EINVAL; return NULL; }
    int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, NULL, 0);
    if (!count) { windows_file_errno(GetLastError()); return NULL; }
    WCHAR *wide = (WCHAR *)malloc((size_t)count * sizeof(WCHAR));
    if (!wide) { errno = ENOMEM; return NULL; }
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, wide, count)) {
        DWORD error = GetLastError(); free(wide); windows_file_errno(error); return NULL;
    }
    return wide;
}

/* This existing foreign symbol is consumed by document_core's narrow file
   adapter. Its paths are UTF-8 and its descriptors carry raw bytes. CRT open's
   active ANSI code page and text-mode CRLF conversion are not that contract. */
int open(const char *path, int flags, ...) {
    int mode = 0;
    if (flags & _O_CREAT) {
        va_list args; va_start(args, flags); mode = va_arg(args, int); va_end(args);
    }
    WCHAR *wide = windows_file_path_utf8(path);
    if (!wide) return -1;
    DWORD attributes = GetFileAttributesW(wide);
    if (attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY)) {
        if ((flags & (_O_WRONLY | _O_RDWR | _O_CREAT | _O_TRUNC)) != 0) {
            free(wide); errno = EISDIR; return -1;
        }
        /* The current directory-FD consumer is a durability barrier. Unlike a
           regular CRT file, a directory cannot be upgraded with ReOpenFile on
           this backend. Obtain its flush right at creation; keep the CRT FD
           read-only, and never accept a denied barrier as a successful read. */
        HANDLE handle = CreateFileW(wide, GENERIC_READ | GENERIC_WRITE,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
            OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
        DWORD error = GetLastError(); free(wide);
        if (handle == INVALID_HANDLE_VALUE) { windows_file_errno(error); return -1; }
        int fd = _open_osfhandle((intptr_t)handle, _O_RDONLY | _O_BINARY);
        if (fd < 0) CloseHandle(handle);
        return fd;
    }
    int fd = _wopen(wide, (flags & ~_O_TEXT) | _O_BINARY, mode);
    free(wide);
    return fd;
}

int fsync(int fd) {
    if (fd < 0) { errno = EBADF; return -1; }
    intptr_t raw = _get_osfhandle(fd);
    if (raw == -1) { errno = EBADF; return -1; }
    HANDLE original = (HANDLE)raw;
    if (FlushFileBuffers(original)) return 0;
    DWORD firstError = GetLastError();
    if (firstError != ERROR_ACCESS_DENIED) { windows_file_errno(firstError); return -1; }
    BY_HANDLE_FILE_INFORMATION info;
    if (!GetFileInformationByHandle(original, &info)) {
        windows_file_errno(GetLastError()); return -1;
    }
    DWORD flags = (info.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        ? FILE_FLAG_BACKUP_SEMANTICS : 0;
    /* ReOpenFile preserves object identity even if its pathname is replaced.
       Do not re-resolve a later path or treat access/sync refusal as success. */
    HANDLE writer = ReOpenFile(original, GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, flags);
    if (writer == INVALID_HANDLE_VALUE) { windows_file_errno(GetLastError()); return -1; }
    BOOL ok = FlushFileBuffers(writer);
    DWORD error = GetLastError(); CloseHandle(writer);
    if (!ok) { windows_file_errno(error); return -1; }
    return 0;
}

long long pread(int fd, void *buffer, size_t count, long long offset) {
    if (!buffer || count == 0) return 0;
    long long saved = _lseeki64(fd, 0, SEEK_CUR);
    if (offset >= 0 && _lseeki64(fd, offset, SEEK_SET) < 0) {
        if (saved >= 0) (void)_lseeki64(fd, saved, SEEK_SET);
        return -1;
    }
    unsigned int chunk = count > 0x40000000ull ? 0x40000000u : (unsigned int)count;
    int got = _read(fd, buffer, chunk);
    if (saved >= 0) (void)_lseeki64(fd, saved, SEEK_SET);
    return got;
}

int renameat(int oldDirFd, const char *oldPath, int newDirFd, const char *newPath) {
    (void)oldDirFd;
    (void)newDirFd;
    if (!oldPath || !newPath) { errno = EINVAL; return -1; }
    WCHAR *from = windows_file_path_utf8(oldPath);
    if (!from) return -1;
    WCHAR *to = windows_file_path_utf8(newPath);
    if (!to) { free(from); return -1; }
    BOOL ok = MoveFileExW(from, to, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
    DWORD error = GetLastError(); free(from); free(to);
    if (ok) return 0;
    windows_file_errno(error); return -1;
}

/* ---------- 稳定源捕获窄桥（Windows 专有，不携带业务） ----------
   document_core 需要一个"复制期间源保持静止"的可证明依据。普通只读句柄不够：
   dwShareMode 只约束之后的打开者，既不拒绝此刻已持有写句柄的人，也不排除已存在的
   写映射视图，所以同长度并发改写可以完全不被发现。这里改为独占取得源对象
   （不共享读/写/删除）：取得成功即证明复制期间不存在也不可能出现其它持有者；
   取不到就具名拒绝，绝不静默降级成共享只读打开，也不改用字节锁冒充强快照。
   长度与身份一律从同一个句柄读取，不允许"查路径后再换源"。
   候选一律 CREATE_NEW 独占创建：已存在即具名失败，绝不 remove 别人留下的路径；
   只有确认是自己创建的候选才允许清理。发布放在校验/封存之后，失败与取消都保旧。 */
#define PHAROS_CAPTURE_OK             0
#define PHAROS_CAPTURE_BAD_PATH       1
#define PHAROS_CAPTURE_MISSING        2
#define PHAROS_CAPTURE_NOT_FILE       3
#define PHAROS_CAPTURE_BUSY           4
#define PHAROS_CAPTURE_EXISTS         5
#define PHAROS_CAPTURE_IO             6
#define PHAROS_CAPTURE_SHORT          7
#define PHAROS_CAPTURE_CANCELLED      8

static void windows_capture_reason(DWORD error, int *out_reason) {
    int reason = PHAROS_CAPTURE_IO;
    if (error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND) {
        reason = PHAROS_CAPTURE_MISSING;
    } else if (error == ERROR_SHARING_VIOLATION || error == ERROR_LOCK_VIOLATION
        || error == ERROR_USER_MAPPED_FILE) {
        reason = PHAROS_CAPTURE_BUSY;
    } else if (error == ERROR_FILE_EXISTS || error == ERROR_ALREADY_EXISTS) {
        reason = PHAROS_CAPTURE_EXISTS;
    }
    windows_file_errno(error);
    if (out_reason) *out_reason = reason;
}

/* 独占取得源对象，并从同一句柄回填长度与 (卷号, FileId) 身份。 */
intptr_t pharos_capture_source_open(const char *path, int *out_reason, long long *out_length,
    unsigned long long *out_volume, unsigned long long *out_file_id) {
    if (out_reason) *out_reason = PHAROS_CAPTURE_OK;
    if (out_length) *out_length = -1;
    if (out_volume) *out_volume = 0u;
    if (out_file_id) *out_file_id = 0u;
    WCHAR *wide = windows_file_path_utf8(path);
    if (!wide) {
        if (out_reason) *out_reason = PHAROS_CAPTURE_BAD_PATH;
        return (intptr_t)INVALID_HANDLE_VALUE;
    }
    HANDLE handle = CreateFileW(wide, GENERIC_READ, 0u, NULL, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    DWORD error = GetLastError();
    free(wide);
    if (handle == INVALID_HANDLE_VALUE) {
        windows_capture_reason(error, out_reason);
        return (intptr_t)INVALID_HANDLE_VALUE;
    }
    BY_HANDLE_FILE_INFORMATION info;
    if (!GetFileInformationByHandle(handle, &info)) {
        error = GetLastError();
        CloseHandle(handle);
        windows_capture_reason(error, out_reason);
        return (intptr_t)INVALID_HANDLE_VALUE;
    }
    if ((info.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0u) {
        CloseHandle(handle);
        errno = EISDIR;
        if (out_reason) *out_reason = PHAROS_CAPTURE_NOT_FILE;
        return (intptr_t)INVALID_HANDLE_VALUE;
    }
    if (out_length) {
        LARGE_INTEGER size;
        size.QuadPart = 0;
        if (!GetFileSizeEx(handle, &size)) {
            error = GetLastError();
            CloseHandle(handle);
            windows_capture_reason(error, out_reason);
            return (intptr_t)INVALID_HANDLE_VALUE;
        }
        *out_length = (long long)size.QuadPart;
    }
    if (out_volume) *out_volume = (unsigned long long)info.dwVolumeSerialNumber;
    if (out_file_id) {
        *out_file_id = ((unsigned long long)info.nFileIndexHigh << 32)
            | (unsigned long long)info.nFileIndexLow;
    }
    return (intptr_t)handle;
}

/* 同一句柄上的绝对偏移有界读取：不改动句柄位置语义，单次不超过 1 MiB。 */
long long pharos_capture_source_read(intptr_t handle, void *buffer, long long count,
    long long offset) {
    if (handle == (intptr_t)INVALID_HANDLE_VALUE || !buffer) { errno = EINVAL; return -1; }
    if (count <= 0) return 0;
    if (count > 1024 * 1024) count = 1024 * 1024;
    OVERLAPPED overlapped;
    memset(&overlapped, 0, sizeof(overlapped));
    overlapped.Offset = (DWORD)(offset & 0xFFFFFFFFll);
    overlapped.OffsetHigh = (DWORD)((offset >> 32) & 0xFFFFFFFFll);
    DWORD read_bytes = 0u;
    if (!ReadFile((HANDLE)handle, buffer, (DWORD)count, &read_bytes, &overlapped)) {
        windows_capture_reason(GetLastError(), NULL);
        return -1;
    }
    return (long long)read_bytes;
}

void pharos_capture_handle_close(intptr_t handle) {
    if (handle != (intptr_t)INVALID_HANDLE_VALUE && handle != 0) {
        CloseHandle((HANDLE)handle);
    }
}

/* 私有候选独占创建（CREATE_NEW + 不共享）。已存在即具名失败，不删除、不覆盖。 */
intptr_t pharos_capture_candidate_create(const char *path, int *out_reason) {
    if (out_reason) *out_reason = PHAROS_CAPTURE_OK;
    WCHAR *wide = windows_file_path_utf8(path);
    if (!wide) {
        if (out_reason) *out_reason = PHAROS_CAPTURE_BAD_PATH;
        return (intptr_t)INVALID_HANDLE_VALUE;
    }
    HANDLE handle = CreateFileW(wide, GENERIC_WRITE, 0u, NULL, CREATE_NEW,
        FILE_ATTRIBUTE_NORMAL, NULL);
    DWORD error = GetLastError();
    free(wide);
    if (handle == INVALID_HANDLE_VALUE) windows_capture_reason(error, out_reason);
    return (intptr_t)handle;
}

long long pharos_capture_candidate_write(intptr_t handle, const void *buffer, long long count) {
    if (handle == (intptr_t)INVALID_HANDLE_VALUE || !buffer) { errno = EINVAL; return -1; }
    if (count <= 0) return 0;
    if (count > 1024 * 1024) count = 1024 * 1024;
    DWORD written = 0u;
    if (!WriteFile((HANDLE)handle, buffer, (DWORD)count, &written, NULL)) {
        windows_capture_reason(GetLastError(), NULL);
        return -1;
    }
    if ((long long)written != count) { errno = ENOSPC; return -2; }
    return (long long)written;
}

/* 封存：刷盘 + 从候选自身句柄核验长度。长度不符不算成功，短写/刷盘失败具名返回。 */
int pharos_capture_candidate_seal(intptr_t handle, long long expected_length, int *out_reason) {
    if (out_reason) *out_reason = PHAROS_CAPTURE_OK;
    if (handle == (intptr_t)INVALID_HANDLE_VALUE) {
        if (out_reason) *out_reason = PHAROS_CAPTURE_IO;
        return -1;
    }
    if (!FlushFileBuffers((HANDLE)handle)) {
        windows_capture_reason(GetLastError(), out_reason);
        return -1;
    }
    LARGE_INTEGER size;
    size.QuadPart = 0;
    if (!GetFileSizeEx((HANDLE)handle, &size)) {
        windows_capture_reason(GetLastError(), out_reason);
        return -1;
    }
    if ((long long)size.QuadPart != expected_length) {
        errno = EIO;
        if (out_reason) *out_reason = PHAROS_CAPTURE_SHORT;
        return -1;
    }
    return 0;
}

/* 发布：候选→目标的一次原子替换。校验并封存后才允许调用。 */
int pharos_capture_candidate_publish(const char *candidate, const char *target, int *out_reason) {
    if (out_reason) *out_reason = PHAROS_CAPTURE_OK;
    WCHAR *from = windows_file_path_utf8(candidate);
    if (!from) { if (out_reason) *out_reason = PHAROS_CAPTURE_BAD_PATH; return -1; }
    WCHAR *to = windows_file_path_utf8(target);
    if (!to) {
        free(from);
        if (out_reason) *out_reason = PHAROS_CAPTURE_BAD_PATH;
        return -1;
    }
    BOOL ok = MoveFileExW(from, to, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
    DWORD error = GetLastError();
    free(from); free(to);
    if (!ok) { windows_capture_reason(error, out_reason); return -1; }
    return 0;
}

/* 只清理自己确实创建的候选；句柄已经关闭后才允许调用。 */
int pharos_capture_candidate_discard(const char *candidate) {
    WCHAR *wide = windows_file_path_utf8(candidate);
    if (!wide) return -1;
    BOOL ok = DeleteFileW(wide);
    DWORD error = GetLastError();
    free(wide);
    if (!ok && error != ERROR_FILE_NOT_FOUND) { windows_capture_reason(error, NULL); return -1; }
    return 0;
}
