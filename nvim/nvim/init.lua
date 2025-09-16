-- bootstrap lazy.nvim, LazyVim and your plugins
-- vim.o.shell = "/bin/bash"


vim.opt.exrc = true

vim.opt.errorformat = {
    -- Gcc
    "%f:%l:%c: %t%*[^:]: %m",           -- file:line:col: error/warning: message
    "%f:%l: %t%*[^:]: %m",              -- file:line: error/warning: message
    "%f: %t%*[^:]: %m",                 -- file: error/warning: message
    -- Python traceback 格式
    '%A  File "%f"\\, line %l\\, in %m',     -- 主要错误行
    '%C    %m',                              -- 错误上下文
    '%+C  %.%#',                             -- 多行错误信息
    '%Z%m',                                  -- 错误结束行
    -- 简单的错误格式
    '%f:%l:%c: %m',                          -- 文件:行:列: 消息
    '%f:%l: %m',                             -- 文件:行: 消息
    -- pytest 格式
    '%f:%l: %m',                             -- pytest 错误
    '%A%f:%l: in %m',                        -- pytest 详细格式
    -- flake8/pylint 格式
    '%f:%l:%c: %t%n %m',                     -- flake8: 文件:行:列: 类型编号 消息
    '%f:%l: %m',                             -- pylint 简化格式
    -- mypy 格式
    '%f:%l: %t%*[a-z]: %m',                  -- mypy: 文件:行: 类型: 消息
    -- 通用格式
    '%-G%.%#',                               -- 忽略不匹配的行
}


function aaabbbb()
  local file_path = '/root/workspace/my_fastlio/test.txt'
  local file = io.open(file_path, 'a')  -- 改为追加模式
  if not file then
      vim.notify("无法打开文件: " .. file_path, vim.log.levels.ERROR)
      return
  end

  -- 获取当前 buffer 内容
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local bufnr_str = table.concat(lines, "\n")

  vim.notify(bufnr_str)
  -- 拼接匹配结果
  local out = ""
  for filename, line, col in bufnr_str:gmatch("([%w%/._~-]+):(%d+):?(%d*)") do
      out = out .. "文件:" .. filename .. " 行:" .. line .. " 列:" .. (col ~= "" and col or "-") .. "\n"
    vim.notify("文件:" .. filename .. " 行:" .. line .. " 列:" .. (col ~= "" and col or "-"))
  end

  -- 写入文件
  file:write(out)
  file:close()
  vim.notify("Buffer 内容已追加到文件: " .. file_path)
end

-- 自动隐藏 toggleterm，当离开终端时
vim.api.nvim_create_autocmd({"BufLeave"}, {
  pattern = "term://*toggleterm#*",
  callback = function()
    require("toggleterm").toggle(0)  -- 隐藏当前 terminal
    vim.cmd("wincmd p")
  end,
})

vim.api.nvim_create_user_command('AppendBuffer', aaabbbb, {})
require("config.lazy")

local project_config = vim.fn.getcwd() .. "/.nvim/init.lua"
if vim.fn.filereadable(project_config) == 1 then
  vim.notify("Found workspace config: " .. project_config)
  dofile(project_config)
else
  vim.notify("Can't find workspace config: " .. project_config)
end

