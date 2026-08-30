return {
  "echasnovski/mini.surround",
  event = "VeryLazy",
  -- 前缀从默认的 s* 挪到 gs*（gsa 添加 / gsd 删除 / gsr 替换，可视模式同样按 gsa），
  -- 让小写 s 完全归还给原生替换命令，零延迟零冲突。
  opts = {
    mappings = {
      add = "gsa",
      delete = "gsd",
      replace = "gsr",
      find = "gsf",
      find_left = "gsF",
      highlight = "gsh",
      suffix_last = "", -- 禁用扩展搜索后缀映射
      suffix_next = "",
    },
  },
}
