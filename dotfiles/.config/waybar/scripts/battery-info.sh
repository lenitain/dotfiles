#!/bin/bash
BAT="/sys/class/power_supply/BAT1"
AC="/sys/class/power_supply/ACAD"

# 基础数据
read -r status < "$BAT/status"
read -r capacity < "$BAT/capacity"
read -r energy_now < "$BAT/energy_now"
read -r energy_full < "$BAT/energy_full"
read -r energy_design < "$BAT/energy_full_design"
read -r power_now < "$BAT/power_now"
read -r voltage < "$BAT/voltage_now"
read -r cycles < "$BAT/cycle_count"
read -r tech < "$BAT/technology"
read -r alarm < "$BAT/alarm"
read -r charge_types < "$BAT/charge_types"
read -r capacity_level < "$BAT/capacity_level"
read -r ac_online < "$AC/online"

# 计算值
health=$((energy_full * 100 / energy_design))
wear=$((100 - health))
read -r power_w voltage_v energy_now_wh energy_full_wh energy_design_wh alarm_wh <<< "$(awk "BEGIN {printf \"%.1f %.2f %.1f %.1f %.1f %.1f\", $power_now/1e6, $voltage/1e6, $energy_now/1e6, $energy_full/1e6, $energy_design/1e6, $alarm/1e6}")"

# 时间估算
if [ "$power_now" -gt 0 ]; then
    if [ "$status" = "Discharging" ]; then
        remaining_h=$(awk "BEGIN {printf \"%.1f\", $energy_now / $power_now}")
        time_line="剩余时间: ${remaining_h}h"
    elif [ "$status" = "Charging" ]; then
        remaining_h=$(awk "BEGIN {printf \"%.1f\", ($energy_full - $energy_now) / $power_now}")
        time_line="充满还需: ${remaining_h}h"
    else
        time_line="状态: $status"
    fi
else
    time_line="状态: $status"
fi

# AC 状态
if [ "$ac_online" = "1" ]; then
    ac_line="电源: 已接通"
else
    ac_line="电源: 未接通"
fi

notify-send -a "Battery" "🔋 电池详细信息" \
"━━━━ 基本状态 ━━━━
电量: ${capacity}% ( 等级: ${capacity_level} )
${time_line}
${ac_line}

━━━━ 实时数据 ━━━━
功率: ${power_w}W
电压: ${voltage_v}V

━━━━ 容量信息 ━━━━
当前: ${energy_now_wh}Wh
满充: ${energy_full_wh}Wh
设计: ${energy_design_wh}Wh

━━━━ 健康信息 ━━━━
健康度: ${health}%   磨损: ${wear}%
循环次数: ${cycles}次
电池类型: ${tech}
充电模式: ${charge_types}
低电告警: ${alarm_wh}Wh"
