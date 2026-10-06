// Windows 上的 POSIX 兼容垫片：为链接期仍引用以下符号的已编译对象提供
// 最小、语义等价的实现。它们只做平台转换（CRT/MoveFileEx），不携带业务。
// - fsync  -> CRT _commit（把文件缓冲刷到磁盘）
// - pread  -> _lseeki64 + _read + 位置恢复（保持 POSIX“读后位置不变”语义；
//              不依赖调用方是否只用绝对偏移，共享句柄上的位置读不会被污染）
// - renameat -> MoveFileExA（调用方使用绝对路径；目录 fd 在 Windows 无对应物）
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <io.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>

int fsync(int fd) {
    return _commit(fd) == 0 ? 0 : -1;
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
    if (MoveFileExA(oldPath, newPath, MOVEFILE_REPLACE_EXISTING)) return 0;
    errno = EACCES;
    return -1;
}
