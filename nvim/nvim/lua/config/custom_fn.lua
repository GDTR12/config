

local M = {}  -- 模块表

function M.nvim_max_win()
  local max_area, target_win = 0, nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      goto continue
    end
    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local area = width * height
    if area > max_area then
      max_area = area
      target_win = win
    end
    ::continue::
  end
  return target_win
end

function M.parse_line(text)
  local result = {}
  if not text then return result end
  for line in text:gmatch("[^\n]+") do
    for filename, row_num, col_num in line:gmatch("([%w%/._~-]+):(%d+):?(%d*)") do
      table.insert(result, {
        file = filename,
        row = row_num,
        col = col_num
      })
    end
    for filename, row_num in line:gmatch('File "([^"]+)", line (%d+)') do -- python error output
      table.insert(result, {
        file = filename,
        row = row_num,
        col = 1
      })
    end
    break
  end
  return result
end

local function has_line_in_buf(bufnr, line_num)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  return line_num >= 1 and line_num <= line_count
end



local function preview_file_at_line(lines_table)

  -- 保存当前窗口和光标
  local win = vim.api.nvim_get_current_win()
  local cur_pos = vim.api.nvim_win_get_cursor(win)

  local qf = {}
  for i = #lines_table, 1, -1 do
    local item = lines_table[i]
    local file, line, col = item.file, item.row, item.col

    if not file then
      goto continue
    end

    local file_path = ""
    if file:sub(1, 1) == "/" then
      file_path = file
    else
      file_path = vim.fn.getcwd() .. "/" .. file
    end
    if vim.fn.filereadable(file_path) == 0 then
      goto continue
    end

    line = line or 0
    local file_str = vim.fn.readfile(file_path)

    table.insert(qf, {
      filename = file_path,
      lnum = tonumber(line) or 1,
      col = tonumber(col) or 1,
      text = file_str[line] or ""
    })
      ::continue::
  end

  if 0 == #qf then
    vim.notify("Parsed no error message")
    return
  end

  vim.fn.setqflist(qf, "r")

  local target_win = 0
  local max_win = M.nvim_max_win()
  if max_win then
   target_win = max_win
  end

  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("telescope.builtin").quickfix({
    attach_mappings = function(prompt_bufnr, map)
      -- Esc: 关闭并恢复光标
      map("i", "<esc>", function()
        actions.close(prompt_bufnr)
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
          vim.api.nvim_win_set_cursor(win, cur_pos)
        end
      end)
      map("n", "<esc>", function()
        actions.close(prompt_bufnr)
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
          vim.api.nvim_win_set_cursor(win, cur_pos)
        end
      end)

      -- Ctrl+Enter: 跳转到条目对应文件和行
      map("i", "<CR>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and vim.api.nvim_win_is_valid(target_win) then
          vim.api.nvim_set_current_win(target_win)
          vim.cmd(string.format("edit %s", selection.filename))
          vim.api.nvim_win_set_cursor(target_win, {selection.lnum, selection.col - 1})
        end
      end)
      map("n", "<CR>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and vim.api.nvim_win_is_valid(target_win) then
          vim.api.nvim_set_current_win(target_win)
          vim.cmd(string.format("edit %s", selection.filename))
          vim.api.nvim_win_set_cursor(target_win, {selection.lnum, selection.col - 1})
        end
      end)

      return true
    end
  })

end



function M.parse_line_goto()
  -- local current_line = math.min(vim.fn.line('$'), vim.fn.line('.'))
  local parse_result

  local current_line = vim.fn.line('.')
  local current_text = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)

  if string.find(table.concat(current_text, " "), "%.py") then
    local end_line = math.min(vim.fn.line('$'), current_line + 15)
    local text = vim.api.nvim_buf_get_lines(0, current_line - 1, end_line, false)
    local resversed_text = {}
    for i = #text, 1, -1 do
        table.insert(resversed_text, text[i])
    end
    parse_result = M.parse_line(table.concat(resversed_text, " "))
  else
    local before_line  = math.max(1, current_line - 15)
    local text = vim.api.nvim_buf_get_lines(0, before_line, current_line, false)
    parse_result = M.parse_line(table.concat(text, " "))
  end
  -- vim.notify(table.concat(text, "\n"))


  preview_file_at_line(parse_result)
  -- -- 保存当前窗口和光标位置
  -- local cur_win = vim.api.nvim_get_current_win()
  -- -- local cur_pos = vim.api.nvim_win_get_cursor(cur_win)
  -- -- vim.notify(file_path)
  -- -- vim.notify(row)
  --  -- 找到面积最大的窗口
  --  local target_win = 0
  --  local max_win = M.nvim_max_win()
  --  if max_win then
  --   target_win = max_win
  --  end
  --
  --  if target_win then
  --  -- 保存最大窗口视图
  --  local view = vim.fn.winsaveview()
  --
  --  -- 在最大窗口显示 buffer
  --  vim.api.nvim_win_set_buf(target_win, bufnr)
  --
  --  -- -- 滚动到错误行，使其可见
  --  -- if not line then return end
  --  -- if has_line_in_buf(bufnr, tonumber(line)) then
  --  --   -- local topline = math.max(line - math.floor(vim.api.nvim_win_get_height(target_win)/2), 1)
  --  --   vim.api.nvim_win_set_cursor(target_win, {tonumber(line), 0})
  --  -- end
  --  --
  --  -- -- 恢复最大窗口视图，但光标仍不动
  --  -- vim.fn.winrestview(view)
  --  end

end


return M
