# dotfiles

Personal config living in `~/.config`. Clone this repo directly into that path.

## Quick start

```bash
git clone https://github.com/cnbrown04/dotfiles.git ~/.config
~/.config/bootstrap
exec zsh -l
```

Bootstrap installs [Homebrew](https://brew.sh) on macOS and Linux, then uses it for almost everything else.

## What's included

| Path | Tool |
|---|---|
| `zsh/` | Shell (ZDOTDIR) |
| `git/config` | Git global config |
| `ghostty/` | Terminal |
| `tmux/` | Terminal multiplexer |
| `nvim/` | Neovim |
| `starship/` | Shell prompt |
| `lazygit/` | Git TUI |
| `gh/` | GitHub CLI preferences |
| `cursor/` | Cursor CLI preferences |
| `.claude/` | Claude Code permission defaults |

## Bootstrap installs

**Via Homebrew (macOS + Linux):**

- git, zsh, tmux, neovim, starship, lazygit, gh
- lua-language-server, rust-analyzer, node, curl

**Via Homebrew cask (macOS) or distro fallback (Linux):**

- ghostty
- JetBrainsMono Nerd Font

**Via npm (global):**

- pyright, typescript, typescript-language-server, vscode-langservers-extracted

**Post-install setup:**

- `/etc/zshenv` — ZDOTDIR, XDG paths, git config location
- [zap](https://github.com/zap-zsh/zap) — zsh plugin manager
- [TPM](https://github.com/tmux-plugins/tpm) — tmux plugin manager
- Neovim plugins — `vim.pack.sync()`
- Ghostty platform config symlink
- Claude Code settings symlink → `~/.claude/settings.local.json`

After bootstrap, log in to services manually: `gh auth login`, Cursor CLI login, etc.

## Plugins

### zsh (via [zap](https://github.com/zap-zsh/zap))

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — fish-style command suggestions as you type
- [supercharge](https://github.com/zap-zsh/supercharge) — speeds up zsh startup and defers compinit for zap
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — colors valid/invalid commands while typing

### tmux (via [TPM](https://github.com/tmux-plugins/tpm))

- [tpm](https://github.com/tmux-plugins/tpm) — plugin manager only; no extra tmux plugins configured

### neovim (via built-in `vim.pack`)

- [hardtime.nvim](https://github.com/m4xshen/hardtime.nvim) — nudges you away from repetitive keys and bad habits
- [barbecue.nvim](https://github.com/utilyre/barbecue.nvim) — winbar breadcrumbs showing file path and symbols
- [nvim-navic](https://github.com/SmiteshP/nvim-navic) — LSP symbol trail used by barbecue
- [noice.nvim](https://github.com/folke/noice.nvim) — nicer cmdline, messages, and popup menu UI
- [nvim-notify](https://github.com/rcarriga/nvim-notify) — toast-style notifications (used by noice)
- [hover.nvim](https://github.com/lewis6991/hover.nvim) — unified hover docs for LSP, marks, and more
- [owl-themes.nvim](https://github.com/cnbrown04/owl-themes.nvim) — Light Owl / Night Owl colorscheme
- [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim) — fast fuzzy file finder
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) — sidebar file tree
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) — Lua stdlib helpers (neo-tree dependency)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) — UI components (neo-tree dependency)
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) — filetype icons

**LSP servers** (configured in `nvim/lsp/`):

- [lua-language-server](https://github.com/LuaLS/lua-language-server) — Lua
- [rust-analyzer](https://github.com/rust-lang/rust-analyzer) — Rust
- [typescript-language-server](https://github.com/typescript-language-server/typescript-language-server) — TypeScript/JavaScript
- [pyright](https://github.com/microsoft/pyright) — Python
- [vscode-langservers-extracted](https://github.com/hrsh7th/vscode-langservers-extracted) — HTML and CSS
