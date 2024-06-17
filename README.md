# [v]ery [m]agic [s]lash.nvim 🧙

https://github.com/yujinyuz/vms.nvim/assets/10972027/a52dd29f-5c12-4112-aa4f-1d570c145f17

## Installation

<details>
  <summary>lazy.nvim</summary>

```lua
{
  'yujinyuz/vms.nvim',
  event = 'VeryLazy',
  opts = {},
}
```

</details>

<details>
  <summary>Packer</summary>

```lua
require('packer').startup(function()
  use({
    'yujinyuz/vms.nvim',
    config = function()
      require('vms').setup()
    end,
  })
end)
```

</details>

<details>
  <summary>Paq</summary>

```lua
require('paq')({
  { 'yujinyuz/vms.nvim' },
})
```

</details>

</details>

<details>
  <summary>Neovim native package</summary>

```sh
git clone --depth=1 https://github.com/yujinyuz/vms.nvim.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/vms/start/vms.nvim
```

</details>

## Usage

* Press `/` in normal mode, and it will automatically become `/\v`
* Type `:%s/`, and it becomes `%s/\v`
* Also works with `:g` and `g!`.

## Why?

You probably won't need this plugin if you haven't heard of magic mode in vim, yet. This is just a
convenience plugin so if you're comfortable manually typing `:s/\v` then that should be enough.

You can have a very basic implementation of this plugin by copying the lines below which was
extracted from my [config](https://github.com/yujinyuz/dotfiles/commit/ea086a):

```lua
-- Automatically add vim magic to search and substitute
-- See: https://vim.fandom.com/wiki/Simplifying_regular_expressions_using_magic_and_no-magic
vim.keymap.set({ 'n', 'v' }, '/', '/\\v', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '?', '?\\v', { noremap = true })

vim.keymap.set('c', '/', function()
  -- Get the previous command-line text
  local line = vim.fn.getcmdline()
  -- Check if the previous text is "%s"
  if line == '%s' or line == "'<,'>s" then
    return '/\\v'
  end

  return '/'
end, { noremap = true, expr = true })

vim.keymap.set('c', '?', function()
  -- Get the previous command-line text
  local line = vim.fn.getcmdline()
  -- Check if the previous text is "%s"
  if line == '%s' or line == "'<,'>s" then
    return '?\\v'
  end
  return '?'
end, { noremap = true, expr = true })
```

That worked for my basic use case, not until I learned more about the `:h global` command and that
I also wanted to apply very magic to it as well. But then it had an inverse equivalent, which is
`:h vglobal`

The basic version also does not work with complicated ranges such as `:.,$` which means _from the
current line up until the end of file_.

That made my config quite complicated, so I extracted it into this plugin.

## Related Resources

* Screencasts
  * [Vim screencast #17: Regular expressions](https://www.youtube.com/watch?v=VjOcINs6QWs)
  * [Vim screencast #20: Loupe](https://www.youtube.com/watch?v=Ipkn3tXKrrA)
  * [Vim screencast](http://vimcasts.org/episodes/refining-search-patterns-with-the-command-line-window/)
* Articles
  * [Vim regexes](https://wincent.dev/wiki/Vim_regexes)

## Acknowledgments

* Inspired by [wincent/loupe](https://github.com/wincent/loupe) plugin where I just extracted the
very magic slash part.


## Known Issues
* None so far
