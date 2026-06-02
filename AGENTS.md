# Agent instructions

This repository is a dotfiles repo rooted at `~/.config`. When you add, remove, or materially change anything here, **update `README.md` in the same change**.

## Update README when you change

- A new config directory or tool (e.g. `wezterm/`, `fish/`)
- Bootstrap install steps (`bootstrap`) — new packages, casks, npm globals, or setup hooks
- zsh, tmux, or neovim plugins
- LSP servers or language tooling
- Cursor or Claude config paths or purpose
- Ghostty platform config or shared settings

## README expectations

- Keep **What's included** and **Bootstrap installs** accurate
- List new plugins under **Plugins** with a [GitHub link](https://github.com/) and a one-line description
- Keep **Quick start** unchanged unless the install flow changes

## Also update when relevant

- `bootstrap` — if the change needs something installed on a fresh machine
- `.gitignore` — if the change creates runtime files that should not be committed

Do not commit secrets, auth tokens, chat history, or machine-local caches.
