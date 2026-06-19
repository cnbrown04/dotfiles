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
| `zsh/` | Shell (ZDOTDIR; Bun PATH/completions) |
| `git/config` | Git global config |
| `ghostty/` | Terminal |
| `tmux/` | Terminal multiplexer |
| `nvim/` | Neovim |
| `starship/` | Shell prompt |
| `zoxide/` | Smarter `cd` (env vars in `env.zsh`; DB is runtime data, not in repo) |
| `lazygit/` | Git TUI |
| `gh/` | GitHub CLI preferences |
| `cursor/` | Cursor CLI preferences |
| `.claude/` | Claude Code permission defaults |
| `colima/` | Colima VM settings (macOS; `COLIMA_HOME` in `zsh/.zshenv`) |

## Install script

<details>
<summary>What <code>bootstrap</code> installs</summary>

Run:

```bash
~/.config/bootstrap
```

to bootstrap your system.

- **Homebrew** (macOS + Linux) — git, zsh, tmux, neovim, starship, lazygit, gh, zoxide, lua-language-server, rust-analyzer, node, curl, [Docker CLI](https://www.docker.com/), [Compose](https://docs.docker.com/compose/), [Buildx](https://docs.docker.com/buildx/)
- **Homebrew** (macOS only) — [Colima](https://colima.run) (Docker-compatible VM runtime; config in `colima/default/colima.yaml`)
- **Ghostty + JetBrainsMono Nerd Font** — Homebrew cask on macOS; brew or distro fallback on Linux
- **npm -g** — pyright, typescript, typescript-language-server, vscode-langservers-extracted
- **Setup** — `/etc/zshenv`, [zap](https://github.com/zap-zsh/zap), [TPM](https://github.com/tmux-plugins/tpm), nvim plugins, ghostty platform symlink, Claude settings symlink, Docker CLI plugin path (`cliPluginsExtraDirs` → Homebrew’s `lib/docker/cli-plugins`)

Log in after: `gh auth login`, Cursor CLI. On macOS, start containers with `colima start` (uses tracked config via `COLIMA_HOME`). On Linux, enable the Docker daemon for your distro (Homebrew installs the CLI only).

**Not tracked:** Docker registry login and credentials live in `~/.docker/` (or `docker/` under this repo if you set `DOCKER_CONFIG`). Colima generates `ssh_config` and VM state under `colima/_lima/` at runtime — both are gitignored.

</details>

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
