// qb-open: qutebrowser 快速客户端（毫秒级）。
//
// 直接向常驻实例（qb-server）的 IPC socket 写 JSON，不启动 Python/Qt。
// 无参数 = 按配置 new_instance_open_target（默认 tab）打开，无窗口则新建。
// 常驻 server 未运行（socket 不存在/连不上）时回退 exec qutebrowser 冷启动。
//
// socket 路径: $XDG_RUNTIME_DIR/qutebrowser/ipc-*（逐个尝试目录下的 socket，用第一个
// 连上的，不依赖 qutebrowser 的 md5(用户名) 命名算法，将来算法变更也不受影响）
//
// 构建（静态 musl，零运行时依赖）:
//   musl-gcc -O2 -Wall -Wextra -static -o qb-open qb-open.c
//
// 用法: qb-open [URL...]

#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

extern char **environ;

// 冷启动兜底的目标；这个程序只为 qutebrowser 服务，不看 $BROWSER
#define QUTEBROWSER_PATH "/usr/bin/qutebrowser"

// 严格 UTF-8 校验：拒绝过长编码、代理区和 > U+10FFFF 的码点。
//
// 存在的理由：JSON 文本必须是合法 UTF-8，而服务端拿到后先 data.decode('utf-8') 再
// json.loads（misc/ipc.py），解码失败就整包丢弃、只在日志里留一行。那时客户端已经
// write 成功，会当成"发送成功"返回 0——URL 静默不打开，比慢一点糟糕得多。非 UTF-8 的
// 参数（Latin-1 文件名之类）在 Linux 上真会出现，交给冷启动的 Python 客户端处理，
// 它用 surrogateescape + ensure_ascii 能原样送到。
static int utf8_valid(const char *s) {
    const unsigned char *p = (const unsigned char *)s;
    while (*p) {
        unsigned char c = *p++;
        if (c < 0x80) continue;
        int extra;
        unsigned int cp;
        if (c >= 0xc2 && c <= 0xdf) {
            extra = 1;
            cp = c & 0x1f;
        } else if (c >= 0xe0 && c <= 0xef) {
            extra = 2;
            cp = c & 0x0f;
        } else if (c >= 0xf0 && c <= 0xf4) {
            extra = 3;
            cp = c & 0x07;
        } else {
            return 0;  // 0x80-0xc1 是多余的首字节，0xf5-0xff 永远非法
        }
        for (int i = 0; i < extra; i++) {
            if ((*p & 0xc0) != 0x80) return 0;  // 截断处会撞上 NUL，一并拒掉
            cp = (cp << 6) | (*p++ & 0x3f);
        }
        if (extra == 2 && (cp < 0x800 || (cp >= 0xd800 && cp <= 0xdfff))) return 0;
        if (extra == 3 && (cp < 0x10000 || cp > 0x10ffff)) return 0;
    }
    return 1;
}

// JSON 字符串转义，追加到缓冲区
static int json_append(char *buf, size_t *pos, size_t cap, const char *s) {
    if (!utf8_valid(s)) return -1;
    if (*pos >= cap) return -1;
    buf[(*pos)++] = '"';
    for (; *s; s++) {
        if (*pos >= cap) return -1;
        switch (*s) {
            case '"':
                if (*pos + 2 > cap) return -1;
                buf[(*pos)++] = '\\';
                buf[(*pos)++] = '"';
                break;
            case '\\':
                if (*pos + 2 > cap) return -1;
                buf[(*pos)++] = '\\';
                buf[(*pos)++] = '\\';
                break;
            case '\n':
                if (*pos + 2 > cap) return -1;
                buf[(*pos)++] = '\\';
                buf[(*pos)++] = 'n';
                break;
            case '\r':
                if (*pos + 2 > cap) return -1;
                buf[(*pos)++] = '\\';
                buf[(*pos)++] = 'r';
                break;
            case '\t':
                if (*pos + 2 > cap) return -1;
                buf[(*pos)++] = '\\';
                buf[(*pos)++] = 't';
                break;
            default:
                if (*s >= 0x00 && *s <= 0x1f) {
                    int n = snprintf(buf + *pos, cap - *pos, "\\u%04x", (unsigned char)*s);
                    if (n < 0 || (size_t)n >= cap - *pos) return -1;
                    *pos += (size_t)n;
                } else {
                    buf[(*pos)++] = *s;
                }
        }
    }
    if (*pos >= cap) return -1;
    buf[(*pos)++] = '"';
    return 0;
}

// 追加一段不需要转义的固定文本，与 json_append 共用同一个上限。
//
// 存在的理由：snprintf 返回的是"本该写入的长度"，被截断时它比实际写入的多。
// 直接把这个返回值加进偏移量，pos 就会冲过缓冲区末尾，紧接着 `sizeof(buf) - pos`
// 下溢成 SIZE_MAX，再往后每一次写入都落在数组之外。宁可写这么个小函数。
static int literal_append(char *buf, size_t *pos, size_t cap, const char *s) {
    if (*pos > cap) return -1;
    size_t len = strlen(s);
    if (len > cap - *pos) return -1;
    memcpy(buf + *pos, s, len);
    *pos += len;
    return 0;
}

