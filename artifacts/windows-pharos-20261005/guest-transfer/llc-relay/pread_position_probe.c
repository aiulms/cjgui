/* pread 位置语义探针：验证 pread 不改变 fd 当前位置。
 *
 * 测试文件内容 "0123456789ABCDEF"（16 字节）。
 * 期望（POSIX 语义）：
 *   pread(fd, buf, 4, 4) -> "4567"，位置仍为 0
 *   pread(fd, buf, 4, 0) -> "0123"，位置仍为 0
 *   随后位置读 read(fd, 4) -> "0123"（从位置 0 继续）
 * 现实现（_lseeki64+_read 不恢复位置）会：位置变 8 -> 变 4 -> read 从 4 读到 "4567"。
 * 输出行：pos_after_pread1 / pos_after_pread2 / read_after_preads / verdict
 */
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

long long pread(int fd, void *buffer, size_t count, long long offset);

int main(void) {
    const char *path = "C:\\cjgui-windows-w1\\pump-probe\\pread-test.bin";
    int fd = _open(path, _O_CREAT | _O_TRUNC | _O_RDWR | _O_BINARY, _S_IREAD | _S_IWRITE);
    if (fd < 0) { printf("open_fail\n"); return 2; }
    const char *content = "0123456789ABCDEF";
    _write(fd, content, 16);
    _lseeki64(fd, 0, SEEK_SET);
    char buf[16];
    memset(buf, 0, sizeof(buf));
    long long got1 = pread(fd, buf, 4, 4);
    long long pos1 = _lseeki64(fd, 0, SEEK_CUR);
    printf("pread1 got=%lld data=%.4s pos_after_pread1=%lld\n", got1, buf, pos1);
    memset(buf, 0, sizeof(buf));
    long long got2 = pread(fd, buf, 4, 0);
    long long pos2 = _lseeki64(fd, 0, SEEK_CUR);
    printf("pread2 got=%lld data=%.4s pos_after_pread2=%lld\n", got2, buf, pos2);
    memset(buf, 0, sizeof(buf));
    int got3 = _read(fd, buf, 4);
    printf("read_after_preads got=%d data=%.4s\n", got3, buf);
    int ok = (pos1 == 0) && (pos2 == 0) && (got3 == 4) && (memcmp(buf, "0123", 4) == 0);
    printf("verdict=%s\n", ok ? "POSITION_PRESERVED" : "POSITION_BROKEN");
    _close(fd);
    return ok ? 0 : 1;
}
