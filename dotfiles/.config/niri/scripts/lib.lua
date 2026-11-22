-- LuaJIT 共享运行时：进程/文件/总线查询。
-- status-readings.lua、state.lua、single-instance.lua 共用；不直接执行。
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

function M.readfile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local line = f:read("*l")
    f:close()
    return line
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

-- fork/exec，stdout 走管道，stdin/stderr 接 /dev/null。
-- 返回 stdout 内容和 waitpid 的原始状态（0 表示成功）。
function M.run(argv)
    local fds = ffi.new("int[2]")
    if ffi.C.pipe(fds) ~= 0 then return nil, -1 end

    local pid = ffi.C.fork()
    if pid < 0 then
        close(fds[0])
        close(fds[1])
        return nil, -1
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
    local chunks = {}
    local buf = ffi.new("char[4096]")
    while true do
        local n = ffi.C.read(fds[0], buf, ffi.sizeof(buf))
        if n <= 0 then break end
        chunks[#chunks + 1] = ffi.string(buf, n)
    end
    ffi.C.close(fds[0])

    local status = ffi.new("int[1]")
    ffi.C.waitpid(pid, status, 0)
    return table.concat(chunks), status[0]
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

-- 与 record state 的语义一致：REC > BUSY > IDLE，录制器不存在时返回 nil。
function M.recording_state(recorder)
    recorder = recorder or M.recorder_path()
    if not recorder or recorder == "" then return nil end

    -- gsr 的 comm 被内核截断到 15 字节（"gpu-screen-reco"）。
    local comm = recorder:match("([^/]+)$") or recorder
    comm = comm:sub(1, 15)
    local pids = M.pids_by_comm(comm, true)
    if #pids > 0 then return "REC" end

    local busy = false
    local lock = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/record.lock"
    local fd = ffi.C.open(lock, O_WRONLY + O_CREAT, 420)
    if fd >= 0 then
        if ffi.C.flock(fd, LOCK_EX + LOCK_NB) ~= 0 then busy = true end
        ffi.C.close(fd)
    end
    if busy then return "BUSY" end

    -- 与 do_state 的 [[ -e $RECORDER_BIN ]] 一致：路径不存在就不占面板一行。
    if ffi.C.access(recorder, F_OK) == 0 then return "IDLE" end
    return nil
end

-- 与 idle-inhibit state 的语义一致：查询失败返回 nil，不把“查不到”当成 off。
function M.idle_state()
    local out, status = M.run({
        "busctl", "--system", "call",
        "org.freedesktop.login1", "/org/freedesktop/login1",
        "org.freedesktop.login1.Manager", "ListInhibitors",
    })
    if status ~= 0 or not out then return nil end
    return out:find('"idle" "idle-inhibit" "', 1, true) and "on" or "off"
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
