-- Neovim notification configuration using mini.notify
--
-- This file configures the mini.notify plugin to filter out verbose LSP messages.
-- It reduces noise from the Lua language server during development.
--
-- What it does:
--   - Sets up mini.notify as the notification handler
--   - Filters out "Diagnosing" and "semantic tokens" messages from lua_ls
--   - Keeps all other notifications visible
--
-- Usage:
--   Loaded automatically via flake.nix:
--   optionalLuaPreInit.project = [(builtins.readFile ./lib/mini-notify-config.lua)]
--
-- Customization:
--   - Add more patterns to filter in the predicate function
--   - Filter notifications from other LSP servers by client_name
--   - Adjust notification display settings in setup() call

-- Predicate function to filter notifications
-- Returns true if notification should be shown, false to hide it
local predicate = function(notif)
  -- Keep all non-LSP notifications
  if not (notif.data.source == "lsp_progress" and notif.data.client_name == "lua_ls") then
    return true
  end
  -- Filter out specific verbose LSP progress notifications from lua_ls
  -- These messages are too frequent and not useful during development
  return notif.msg:find("Diagnosing") == nil and notif.msg:find("semantic tokens") == nil
end

-- Custom sort function that applies filtering
-- Filters notification array before sorting
local custom_sort = function(notif_arr)
  return MiniNotify.default_sort(vim.tbl_filter(predicate, notif_arr))
end

-- Initialize mini.notify with custom configuration
require("mini.notify").setup({ content = { sort = custom_sort } })

-- Set mini.notify as the default notification handler
vim.notify = MiniNotify.make_notify()
