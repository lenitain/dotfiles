#!/usr/bin/luajit
-- record / idle-inhibit 的 state 快速路径；供两个 bash 脚本和 status 共用。
local dir = arg[0]:match("^(.*)/") or "."
package.path = dir .. "/?.lua;" .. package.path
local lib = require("lib")

local command = arg[1]

if command == "record" then
    local state = lib.recording_state(os.getenv("RECORDER_BIN"))
    if not state then os.exit(1) end
    print(state)
elseif command == "idle" then
    local state = lib.idle_state()
    if not state then os.exit(1) end
    print(state)
else
    io.stderr:write("用法: state.lua record|idle\n")
    os.exit(2)
end