// 连接 $XDG_RUNTIME_DIR/qutebrowser/ 下的 ipc-* socket，返回第一个连上的 fd，
// 一个都连不上则返回 -1。
//
// 不能只挑第一个文件：目录里可能有崩溃实例残留的死 socket，也可能有多个 ipc-*
// （名字是 md5(getpass.getuser() + basedir)，而 getpass.getuser() 先看 LOGNAME/USER，
// systemd 拉起的常驻实例和交互式启动的算出来未必同名）。挑错了就得走冷启动，而冷启动
// 的 qutebrowser 自己算名字，未必连得上常驻实例——那就真多起一个浏览器了。
static int connect_socket(const char *runtime_dir) {
    char dir[PATH_MAX];
    int n = snprintf(dir, sizeof(dir), "%s/qutebrowser", runtime_dir);
    if (n < 0 || (size_t)n >= sizeof(dir)) return -1;

    DIR *d = opendir(dir);
    if (!d) return -1;

    int fd = -1;
    struct dirent *ent;
    while (fd < 0 && (ent = readdir(d)) != NULL) {
        if (strncmp(ent->d_name, "ipc-", 4) != 0) continue;

        struct sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        int m = snprintf(addr.sun_path, sizeof(addr.sun_path), "%s/%s", dir, ent->d_name);
        if (m < 0 || (size_t)m >= sizeof(addr.sun_path)) continue;  // 长得连不上，跳过
        socklen_t addr_len = (socklen_t)(offsetof(struct sockaddr_un, sun_path) + (size_t)m);

        int candidate = socket(AF_UNIX, SOCK_STREAM, 0);
        if (candidate < 0) break;
        if (connect(candidate, (struct sockaddr *)&addr, addr_len) == 0) {
            fd = candidate;
        } else {
            close(candidate);
        }
    }

    closedir(d);
    return fd;
}

// 写全整个消息。服务端按 \n 分行读，短写等于发了一条永远不会被解析的半行 JSON，
// 所以这里不许半途而废：8KB 在 AF_UNIX 上几乎不会短写，真短写了也只能回退冷启动。
static int write_all(int fd, const char *buf, size_t len) {
    while (len > 0) {
        ssize_t n = write(fd, buf, len);
        if (n < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (n == 0) return -1;
        buf += n;
        len -= (size_t)n;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    // 回退 exec 用的 argv
    char **exec_argv = malloc(((size_t)argc + 1) * sizeof(char *));
    if (!exec_argv) goto fallback;
    exec_argv[0] = QUTEBROWSER_PATH;
    for (int i = 1; i < argc; i++) exec_argv[i] = argv[i];
    exec_argv[argc] = NULL;

    // 运行时目录。XDG_RUNTIME_DIR 被 launcher 剥掉时按 uid 猜 /run/user/N——上游这时会退到
    // TempLocation，猜不准，但猜错只多一次失败的 opendir，猜对就省掉一次冷启动。
    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    char runtime_buf[64];
    if (!runtime_dir || !*runtime_dir) {
        snprintf(runtime_buf, sizeof(runtime_buf), "/run/user/%d", getuid());
        runtime_dir = runtime_buf;
    }

    // 组装 JSON 消息。正文一律走 json_append / literal_append，上限统一为
    // sizeof(json) - 2 —— 剩下 2 字节留给收尾的 "}\n"，于是 pos 永远不会越界。
    static char json[8192];
    const size_t cap = sizeof(json) - 2;
    size_t pos = 0;
    if (literal_append(json, &pos, cap, "{\"args\":[") < 0) goto fallback;
    if (argc > 1) {
        for (int i = 1; i < argc; i++) {
            if (i > 1) {
                if (pos >= cap) goto fallback;
                json[pos++] = ',';
            }
            if (json_append(json, &pos, cap, argv[i]) < 0) goto fallback;
        }
    } else {
        if (literal_append(json, &pos, cap, "\"\"") < 0) goto fallback;
    }
    // 追加 target_arg, version, protocol_version
    if (literal_append(json, &pos, cap,
        "],\"target_arg\":null,\"version\":\"3.7.0\",\"protocol_version\":1") < 0) goto fallback;

    // 追加 cwd
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd))) {
        if (literal_append(json, &pos, cap, ",\"cwd\":") < 0) goto fallback;
        if (json_append(json, &pos, cap, cwd) < 0) goto fallback;
    }
    // 上面两个函数成功返回时保证 pos <= cap，这 2 字节一定放得下
    json[pos++] = '}';
    json[pos++] = '\n';

    // 连接 IPC socket 并发送。fd 用完立刻关，绝不留给 fallback 里 execve 出来的浏览器。
    // 服务端可能在收到之前就断开（超时、:restart），那样 write 会带着 EPIPE 和 SIGPIPE
    // 回来，而默认动作是当场把 qb-open 打死——死了就没有回退了，所以先忽略 SIGPIPE。
    signal(SIGPIPE, SIG_IGN);

    int fd = connect_socket(runtime_dir);
    if (fd < 0) goto fallback;

    int err = write_all(fd, json, pos);
    close(fd);
    if (err < 0) goto fallback;

    free(exec_argv);
    return 0;

fallback:
    // 冷启动：先绝对路径（避开 PATH 劫持），再交给 PATH 查找（pipx/mise 之类的安装
    // 方式未必落在 /usr/bin）。两条都失败就只剩报错——静默返回只会让调用者以为
    // "什么都没发生"，比退出码难看也没关系。
    execve(QUTEBROWSER_PATH, exec_argv ? exec_argv : argv, environ);
    execvp("qutebrowser", exec_argv ? exec_argv : argv);
    fprintf(stderr, "qb-open: 无法启动 qutebrowser (%s): %s\n",
            QUTEBROWSER_PATH, strerror(errno));
    free(exec_argv);
    return 127;
}
