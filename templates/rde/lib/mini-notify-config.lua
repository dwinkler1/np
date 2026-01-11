-- Configuration for mini.notify
-- Filters out some verbose LSP progress notifications
local predicate = function(notif)
  if not (notif.data.source == "lsp_progress" and notif.data.client_name == "lua_ls") then
    return true
  end
  -- Filter out some LSP progress notifications from 'lua_ls'
  return notif.msg:find("Diagnosing") == nil and notif.msg:find("semantic tokens") == nil
end

local custom_sort = function(notif_arr)
  return MiniNotify.default_sort(vim.tbl_filter(predicate, notif_arr))
end

require("mini.notify").setup({ content = { sort = custom_sort } })
vim.notify = MiniNotify.make_notify()
