-- LuaJIT 共享运行时：进程/文件/总线/niri IPC 查询。
-- status-readings.lua、resize-workspace、state.lua、single-instance.lua 共用；不直接执行。
local ffi = require("ffi")

ffi.cdef [[
int socket(int, int, int);
int connect(int, const void *, unsigned int);
long write(int, const char *, unsigned long);
long read(int, char *, unsigned long);
int close(int);

struct sockaddr_un {
    unsigned short sun_family;
    char sun_path[108];
};

typedef int pid_t;
int pipe(int[2]);
pid_t fork(void);
int execvp(const char *, char *const[]);
int dup2(int, int);
int waitpid(pid_t, int *, int);
void _exit(int);
int open(const char *, int, ...);
int flock(int, int);
int kill(pid_t, int);
long readlink(const char *, char *, unsigned long);
struct timespec { long tv_sec; long tv_nsec; };
int nanosleep(const struct timespec *, struct timespec *);
int access(const char *, int);
unsigned int getuid(void);

typedef struct __dirstream DIR;
DIR *opendir(const char *);
struct dirent {
    unsigned long d_ino;
    long d_off;
    unsigned short d_reclen;
    unsigned char d_type;
    char d_name[256];
};
struct dirent *readdir(DIR *);
int closedir(DIR *);
]]

local M = { ffi = ffi }

local O_RDONLY, O_WRONLY, O_CREAT = 0, 1, 64
local X_OK, F_OK = 1, 0
local LOCK_EX, LOCK_NB = 2, 4

local function close(fd)
    if fd >= 0 then ffi.C.close(fd) end
end

-- niri IPC：一行 JSON 请求，一行 JSON 回复。连接由模块持有，出错后关闭，
-- 下一次请求自动重连。成功返回 Ok 里的内容，失败返回 nil 和原因。
local AF_UNIX, SOCK_STREAM = 1, 1
local niri_fd

local function niri_close()
    if niri_fd then
        close(niri_fd)
        niri_fd = nil
    end
end

local function niri_connect()
    local path = os.getenv("NIRI_SOCKET")
    if not path or path == "" or #path >= 108 then
        return nil, "NIRI_SOCKET 未设置或路径太长"
    end

    local fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
    if fd < 0 then return nil, "socket() 失败" end

    local addr = ffi.new("struct sockaddr_un")
    addr.sun_family = AF_UNIX
    ffi.copy(addr.sun_path, path)
    local length = ffi.offsetof("struct sockaddr_un", "sun_path") + #path + 1
    if ffi.C.connect(fd, ffi.cast("const void *", addr), length) ~= 0 then
        close(fd)
        return nil, "connect " .. path .. " 失败"
    end

    niri_fd = fd
    return true
end

