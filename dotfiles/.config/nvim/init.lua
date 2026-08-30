-- 全局选项：行号、缩进、编码、搜索、剪贴板等基础设置
require("config.options")

-- 自定义快捷键映射：键位绑定与快捷操作定义
require("config.keymaps")

-- 自动命令：文件类型检测、自动格式化、窗口行为等事件回调
require("config.autocmds")

-- 插件管理：通过 lazy.nvim 加载并管理所有插件
require("config.lazy")
