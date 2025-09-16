return {
  "sphamba/smear-cursor.nvim",

  opts = {
    -- Smear cursor when switching buffers or windows.
    smear_between_buffers = false,


    -- Smear cursor when moving within line or to neighbor lines.
    -- Use `min_horizontal_distance_smear` and `min_vertical_distance_smear` for finer control
    smear_between_neighbor_lines = true,
    min_horizontal_distance_smear = 5,
    min_vertical_distance_smear = 0,
    stiffness = 0.6,
    tailing_stiffness = 0.6,
    distance_stop_animating = 0.5,
    max_length = 5,
    color_levels = 1,

    -- Draw the smear in buffer space instead of screen space when scrolling
    scroll_buffer_space = true,

    -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
    -- Smears will blend better on all backgrounds.
    legacy_computing_symbols_support = false,

    -- Smear cursor in insert mode.
    -- See also `vertical_bar_cursor_insert_mode` and `distance_stop_animating_vertical_bar`.
    smear_insert_mode = true,
  },
}
