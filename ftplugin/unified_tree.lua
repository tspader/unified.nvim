vim.bo.modifiable = false
vim.bo.buftype = "nofile"
vim.bo.swapfile = false
vim.bo.bufhidden = "wipe"
vim.bo.syntax = "unified_tree"

-- Window-local options are applied via apply_tree_window_options in
-- lua/unified/file_tree/init.lua. Setting them here would target whichever
-- window happens to be current when the FileType event fires — which is the
-- user's editing window, not the tree window (the tree window doesn't exist
-- yet at that point).

vim.keymap.set("n", "R",
  function()
    require('unified.file_tree.actions').refresh()
  end,
  { noremap = true, silent = true, buffer = true }
)

vim.keymap.set("n", "q",
  function()
    require('unified.file_tree.actions').close_tree()
  end,
  { noremap = true, silent = true, buffer = true }
)

vim.keymap.set("n", "?",
  function()
    require('unified.file_tree.actions').show_help()
  end,
  { noremap = true, silent = true, buffer = true }
)

for _, key in ipairs({ "l", "o", "<CR>" }) do
  vim.keymap.set("n", key,
    function()
      require('unified.file_tree.actions').toggle_node()
    end,
    { noremap = true, silent = true, buffer = true }
  )
end
