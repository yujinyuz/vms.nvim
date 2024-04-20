local M = {}

local default_config = {
  default_keymaps = true,
}

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
  -- If we are not in command-line mode, just return the slash
  if vim.fn.getcmdtype() ~= ':' then
    return slash
  end

  -- Get the current command-line text
  local cmdline = vim.fn.getcmdline()
  local cmdpos = vim.fn.getcmdpos()

  -- For simplicity, only consider a slash typed at the end of the command-line.
  if #cmdline + 1 ~= cmdpos then
    return slash
  end

  local commands = {
    'g',
    'gl',
    'glo',
    'glob',
    'globa',
    'global',
    'g!',
    'gl!',
    'glo!',
    'glob!',
    'globa!',
    'global!',
    's',
    'su',
    'sub',
    'subs',
    'subst',
    'substi',
    'substit',
    'substitu',
    'substitut',
    'substitute',
    'v',
    'vg',
    'vgl',
    'vglo',
    'vglob',
    'vgloba',
    'vglobal',
  }

  -- Strip ranges from the current command
  while true do
    local stripped = strip_ranges(cmdline)
    if stripped == cmdline then
      break
    else
      cmdline = stripped
    end
  end

  --  We special case `:g!` (and `gl!`, `glo!`, `glob!`, `globa!`, `global!`).
  --  All of those commands are equivalent to `:v` (ie. `!` is not being used as a
  --  slash). Using `!` with `:v` (etc) is an error (`:h E477`). Using it with `:s`
  --  is ok (it _is_ treated as a delimiter there). Fun fact: `:g!!foo!d` is a
  --  legitmate command.
  local g_commands = {
    'g',
    'gl',
    'glo',
    'glob',
    'globa',
    'global',
  }

  if slash == '!' and vim.tbl_contains(g_commands, cmdline) then
    return slash
  end

  -- Now, we obtain the command token
  -- Check if the command token is in the list of commands
  -- where we can add the \v magic
  if vim.tbl_contains(commands, cmdline) then
    return slash .. '\\v'
  end

  return slash
end

M.setup_normal_keymap = function()
  vim.keymap.set({ 'n', 'v' }, '/', '/\\v', { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '?', '?\\v', { noremap = true })
end

M.setup_cmdline_keymap = function()
  local chars = {
    '!',
    '#',
    '$',
    '%',
    '&',
    "'",
    '(',
    ')',
    '*',
    '+',
    ',',
    '-',
    '.',
    '/',
    ':',
    ';',
    '<',
    '=',
    '>',
    '?',
    '@',
    '[',
    ']',
    '^',
    '_',
    '`',
    '{',
    '}',
    '~',
  }

  for _, char in ipairs(chars) do
    vim.keymap.set('c', char, function()
      return M.very_magic_slash(char)
    end, { noremap = true, expr = true })
  end
end

M.setup = function(opts)
  opts = vim.tbl_extend('force', default_config, opts)

  if opts.default_keymaps then
    M.setup_normal_keymap()
    M.setup_cmdline_keymap()
  end
end

return M
