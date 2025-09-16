-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- vim.keymap.set({'n', 'i', 'v'}, "<C-Space>", )
local teles_builtin = require('telescope.builtin')
local custom_fn     = require('config.custom_fn')

local wk = require("which-key")

wk.add({
  --  打开大纲用 "<leader>cs"
  -- {"<leader>uo", "<cmd>Outline<CR>", desc = "Show the outline of the file"},

  -- termnal --
  {"<leader>t", group = "terminal"},
  {"<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Toggle one floating terminal"},
  {"<leader>tt", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Toggle one terminal"},
  {"<leader>th", function() vim.cmd("ToggleTerm ".. tostring(require("toggleterm.terminal").get_focused_id() + 1) .. "<CR>")end,desc = "New terminal right"},
  {"<leader>tv", function() vim.cmd("ToggleTerm ".. tostring(require("toggleterm.terminal").get_focused_id() + 1) .. " direction='vertical'<CR>")end,desc = "New terminal below"},
  {"<leader>tq", function() require("toggleterm.terminal").get(require("toggleterm.terminal").get_focused_id()):close() end,desc = "Close current terminal"},

  {"<leader>se", custom_fn.parse_line_goto, desc="Parse current error and telescope it"},
})

wk.add({
  {"<leader><leader>", "<cmd>wincmd p<CR>", desc="Go to previous window" }
})

-- -- 行注释 - Ctrl + /
vim.keymap.set("n", "<C-_>", "gcc", { desc = "Toggle line comment", remap = true })
vim.keymap.set("v", "<C-_>", "gc", { desc = "Toggle line comment", remap = true })

-- 段落注释 - Ctrl + Shift + /
vim.keymap.set("n", "<C-S-_>", "gbc", { desc = "Toggle block comment", remap = true })
vim.keymap.set("v", "<C-S-_>", "gb", { desc = "Toggle block comment", remap = true })

-- 映射 Home 到 ^ (第一个非空字符)
vim.keymap.set({'n', 'v'}, '<Home>', '^', { desc = "Go to first non-blank character" })
vim.keymap.set('i', '<Home>', '<Esc>^i', { desc = "Go to first non-blank character in insert mode" })

-- 映射 End 到 g_ (最后一个非空字符)
vim.keymap.set({'n', 'v'}, '<End>', 'g_', { desc = "Go to last non-blank character" })
vim.keymap.set('i', '<End>', '<Esc>g_a', { desc = "Go to last non-blank character in insert mode" })

-- -- 回到上一个窗口
-- local telescope_builtin = require("telescope.actions")
-- -- 普通模式映射
-- vim.keymap.set("n", "<C-k>", telescope_builtin.results_scrolling_up,   { silent = true })
-- vim.keymap.set("n", "<C-j>", telescope_builtin.results_scrolling_down, { silent = true })

-- 双击 Esc 退出终端输入模式
local esc_timer
vim.keymap.set("t", "<Esc>", function()
  if esc_timer then
    esc_timer:close()
    esc_timer = nil
    -- 双击 Esc 退出终端模式
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
  else
    -- 第一次按 Esc，发送给终端
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    esc_timer = vim.defer_fn(function()
      esc_timer = nil
    end, 300) -- 200ms 内双击有效
  end
end, { desc = "Double Esc to exit terminal" })

