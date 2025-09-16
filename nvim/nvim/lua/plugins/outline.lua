return {
  "hedyhli/outline.nvim",
  event = "BufReadPost",
  opts = {
    outline_window = {
      width = 17,           -- 改为 30% 或 40 列宽度
      relative_width = true,  -- 使用百分比方式
      auto_close = true,
    }
  }
}
