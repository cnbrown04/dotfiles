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
- zap — zsh plugin manager
- TPM — tmux plugin manager
- Neovim plugins — `vim.pack.sync()`
- Ghostty platform config symlink
- Claude Code settings symlink → `~/.claude/settings.local.json`

After bootstrap, log in to services manually: `gh auth login`, Cursor CLI login, etc.

## Plugins

### zsh (via [zap](https://github.com/zap-zsh/zap))

- zsh-users/zsh-autosuggestions
- zap-zsh/supercharge
- zsh-users/zsh-syntax-highlighting

### tmux (via [TPM](https://github.com/tmux-plugins/tpm))

- tmux-plugins/tpm only (no extra plugins configured)

### neovim (via built-in `vim.pack`)

- hardtime.nvim
- barbecue.nvim, nvim-navic
- noice.nvim, nvim-notify
- hover.nvim
- owl-themes.nvim
- fff.nvim
- neo-tree.nvim, plenary.nvim, nui.nvim, nvim-web-devicons

**LSP servers** (configured in `nvim/lsp/`): lua_ls, rust_analyzer, ts_ls, pyright, html, cssls

## Not tracked

- zsh history, compdump, sessions
- tmux plugin clones
- cursor chat history, statsig cache, and auth/session fields (login repopulates those)
- gh auth tokens (`gh/hosts.yml`)
- raycast installed extensions
- ghostty `macos.conf` / `linux.conf` symlinks (created by bootstrap)

## Notes

- Git signing uses 1Password SSH on macOS — adjust `git/config` on other machines if needed.
- `chsh -s $(brew --prefix)/bin/zsh` to make Homebrew zsh your login shell.
