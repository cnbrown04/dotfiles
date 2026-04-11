# Dotfiles

A collection of configuration files for terminal-based workflows, managed via GNU Stow.

## Package Compatibility

| Package | macOS | Linux | WSL2 | Notes |
| :--- | :---: | :---: | :---: | :--- |
| **Neovim** | ✅ | ✅ | ✅ | Configured with Lazy.nvim |
| **Zsh / Starship** | ✅ | ✅ | ✅ | Shell environment |
| **Tmux / Tmuxp** | ✅ | ✅ | ✅ | Session management |
| **Ghostty** | ✅ | ✅ | ⚠️ | Requires X-Server/Wayland on WSL |
| **Raycast** | ✅ | ❌ | ❌ | macOS Application only |

---

## Usage and Symlinking

This repository mirrors the home directory structure. Since each folder contains a `.config` subfolder, you must target the **Home directory (~)** to ensure files land in `~/.config/`.

### Linking a Package
Run from the `~/Developer/dotfiles` directory:

`stow -v -t ~ <package_name>`

### Example: Linking Neovim
`stow -v -t ~ nvim`

### Unlinking a Package
To remove the symlinks:

`stow -D -t ~ <package_name>`

---

## Directory Structure



* **nvim/**: Neovim configuration (`init.lua`, lazy plugins)
* **zsh/**: Zsh configuration (`.zshrc`, `.zshenv`)
* **tmux/**: Tmux configuration (`tmux.conf`)
* **starship/**: Starship prompt (`starship.toml`)
* **ghostty/**: Ghostty terminal configuration
* **raycast/**: Raycast extensions and settings (macOS)

---

## Installation

### 1. Install GNU Stow
* macOS: `brew install stow`
* Linux: `sudo apt install stow`

### 2. Clone the Repository
`mkdir -p ~/Developer`
`cd ~/Developer`
`git clone <repo-url> dotfiles`
`cd dotfiles`

### 3. Deploy Configs
`stow -v -t ~ nvim zsh tmux starship`

### 4. Initialize Neovim
Run `nvim`. The configuration will automatically bootstrap and download plugins via Lazy.nvim.
