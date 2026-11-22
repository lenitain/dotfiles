-- 单实例包装器的共享实现：先杀旧进程，等它真的退出，再 exec 新进程。
-- fuzzel-wrapper / slurp-wrapper 只负责传入程序和默认 profile 策略。
local lib = require("lib")

local M = {}

function M.run(program, default_config)
    local name = program:match("([^/]+)$") or program
    local pids = lib.pids_by_comm(name)
    local signaled = {}

    for _, pid in ipairs(pids) do
        -- 别的用户的进程 kill 会 EPERM；不要等它，也别把新实例拖住。
        if lib.ffi.C.kill(pid, 15) == 0 then
            signaled[#signaled + 1] = pid
        end
    end

    for _, pid in ipairs(signaled) do
        for _ = 1, 100 do
            if lib.ffi.C.kill(pid, 0) ~= 0 then break end
            lib.nanosleep(0.001)
        end
    end

    local argv = { program }
    if default_config then
        local has_config = false
        for i = 1, #arg do
            local value = arg[i]
            if value == "--config" or value:match("^%-%-config=") then
                has_config = true
                break
            end
        end
        if not has_config then
            local base = os.getenv("XDG_CONFIG_HOME")
            if not base or base == "" then
                local home = os.getenv("HOME")
                if home and home ~= "" then base = home .. "/.config" end
            end
            if base then
                argv[#argv + 1] = "--config=" .. base .. "/fuzzel/launcher.ini"
            end
        end
    end
    for i = 1, #arg do argv[#argv + 1] = arg[i] end

    lib.exec(argv)
end

return M
