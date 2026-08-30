return {
  "rcarriga/nvim-dap-ui",
  dependencies = {
    "mfussenegger/nvim-dap",
    "nvim-neotest/nvim-nio",
  },
  keys = {
    { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
  },
  config = function()
    local dapui = require("dapui")
    local dap = require("dap")

    dapui.setup({
      floating = {
        border = "rounded",
      },
    })

    -- 自动打开/关闭 UI
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end,
}
