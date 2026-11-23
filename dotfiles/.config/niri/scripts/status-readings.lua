#!/usr/bin/luajit
-- status 的读数层：一次进程里直连 niri、读 sysfs、查 UPower/logind，
-- 只把 wpctl / fcitx5-remote / ddcutil 留给外部命令。
local dir = arg[0]:match("^(.*)/") or "."
package.path = dir .. "/?.lua;" .. package.path

local ffi = require("ffi")
local lib = require("lib")

os.setlocale("C", "time")

local ICON = {
    clock = "󰥔",
    brightness = "󰖨",
    language = "󰗊",
    monitor = "󰍹",
    record = "󰑊",
    video = "󰕧",
    workspace = "󰀻",
    volume = "󰕾",
    volume_zero = "󰕿",
    mute = "󰖁",
    battery = { "󰁺", "󰁼", "󰁾", "󰂀", "󰂂" },
    charging = "󰂄",
}

local rows = {}

local function add(reading, action)
    if reading and reading ~= "" then
        rows[#rows + 1] = reading .. "\t" .. (action or "")
    end
end

-- niri IPC：一行 JSON 请求，一行 JSON 回复。
local niri_fd

local function niri_connect()
    local path = os.getenv("NIRI_SOCKET")
    if not path or path == "" or #path >= 108 then return nil end

    local fd = ffi.C.socket(1, 1, 0)
    if fd < 0 then return nil end

    local addr = ffi.new("struct sockaddr_un")
    addr.sun_family = 1
    ffi.copy(addr.sun_path, path)
    local length = ffi.offsetof("struct sockaddr_un", "sun_path") + #path + 1
    if ffi.C.connect(fd, ffi.cast("const void *", addr), length) ~= 0 then
        ffi.C.close(fd)
        return nil
    end
    return fd
end

local function niri_request(name)
    if not niri_fd then niri_fd = niri_connect() end
    if not niri_fd then return nil end

    local req = '"' .. name .. '"\n'
    if ffi.C.write(niri_fd, req, #req) ~= #req then
        ffi.C.close(niri_fd)
        niri_fd = nil
        return nil
    end

    local chunks = {}
    local buf = ffi.new("char[4096]")
    while true do
        local n = ffi.C.read(niri_fd, buf, ffi.sizeof(buf))
        if n <= 0 then
            ffi.C.close(niri_fd)
            niri_fd = nil
            return nil
        end
        local chunk = ffi.string(buf, n)
        local newline = chunk:find("\n", 1, true)
        if newline then
            chunks[#chunks + 1] = chunk:sub(1, newline - 1)
            local reply = table.concat(chunks)
            return reply:match('^{"Ok":(.*)}$')
        end
        chunks[#chunks + 1] = chunk
    end
end

-- 顶层 JSON 数组里的对象逐个切出来，跳过字符串里的括号和转义。
local function objects(json)
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

local function niri_outputs()
    local payload = niri_request("Outputs")
    if not payload then return nil end
    local body = payload:match('^{"Outputs":(.*)}$')
    if not body then return nil end

    local outputs = {}
    for name, value in body:gmatch('"([^"]+)":(%b{})') do
        local logical = value:match('"logical":(%b{})')
        if logical then
            outputs[#outputs + 1] = {
                name = name,
                x = tonumber(logical:match('"x":([%d%.%-]+)')) or 0,
                y = tonumber(logical:match('"y":([%d%.%-]+)')) or 0,
            }
        end
    end
    table.sort(outputs, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    return outputs
end

local function niri_workspaces()
    local payload = niri_request("Workspaces")
    if not payload then return nil end
    local body = payload:match('^{"Workspaces":(.*)}$')
    if not body then return nil end

    local indices, current = {}, nil
    for _, object in ipairs(objects(body)) do
        local idx = tonumber(object:match('"idx":(%d+)'))
        if idx then
            indices[#indices + 1] = idx
            if object:find('"is_focused":true', 1, true) then current = idx end
        end
    end
    table.sort(indices)
    if #indices == 0 or not current then return nil end
    return indices, current
end

-- 电量：AC 直接读 sysfs；百分比优先走 UPower（sysfs capacity 在空闲后要 ~85ms）。
local function power_state()
    local battery, ac = nil, false
    for _, name in ipairs(lib.listdir("/sys/class/power_supply")) do
        local base = "/sys/class/power_supply/" .. name
        local kind = lib.readfile(base .. "/type")
        if kind == "Battery" and not battery then
            battery = name
        elseif kind == "Mains" or kind == "USB" then
            if lib.readfile(base .. "/online") == "1" then ac = true end
        end
    end
    return battery, ac
end

local function upower_percentage(path)
    local out, status = lib.run({
        "busctl", "--system", "get-property",
        "org.freedesktop.UPower", path,
        "org.freedesktop.UPower.Device", "Percentage",
    })
    if status ~= 0 or not out then return nil end
    return tonumber(out:match("^d%s+([%d%.]+)"))
end

local function battery_percentage(battery)
    local path = "/org/freedesktop/UPower/devices/battery_" .. battery
    local pct = upower_percentage(path)
    if pct then return pct end

    -- 设备路径不是固定命名时，枚举一次再取。
    local out, status = lib.run({
        "busctl", "--system", "call",
        "org.freedesktop.UPower", "/org/freedesktop/UPower",
        "org.freedesktop.UPower", "EnumerateDevices",
    })
    if status == 0 and out then
        for candidate in out:gmatch('"([^"]+/battery_[^"]+)"') do
            pct = upower_percentage(candidate)
            if pct then return pct end
        end
    end

    -- UPower 不可用时退回 sysfs；慢，但至少正确。
    return tonumber(lib.readfile("/sys/class/power_supply/" .. battery .. "/capacity"))
end

local function battery_row()
    local battery, ac = power_state()
    if not battery then return nil end
    local pct = battery_percentage(battery)
    if not pct then return nil end
    pct = math.floor(pct)

    local icon
    if ac then
        icon = ICON.charging
    else
        local index = math.floor(pct * 5 / 101)
        if index > 4 then index = 4 end
        icon = ICON.battery[index + 1]
    end
    return string.format("%s  %d%%", icon, pct)
end

local function backlight_percentages()
    local names = lib.listdir("/sys/class/backlight")
    table.sort(names)
    local percentages = {}
    for _, name in ipairs(names) do
        local base = "/sys/class/backlight/" .. name
        local current = tonumber(lib.readfile(base .. "/brightness"))
        local maximum = tonumber(lib.readfile(base .. "/max_brightness"))
        if current and maximum and maximum > 0 then
            percentages[#percentages + 1] = math.floor(current * 100 / maximum)
        end
    end
    return percentages
end

local function is_internal(name)
    return name:match("^eDP") or name:match("^LVDS") or name:match("^DSI")
end

-- 外接屏的 DDC/CI 总线：detect 输出里 Invalid display 的段跳过。
local function ddc_buses()
    local out, _ = lib.run({ "timeout", "2", "ddcutil", "detect", "--brief" })
    if not out then return {} end

    local buses, valid, bus = {}, false, nil
    for line in out:gmatch("[^\n]+") do
        if line:match("^Invalid display") then
            valid = false
        elseif line:match("^Display ") then
            valid = true
        else
            -- --bus 只收总线号；detect 报的是 /dev/i2c-N 设备路径，原样传会被拒绝
            local parsed_bus = line:match("^%s*I2C bus:%s*/dev/i2c%-(%d+)")
            if parsed_bus then bus = parsed_bus end
            local connector = line:match("^%s*DRM connector:%s*(%S+)")
            if connector then
                connector = connector:gsub("^card%d+%-", "")
                if valid and bus then buses[connector] = bus end
            end
        end
    end
    return buses
end

local function ddc_percentage(bus)
    if not bus or bus == "" then return nil end
    -- 0x10 = Brightness；ddcutil 的 feature code 一律按十六进制解析
    local out, status = lib.run({
        "timeout", "1", "ddcutil", "getvcp", "10", "--bus", bus,
    })
    if status ~= 0 or not out then return nil end

    local current = tonumber(out:match("current value%s*=%s*(%d+)"))
    local maximum = tonumber(out:match("max value%s*=%s*(%d+)"))
    if not current or not maximum or maximum == 0 then return nil end
    return math.floor(current * 100 / maximum)
end

local function brightness_rows()
    local outputs = niri_outputs()
    local backlights = backlight_percentages()

    if not outputs or #outputs == 0 then
        if #backlights == 0 then return {} end
        return { string.format("%s  %d%%", ICON.brightness, backlights[1]) }
    end

    local external = false
    for _, output in ipairs(outputs) do
        if not is_internal(output.name) then
            external = true
            break
        end
    end
    local buses = external and ddc_buses() or {}

    local result, slot = {}, 0
    for _, output in ipairs(outputs) do
        local pct
        if is_internal(output.name) then
            slot = slot + 1
            pct = backlights[slot]
        else
            pct = ddc_percentage(buses[output.name])
        end
        if pct then
            result[#result + 1] = string.format(
                "%s  %d%% %s", ICON.brightness, pct, output.name)
        end
    end
    return result
end

local function volume_row()
    local out, status = lib.run({
        "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@",
    })
    if status ~= 0 or not out then return nil end
    if out:find("MUTED", 1, true) then return ICON.mute .. "  Muted" end

    local whole, fraction = out:match("Volume:%s*(%d+)%.(%d+)")
    if not whole then return nil end
    local pct = math.floor(
        tonumber(whole) * 100 + tonumber(fraction) * 10 ^ (2 - #fraction))
    if pct == 0 then return ICON.volume_zero .. "  0%" end
    return string.format("%s  %d%%", ICON.volume, pct)
end

local function ime_row()
    local out, status = lib.run({ "fcitx5-remote" })
    if status ~= 0 or not out then return nil end
    out = out:gsub("%s+", "")
    return ICON.language .. "  " .. (out == "2" and "ZH" or "EN")
end

local function workspaces_row()
    local indices, current = niri_workspaces()
    if not indices or not current then return nil end

    local numbers = {}
    for _, idx in ipairs(indices) do
        numbers[#numbers + 1] = idx == current
            and ("[" .. idx .. "]") or tostring(idx)
    end
    return ICON.workspace .. "  " .. table.concat(numbers, " ")
end

local function recording_row()
    local state = lib.recording_state(lib.recorder_path())
    if not state then return nil end
    local icon = state == "REC" and ICON.record or ICON.video
    return icon .. "  " .. state
end

local function idle_row()
    local state = lib.idle_state()
    if not state then return nil end
    return ICON.monitor .. "  " .. state
end

local function clock_row()
    return ICON.clock .. "  " .. os.date("%m-%d %a %H:%M")
end

add(recording_row(), "record")
add(idle_row(), "idle")
add(battery_row())
for _, reading in ipairs(brightness_rows()) do add(reading) end
add(volume_row(), "volume")
add(ime_row(), "ime")
add(workspaces_row())
add(clock_row())

if niri_fd then
    ffi.C.close(niri_fd)
    niri_fd = nil
end

io.write(table.concat(rows, "\n"))
if #rows > 0 then io.write("\n") end
