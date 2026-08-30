return {
  "mfussenegger/nvim-dap",
  dependencies = { "theHamsta/nvim-dap-virtual-text" },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dr", function() require("dap").repl.open() end, desc = "Open REPL" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
  },
  config = function()
    local dap = require("dap")

    -- Python (debugpy, 由 mise pipx 管理)
    dap.adapters.python = {
      type = "executable",
      command = "debugpy-adapter",
    }
    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        pythonPath = function() return vim.fn.exepath("python3") or "python3" end,
      },
    }

    -- JavaScript / TypeScript (pwa-node, 需安装 js-debug-adapter)
    -- 下载: https://github.com/microsoft/vscode-js-debug/releases
    for _, lang in ipairs({ "javascript", "typescript" }) do
      dap.configurations[lang] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }
    end

    -- Go (delve, go install → ~/go/bin/dlv)
    dap.adapters.go = {
      type = "executable",
      command = "dlv",
      args = { "dap" },
    }
    dap.configurations.go = {
      {
        type = "go",
        request = "launch",
        name = "Debug file",
        program = "${file}",
      },
      {
        type = "go",
        request = "launch",
        name = "Debug project",
        program = "${workspaceFolder}",
      },
    }

    -- Rust / Zig / C / C++ (lldb-dap, 系统 LLVM 自带)
    dap.adapters.lldb = {
      type = "executable",
      command = "lldb-dap",
    }
    for _, lang in ipairs({ "rust", "zig", "c", "cpp" }) do
      dap.configurations[lang] = {
        {
          type = "lldb",
          request = "launch",
          name = "Debug",
          program = function() return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/", "file") end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
    end
  end,
}