function M.niri_request(json)
    if not niri_fd then
        local ok, err = niri_connect()
        if not ok then return nil, err end
    end

    local req = json .. "\n"
    if ffi.C.write(niri_fd, req, #req) ~= #req then
        niri_close()
        return nil, "write 失败"
    end

    local chunks = {}
    local buf = ffi.new("char[4096]")
    while true do
        local n = ffi.C.read(niri_fd, buf, ffi.sizeof(buf))
        if n <= 0 then
            niri_close()
            return nil, "读取回复失败"
        end

        local chunk = ffi.string(buf, n)
        local newline = chunk:find("\n", 1, true)
        if newline then
            chunks[#chunks + 1] = chunk:sub(1, newline - 1)
            local reply = table.concat(chunks)
            local ok = reply:match('^{"Ok":(.*)}$')
            if ok then return ok end
            return nil, reply:match('^{"Err":(.*)}$') or reply
        end
        chunks[#chunks + 1] = chunk
    end
end

function M.niri_query(name)
    return M.niri_request('"' .. name .. '"')
end

function M.niri_close()
    niri_close()
end

-- 顶层 JSON 数组里的对象逐个切出来，跳过字符串里的括号和转义。
function M.json_objects(json)
    local result, depth, start, in_string, escaped = {}, 0, nil, false, false
    for i = 1, #json do
        local c = json:sub(i, i)
        if in_string then
            if escaped then escaped = false
            elseif c == "\\" then escaped = true
            elseif c == '"' then in_string = false end
        elseif c == '"' then
            in_string = true
        elseif c == "{" then
            depth = depth + 1
            if depth == 1 then start = i end
        elseif c == "}" then
            if depth == 1 then result[#result + 1] = json:sub(start, i) end
            depth = depth - 1
        end
    end
    return result
end

function M.readfile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local line = f:read("*l")
    f:close()
    return line
end

-- 软链接的目标（相对路径原样返回）。
function M.readlink(path)
    local buf = ffi.new("char[256]")
    local n = ffi.C.readlink(path, buf, 255)
    if n <= 0 then return nil end
    return ffi.string(buf, n)
end

function M.listdir(path)
    local entries = {}
    local dir = ffi.C.opendir(path)
    if dir == nil then return entries end
    while true do
        local ent = ffi.C.readdir(dir)
        if ent == nil then break end
        local name = ffi.string(ent.d_name)
        if name ~= "." and name ~= ".." then
            entries[#entries + 1] = name
        end
    end
    ffi.C.closedir(dir)
    return entries
end

-- fork/exec 一个命令：stdout 走管道，stdin/stderr 接 /dev/null。
-- 返回 pid 和管道读端；起不来返回 nil。
local function spawn(argv)
    local fds = ffi.new("int[2]")
    if ffi.C.pipe(fds) ~= 0 then return nil end

    local pid = ffi.C.fork()
    if pid < 0 then
        close(fds[0])
        close(fds[1])
        return nil
    end

    if pid == 0 then
        ffi.C.close(fds[0])
        local devnull = ffi.C.open("/dev/null", O_RDONLY)
        if devnull >= 0 and devnull ~= 0 then
            ffi.C.dup2(devnull, 0)
            ffi.C.close(devnull)
        end
        if fds[1] ~= 1 then
            ffi.C.dup2(fds[1], 1)
            ffi.C.close(fds[1])
        end
        local err = ffi.C.open("/dev/null", O_WRONLY)
        if err >= 0 and err ~= 2 then
            ffi.C.dup2(err, 2)
            ffi.C.close(err)
        end
        local n = #argv
        local cargs = ffi.new("char *[?]", n + 1)
        for i = 1, n do cargs[i - 1] = ffi.cast("char *", argv[i]) end
        cargs[n] = nil
        ffi.C.execvp(cargs[0], cargs)
        ffi.C._exit(127)
    end

    ffi.C.close(fds[1])
    return pid, fds[0]
end

-- 读到 EOF 为止。
local function read_all(fd)
    local chunks = {}
    local buf = ffi.new("char[4096]")
    while true do
        local n = ffi.C.read(fd, buf, ffi.sizeof(buf))
        if n <= 0 then break end
        chunks[#chunks + 1] = ffi.string(buf, n)
    end
    return table.concat(chunks)
end

-- 等子进程退出，返回 waitpid 的原始状态（0 表示成功）。
local function wait(pid)
    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    return status[0]
end

-- 一批命令同时起来：所有子进程先 fork 完，父进程再统一收 stdout、等退出。
-- 等待时间因此是最慢的那条命令，而不是所有命令的耗时之和。
-- 返回与 argvs 等长的列表，每项 { output = ..., status = ... }。
function M.run_all(argvs)
    local children = {}
    for i, argv in ipairs(argvs) do
        local pid, fd = spawn(argv)
        children[i] = { pid = pid, fd = fd, output = nil, status = -1 }
    end

    -- 逐个收 stdout：每条命令的输出都塞得进管道缓冲，
    -- 谁先写完谁先退出，不会互相等。
    for _, child in ipairs(children) do
        if child.pid then
            child.output = read_all(child.fd)
            close(child.fd)
            child.status = wait(child.pid)
        end
    end

    return children
end

-- fork/exec，stdout 走管道，stdin/stderr 接 /dev/null。
-- 返回 stdout 内容和 waitpid 的原始状态（0 表示成功）。
function M.run(argv)
    local result = M.run_all({ argv })[1]
    return result.output, result.status
end

function M.which(name)
    if name:find("/", 1, true) then
        return ffi.C.access(name, X_OK) == 0 and name or nil
    end
    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
    for dir in (path .. ":"):gmatch("([^:]*):") do
        if dir == "" then dir = "." end
        local candidate = dir .. "/" .. name
        if ffi.C.access(candidate, X_OK) == 0 then return candidate end
    end
    return nil
end

function M.recorder_path()
    local env = os.getenv("RECORDER_BIN")
    if env and env ~= "" then return env end
    return M.which("gpu-screen-recorder")
end

function M.owned(pid)
    local f = io.open("/proc/" .. pid .. "/status", "r")
    if not f then return false end
    local uid = ffi.C.getuid()
    for line in f:lines() do
        local value = line:match("^Uid:%s*(%d+)")
        if value then
            f:close()
            return tonumber(value) == uid
        end
    end
    f:close()
    return false
end

function M.pids_by_comm(name, owned_only)
    local pids = {}
    for _, entry in ipairs(M.listdir("/proc")) do
        if entry:match("^%d+$") then
            local f = io.open("/proc/" .. entry .. "/comm", "r")
            if f then
                local comm = f:read("*l")
                f:close()
                if comm == name and (not owned_only or M.owned(entry)) then
                    pids[#pids + 1] = tonumber(entry)
                end
            end
        end
    end
    return pids
end

-- 与 record state 的语义一致：BUSY > REC > IDLE，录制器不存在时返回 nil。
function M.recording_state(recorder)
    recorder = recorder or M.recorder_path()
    if not recorder or recorder == "" then return nil end

    local busy = false
    local lock = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/record.lock"
    -- open 是可变参数函数：Lua number 在 varargs 里按 double 传，mode 会变成 0，
    -- 锁文件因此不可写。这里必须显式传 int cdata。
    local fd = ffi.C.open(lock, O_WRONLY + O_CREAT, ffi.new("int", 420))
    if fd >= 0 then
        if ffi.C.flock(fd, LOCK_EX + LOCK_NB) ~= 0 then busy = true end
        ffi.C.close(fd)
    end
    -- 锁被占：stop 正在收尾旧进程，或 start 正在启动新录制。
    -- 两种都不该显示成可以再停一次的 REC。
    if busy then return "BUSY" end

    -- gsr 的 comm 被内核截断到 15 字节（"gpu-screen-reco"）。
    local comm = recorder:match("([^/]+)$") or recorder
    comm = comm:sub(1, 15)
    if #M.pids_by_comm(comm, true) > 0 then return "REC" end

    -- 与 do_state 的 [[ -e $RECORDER_BIN ]] 一致：路径不存在就不占面板一行。
    if ffi.C.access(recorder, F_OK) == 0 then return "IDLE" end
    return nil
end

function M.nanosleep(seconds)
    local sec = math.floor(seconds)
    local ts = ffi.new("struct timespec")
    ts.tv_sec = sec
    ts.tv_nsec = math.floor((seconds - sec) * 1000000000)
    ffi.C.nanosleep(ts, nil)
end

function M.exec(argv)
    local n = #argv
    local cargs = ffi.new("char *[?]", n + 1)
    for i = 1, n do cargs[i - 1] = ffi.cast("char *", argv[i]) end
    cargs[n] = nil
    ffi.C.execvp(cargs[0], cargs)
    io.stderr:write("exec failed: ", tostring(argv[1]), "\n")
    os.exit(127)
end

return M
