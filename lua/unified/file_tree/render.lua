local tree_state = require("unified.file_tree.state")

local M = {}

local STATUS = {
  A = { "A", "UnifiedTreeAdded", "#6a9955" },
  M = { "M", "UnifiedTreeModified", "#dcdcaa" },
  D = { "D", "UnifiedTreeDeleted", "#f44747" },
  R = { "R", "UnifiedTreeRenamed", "#569cd6" },
  C = { "C", "UnifiedTreeCached", "#808080" },
  ["?"] = { "?", "UnifiedTreeUntracked", "#808080" },
}

local function define_highlights()
  for _, status in pairs(STATUS) do
    vim.api.nvim_set_hl(0, status[2], { fg = status[3], default = true })
  end
end

local function has_change(node)
  if not node.is_dir then
    return (node.status or " ") ~= " "
  end
  for _, child in ipairs(node:get_children() or {}) do
    if has_change(child) then
      return true
    end
  end
  return false
end

function M.render_tree(tree, buffer)
  buffer = buffer or vim.api.nvim_get_current_buf()
  local ns = vim.api.nvim_create_namespace("unified_file_tree")
  define_highlights()

  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_clear_namespace(buffer, ns, 0, -1)
  tree_state.line_to_node = {}
  tree_state.expanded_dirs = tree_state.expanded_dirs or {}

  local lines = { "  " .. vim.fn.fnamemodify(tree.root.path, ":~"), "  Help: ? ", "" }
  local marks = {}
  local file_count = 0

  local function walk(node, depth)
    for _, child in ipairs(node:get_children() or {}) do
      if not tree_state.diff_only or has_change(child) then
        local indent = string.rep("  ", depth)
        if child.is_dir then
          local open = tree_state.expanded_dirs[child.path] ~= false
          lines[#lines + 1] = " " .. indent .. (open and "▾ " or "▸ ") .. child.name
          local line = #lines - 1
          tree_state.line_to_node[line] = child
          marks[#marks + 1] = { line = line, col = 1 + #indent, hl = "Directory" }
          if open then
            walk(child, depth + 1)
          end
        else
          file_count = file_count + 1
          lines[#lines + 1] = " " .. indent .. "  " .. child.name
          local line = #lines - 1
          tree_state.line_to_node[line] = child
          local key = (child.status or " "):match("[AMDRC?]")
          local status = key and STATUS[key]
          if status then
            marks[#marks + 1] = { line = line, col = 0, hl = status[2], virt = status[1] }
          end
        end
      end
    end
  end
  walk(tree.root, 0)

  if file_count == 0 then
    lines[#lines + 1] = "  No changes to display"
  end

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_extmark(buffer, ns, 0, 0, { end_col = #lines[1], hl_group = "Title" })
  vim.api.nvim_buf_set_extmark(buffer, ns, 1, 0, { end_col = #lines[2], hl_group = "Comment" })
  for _, mark in ipairs(marks) do
    if mark.virt then
      vim.api.nvim_buf_set_extmark(buffer, ns, mark.line, mark.col, {
        virt_text = { { mark.virt, mark.hl } },
        virt_text_pos = "overlay",
      })
    else
      vim.api.nvim_buf_set_extmark(buffer, ns, mark.line, mark.col, {
        end_col = #lines[mark.line + 1],
        hl_group = mark.hl,
      })
    end
  end

  vim.bo[buffer].modifiable = false
  tree_state.buffer = buffer
  tree_state.current_tree = tree
end

return M
