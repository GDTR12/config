
return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    config = function()
      vim.o.background = "dark" -- 或 "light"
      require("vscode").setup({
        transparent = false, -- 启用透明背景
        italic_comments = true, -- 启用斜体注释
        italic_inlayhints = true, -- 启用斜体内联提示
        underline_links = true, -- 启用链接下划线
        disable_nvimtree_bg = true, -- 禁用 NvimTree 背景色
        terminal_colors = true, -- 启用终端颜色
        color_overrides = {
          vscLineNumber = "#FFFFFF", -- 自定义行号颜色
        },
        group_overrides = {
          Cursor = { fg = "#1e1e1e", bg = "#569cd6", bold = true },
        },
      })
      vim.cmd.colorscheme("vscode")
    end,
  },
}
