return{
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      shade_terminals = false,
      highlights = {
        Normal = { link = "Normal" },
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
      },
      float_opts = {
        border = "rounded",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    },
  },
}
