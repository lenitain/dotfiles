#!/usr/bin/luajit
-- status 的读数层：一次进程里直连 niri、读 sysfs、查 UPower/logind，
-- 只把 wpctl / fcitx5-remote / ddcutil 留给外部命令。
--
-- 外部命令全部同时发起，面板的等待时间因此是最慢的那条命令，
-- 而不是所有命令的耗时之和。
local dir = arg[0]:match("^(.*)/") or "."
package.path = dir .. "/?.lua;" .. package.path

local lib = require("lib")

os.setlocale("C", "time")

local ICON = {
    clock = "󰥔",
    brightness = "󰖨",
    language = "󰗊",
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

local function niri_outputs()
    local payload = lib.niri_query("Outputs")
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

-- 工作区按 output 分组：idx 是该 output 上的序号，不同 output 可以重复。
-- output 为 null 表示这个工作区当前没有屏承载。
local function niri_workspaces()
    local payload = lib.niri_query("Workspaces")
    if not payload then return nil end
    local body = payload:match('^{"Workspaces":(.*)}$')
    if not body then return nil end

    local workspaces = {}
    for _, object in ipairs(lib.json_objects(body)) do
        local idx = tonumber(object:match('"idx":(%d+)'))
        if idx then
            workspaces[#workspaces + 1] = {
                idx = idx,
                output = object:match('"output":"([^"]*)"'),
                focused = object:find('"is_focused":true', 1, true) ~= nil,
            }
        end
    end
    return workspaces
end

-- 聚焦输出：当前持有键盘焦点的屏。focus-follows-mouse 关着时只随点击切换。
local function niri_focused_output()
    local payload = lib.niri_query("FocusedOutput")
    if not payload then return nil end
    local body = payload:match('^{"FocusedOutput":(.*)}$')
    if not body then return nil end
    return body:match('"name":"([^"]*)"')
end

local function is_internal(name)
    return name:match("^eDP") or name:match("^LVDS") or name:match("^DSI")
end

-- DDC/CI 总线号：DRM 连接器的 ddc 软链接指向 i2c-N。
-- ddcutil detect 得到的是同一个号，但它要逐条总线探测，慢一个数量级。
local function ddc_bus(connector)
    for _, entry in ipairs(lib.listdir("/sys/class/drm")) do
        local card, name = entry:match("^(card%d+)%-(.+)$")
        if card and name == connector then
            local target = lib.readlink("/sys/class/drm/" .. entry .. "/ddc")
            local bus = target and target:match("i2c%-(%d+)$")
            if bus then return tonumber(bus) end
        end
    end
    return nil
end

-- 内置屏的 sysfs 背光。
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

-- 电量的两个电源：电池与市电。
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

-- UPower 的电量百分比。
local function upower_query(path)
    return {
        "busctl", "--system", "get-property",
        "org.freedesktop.UPower", path,
        "org.freedesktop.UPower.Device", "Percentage",
    }
end

local function upower_percentage(out, status)
    if status ~= 0 or not out then return nil end
    return tonumber(out:match("^d%s+([%d%.]+)"))
end

-- ddcutil getvcp 的输出：current value = 47, max value = 100
local function ddc_percentage(out, status)
    if status ~= 0 or not out then return nil end
    local current = tonumber(out:match("current value%s*=%s*(%d+)"))
    local maximum = tonumber(out:match("max value%s*=%s*(%d+)"))
    if not current or not maximum or maximum == 0 then return nil end
    return math.floor(current * 100 / maximum)
end

-- 外部探测：每条命令一次 fork/exec。
-- 名字只是取结果的 key，同一条读数一个名字。
local function probe(name, argv)
    return { name = name, argv = argv }
end

local function battery_row(results, battery, ac)
    if not battery then return nil end

    local result = results.battery
    local pct = result and upower_percentage(result.output, result.status)

    -- 设备路径不是固定命名时，枚举一次再取。
    if not pct then
        local out, status = lib.run({
            "busctl", "--system", "call",
            "org.freedesktop.UPower", "/org/freedesktop/UPower",
            "org.freedesktop.UPower", "EnumerateDevices",
        })
        if status == 0 and out then
            for candidate in out:gmatch('"([^"]+/battery_[^"]+)"') do
                pct = upower_percentage(lib.run(upower_query(candidate)))
                if pct then break end
            end
        end
    end

    -- UPower 不可用时退回 sysfs；慢，但至少正确。
    if not pct then
        pct = tonumber(lib.readfile("/sys/class/power_supply/" .. battery .. "/capacity"))
    end
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

-- 亮度：内置屏读 sysfs，外部屏读 DDC/CI 的结果。
local function brightness_rows(outputs, backlights, results)
    if #outputs == 0 then
        if #backlights == 0 then return {} end
        return { string.format("%s  %d%%", ICON.brightness, backlights[1]) }
    end

    local readings, slot = {}, 0
    for _, output in ipairs(outputs) do
        local pct
        if is_internal(output.name) then
            slot = slot + 1
            pct = backlights[slot]
        else
            local result = results["brightness:" .. output.name]
            if result then
                pct = ddc_percentage(result.output, result.status)
            end
        end
        if pct then
            readings[#readings + 1] = string.format(
                "%s  %d%% %s", ICON.brightness, pct, output.name)
        end
    end
    return readings
end

local function volume_row(result)
    if not result or result.status ~= 0 or not result.output then return nil end
    local out = result.output
    if out:find("MUTED", 1, true) then return ICON.mute .. "  Muted" end

    local whole, fraction = out:match("Volume:%s*(%d+)%.(%d+)")
    if not whole then return nil end
    local pct = math.floor(
        tonumber(whole) * 100 + tonumber(fraction) * 10 ^ (2 - #fraction))
    if pct == 0 then return ICON.volume_zero .. "  0%" end
    return string.format("%s  %d%%", ICON.volume, pct)
end

local function ime_row(result)
    if not result or result.status ~= 0 or not result.output then return nil end
    local out = result.output:gsub("%s+", "")
    return ICON.language .. "  " .. (out == "2" and "ZH" or "EN")
end

-- 只列聚焦输出上的工作区：idx 是屏内序号，所有屏混在一起会重复。
local function workspaces_row(focused_output, workspaces)
    if not focused_output then return nil end

    local on_output = {}
    for _, workspace in ipairs(workspaces) do
        if workspace.output == focused_output then
            on_output[#on_output + 1] = workspace
        end
    end
    if #on_output == 0 then return nil end
    table.sort(on_output, function(a, b) return a.idx < b.idx end)

    local numbers = {}
    for _, workspace in ipairs(on_output) do
        numbers[#numbers + 1] = workspace.focused
            and ("[" .. workspace.idx .. "]") or tostring(workspace.idx)
    end
    return ICON.workspace .. "  " .. table.concat(numbers, " ")
end

local function recording_row()
    local state = lib.recording_state(lib.recorder_path())
    if not state then return nil end
    local icon = state == "REC" and ICON.record or ICON.video
    return icon .. "  " .. state
end

local function clock_row()
    return ICON.clock .. "  " .. os.date("%m-%d %a %H:%M")
end

-- 采集：便宜的数据先拿（niri IPC、sysfs），外部命令留到最后一起发。
local outputs = niri_outputs() or {}
local focused_output = niri_focused_output()
local workspaces = niri_workspaces() or {}
local battery, ac = power_state()
local backlights = backlight_percentages()

-- 外部显示器的亮度走 DDC/CI，总线号由 DRM 连接器给出。
local probes = {
    probe("volume", { "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@" }),
    probe("ime", { "fcitx5-remote" }),
}

if battery then
    probes[#probes + 1] = probe(
        "battery",
        upower_query("/org/freedesktop/UPower/devices/battery_" .. battery))
end

for _, output in ipairs(outputs) do
    if not is_internal(output.name) then
        local bus = ddc_bus(output.name)
        if bus then
            -- 跳过 ddcutil 的开场检查和能力缓存：总线号是我们自己给的，
            -- 显示器在不在、支不支持这些它查了也没用。
            probes[#probes + 1] = probe("brightness:" .. output.name, {
                "timeout", "1",
                "ddcutil", "getvcp", "10", "--bus", tostring(bus),
                "--skip-ddc-checks", "--disable-capabilities-cache",
            })
        end
    end
end

local argvs = {}
for i, item in ipairs(probes) do argvs[i] = item.argv end

local probe_results = lib.run_all(argvs)
local results = {}
for i, item in ipairs(probes) do
    results[item.name] = probe_results[i]
end

add(recording_row(), "record")
add(battery_row(results, battery, ac))
for _, reading in ipairs(brightness_rows(outputs, backlights, results)) do add(reading) end
add(volume_row(results.volume), "volume")
add(ime_row(results.ime), "ime")
add(workspaces_row(focused_output, workspaces))
add(clock_row())

lib.niri_close()

io.write(table.concat(rows, "\n"))
if #rows > 0 then io.write("\n") end
