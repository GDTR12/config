-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.autoformat = false


-- 配置 vim 的通知行为
vim.opt.shortmess:remove("F") -- 显示完整的文件信息
vim.opt.shortmess:remove("c") -- 显示补全消息

-- 配置错误显示
vim.o.cmdheight = 10 -- 增加命令行高度来显示更多错误信息

