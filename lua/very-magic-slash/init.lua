local M = {}
local default_config = {
  default_keymaps = true,
}
local commands = {}
local g_commands = {}
-- stylua: ignore
local ALLOWED_DELIMITERS = {
  '!', '#', '$', '%', '&', "'",
  '(', ')', '*', '+', ',', '-',
  '.', '/', ':', ';', '<', '=',
  '>', '?', '@', '[', ']', '^',
  '_', '`', '{', '}', '~',
}
local initialized = false

local __setup_cmds = function(c, t)
  local curr_form = ''
  local bang = ''
  -- but add it to each truncated form
  if c:sub(-1) == '!' then
    c = c:sub(1, -2)
    bang = '!'
  end
  for i = 1, #c do
    curr_form = curr_form .. c:sub(i, i)
    table.insert(t, curr_form .. bang)
  end
end

local setup_vars = function()
  __setup_cmds('global', g_commands) -- for handling special case `:g!`
  __setup_cmds('global!', commands)
  __setup_cmds('vglobal', commands)
  __setup_cmds('substitute', commands)
end

local strip_ranges = function(cmdstr)
  local modifier = '([%+%-]?%d*)'
  -- Range tokens
  cmdstr = cmdstr:gsub('^%d+' .. modifier, '') -- line number
  cmdstr = cmdstr:gsub('^%.' .. modifier, '') -- current line
  cmdstr = cmdstr:gsub('^$' .. modifier, '') -- last line in file
  cmdstr = cmdstr:gsub('^%%' .. modifier, '') -- entire file
  cmdstr = cmdstr:gsub("^'[a-z]\\c" .. modifier, '') -- mark t (or T)
  cmdstr = cmdstr:gsub("^'[<>]" .. modifier, '') -- visual selection marks
  cmdstr = cmdstr:gsub('^/[^/]+/' .. modifier, '') -- /{pattern}/
  cmdstr = cmdstr:gsub('^?[^?]+?' .. modifier, '') -- ?{pattern}?
  cmdstr = cmdstr:gsub('^\\/' .. modifier, '') -- \/ (next match of previous pattern)
  cmdstr = cmdstr:gsub('^\\?' .. modifier, '') -- \? (last match of previous pattern)
  cmdstr = cmdstr:gsub('^\\&' .. modifier, '') -- \& (last match of previous substitution)
  -- Separators
  cmdstr = cmdstr:gsub('^,', '') -- , (separator)
  cmdstr = cmdstr:gsub('^;', '') -- ; (separator)

  -- Remove leading spaces if any
  cmdstr = cmdstr:gsub('^%s+', '')

  -- Return the remaining string, which should be the command token
  return cmdstr
end

M.very_magic_slash = function(slash)
  if vim.fn.getcmdtype() ~= ':' then
    return slash
  end

  local cmdline = vim.fn.getcmdline()
  local cmdpos = vim.fn.getcmdpos()

  if #cmdline + 1 ~= cmdpos then
    return slash
  end

  -- Strip ranges, if any, from the current command until we only have the command token
  while true do
    local stripped = strip_ranges(cmdline)
    if stripped == cmdline then
      break
    else
      cmdline = stripped
    end
  end

  --  Handle special case `:g!` (and `gl!`, `glo!`, `glob!`, `globa!`, `global!`).
  --  All of those commands are equivalent to `:v` (ie. `!` is not being used as a
  --  slash). Using `!` with `:v` (etc) is an error (`:h E477`). Using it with `:s`
  --  is ok (it _is_ treated as a delimiter there). Fun fact: `:g!!foo!d` is a
  --  legitmate command.
  if slash == '!' and vim.tbl_contains(g_commands, cmdline) then
    return slash
  end

  if vim.tbl_contains(commands, cmdline) then
    return slash .. '\\v'
  end

  return slash
end

M.setup_normal_keymap = function()
  vim.keymap.set({ 'n', 'v' }, '/', '/\\v', { noremap = true, desc = "Very Magic '/'" })
  vim.keymap.set({ 'n', 'v' }, '?', '?\\v', { noremap = true, desc = "Very Magic '?'" })
end

M.setup_cmdline_keymap = function()
  for _, char in ipairs(ALLOWED_DELIMITERS) do
    vim.keymap.set('c', char, function()
      return M.very_magic_slash(char)
    end, { noremap = true, expr = true, desc = "Very Magic '" .. char .. "'" })
  end
end

M.setup = function(opts)
  if initialized then
    return
  end
  opts = vim.tbl_extend('force', default_config, opts)
  if opts.default_keymaps then
    M.setup_normal_keymap()
    M.setup_cmdline_keymap()
  end
  setup_vars()
  initialized = true
end

return M
