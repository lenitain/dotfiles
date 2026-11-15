local M = {}

--- 是否为"虚拟 buffer"：hunk.nvim 的 `hunk://…` diff 视图，以及 help / qf /
--- terminal 这类临时缓冲区。它们背后没有可供外部工具读写落盘的文件，
--- LSP、lint、formatter 介入只会白起进程（hunk 的只读副本甚至连写回都不存在）。
---@param bufnr integer
---@return boolean
function M.is_virtual_buffer(bufnr)
  return vim.bo[bufnr].buftype ~= "" or vim.api.nvim_buf_get_name(bufnr):match("^%a[%w+.-]*://") ~= nil
end

return M
